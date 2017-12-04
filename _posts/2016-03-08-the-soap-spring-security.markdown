---
layout: post
title:  "The SOAP Spring Security"
date: 2016-03-08
categories: spring security soap
---

I was recently reminded of the issues surrounding authenticating both web services and their associated administration and documentation pages.  
In the past I had to provide authentication and authorisation services on top of a web service, the .wsdl file served as a web page and the administration web page for managing users and access to the web service.  
SOAP web services have their own mechanisms as does the Spring framework which I'd chosen for the web app, ideally though you want a single source of truth for user authentication and authorisation. I'm going to go through each built in mechanism below and the solution I created to ensure both worked together.

### [Spring security][Spring-Security]
Spring security provides great functionality out of the box with minimal modifications.
The main central security mechanism is the **AuthenticationManager** which makes use of an AuthenticationProvider.

![Spring Security Auth Manager](/assets/SpringSecurity.svg)

The AuthenticationProvider is composed of:
* **SaltSource** - used to provide the salt value when encoding the password to ensure that the resultant *encoded password* for two separate users is not the same with the same input password.
* **PasswordEncoder** - used to encode the provided password with salt value from the SaltSource and compare to the encoded value held in the database
* **UserDetailsService** - this is the datastore that will retrieve a stored and encoded password based on the provided user name.

The UserDetailsService is an interface you need to implement to provide the `loadUserByUsername(String username)` capability. This is called by the AuthenticationProvider to  retrieve the `UserDetails` in its `retrieveUser(username, userAuthToken)` method.
These `UserDetails` contain the encoded & salted copy of the password for the username.
The username given by the user attempting to authenticate is encoded (hashed) using the `PasswordEncoder` and along with a salt generated from the `SaltSource` and compared to the value in the `UserDetails`, if they match then you have yourself an authenticated user.

In this way you can have your user credentials backed up by any type of data store you choose e.g. MySQL, NoSQL, in-memory.

### How WS-Security is implemented via [CXF][CXF]
[WS-Security][SOAP-Security] is an addition to the SOAP spec that allows for authentication to be added to SOAP requests without delegating security to the underlying transport (HTTPS) since multiple transport bindings can be used with SOAP.
WS-Security in CXF involves use of a WSS4JInterceptor to specify the authentication type, in our case a `UsernameToken` strategy/action and specifying the `PasswordText` for the passwordType implying we expect a username token with a text representing the password.
[UsernameToken Authentication][UsernameToken Authentication]

```
<bean id="myPasswordCallback"
      class="com.mycompany.webservice.PasswordCallback"/>

<jaxws:endpoint id="service"
  implementor="#serviceImpl"
  address="/Service"
  publishedEndpointUrl="${service.protocol}://${service.domain}/${build.name}/services/Service">
  <jaxws:inInterceptors>
    <bean class="org.apache.cxf.binding.soap.saaj.SAAJInInterceptor"/>
    <bean class="org.apache.cxf.ws.security.wss4j.WSS4JInInterceptor">
      <constructor-arg>
        <map>
          <entry key="action"			  value="UsernameToken"/>
          <entry key="passwordType"	      value="PasswordText"/>
          <entry key="passwordCallbackRef">
             <ref bean="myPasswordCallback"/>
          </entry>
        </map>
      </constructor-arg>
    </bean>
  </jaxws:inInterceptors>
```
A callback is registered to handle the authentication, this is where the username provided by the token is used to look up the password.  
The password is then set into the callback response which is compared by CXF with the password provided by the user
```
import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;
import org.apache.wss4j.common.ext.WSPasswordCallback;

public class PasswordCallback implements CallbackHandler {

    public void handle(Callback[] callbacks) throws IOException,
            UnsupportedCallbackException {
        WSPasswordCallback pc = (WSPasswordCallback) callbacks[0];

        if ("hardcodedusername".equals(pc.getIdentifier())) {
           pc.setPassword("hardcodedpassword");
        }
    }
}
```
### Spring Security Provider with CXF
Instead of using the PasswordCallback which in the background uses the built in `org.apache.ws.security.validate.UsernameTokenValidator` class we create our own extension of the UsernameTokenValidator class and wire it up as a **USERNAME_TOKEN_VALIDATOR** entry in the jaxws:properties:
```
<jaxws:properties>
  <entry key="#{T(org.apache.cxf.ws.security.SecurityConstants).USERNAME_TOKEN_VALIDATOR}">
    <bean id="usernameTokenValidator" 	class="com.masabi.validation.seeds.watermarking.security.UsernameTokenValidator">
      <property name="authManager" 	ref="authenticationManager"/>
    </bean>
  </entry>
</jaxws:properties>
```

This class has the `@Required` annotation on the field for the AuthenticationManager - which is the implementation of the main Spring Security mechanism.  
The username and password from the CXF `UsernameToken` are extracted and then are used to create a Spring Security `UsernamePasswordAuthenticationToken`.  
This token is then passed into the Spring [AuthenticationManager][AuthenticationManager] (the `authManager` field in the below code) for authentication.  
In the below example we are verifying that the user's role is that of a web service consumer `WS_CONSUMER` and setting a `granted` boolean to true if we get a match.  
If we don't get authentication then there are no `GrantedAuthority` objects returned and we leave the `granted` boolean set to false.  
If the `granted` boolean is false after looping through our `GrantedAuthority` set then we throw a `InsufficientAuthenticationException`.  
If the `granted` boolean is true then we update the Security Context with the authentication values we have received from AuthenticationManager. 

```
@Override
protected void verifyPlaintextPassword(UsernameToken usernameToken, RequestData data){
  String username = usernameToken.getName();
  String password = usernameToken.getPassword();

  UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(username, password);
  LOG.debug("Created authentication token");

  Authentication authentication	= this.authManager.authenticate(token);

  LOG.debug("User Authenticated");
  Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
  boolean granted 		= false;
  for (GrantedAuthority authority : authorities){
    LOG.debug("User {} has authority {}",username, authority.getAuthority());
    if (authority.getAuthority().equalsIgnoreCase(Roles.WS_CONSUMER.toString())){
      granted = true;//all good
    }
  }
  if (!granted){
    throw new InsufficientAuthenticationException("User does not have sufficient privilages");
  } else {
    SecurityContextHolder.getContext().setAuthentication(authentication);
  }
}
```

By using the Spring Security AuthenticationManager we are able to make use of the Hibernate backed storage from Spring to retrieve the user credentials, obtain the salt value and hash the provided plaintext password in the same way that Spring does but using CXF.

In this way we aren't duplicating logic for both frameworks and can use the same credential store across both the web interface and the web service. 


[CXF]:              			https://cxf.apache.org/docs/ws-security.html
[SOAP-Security]:				https://en.wikipedia.org/wiki/WS-Security
[Spring-Security]:  			https://projects.spring.io/spring-security/
[AuthenticationManager]:     	https://docs.spring.io/spring-security/site/docs/3.0.x/reference/core-services.html
[UsernameToken Authentication]:	https://cxf.apache.org/docs/ws-security.html#WS-Security-UsernameTokenAuthentication

---
layout: post
title:  "The Spring Security Rate Limiting"
date: 2017-02-04
categories: spring security
---

I have covered how Spring Security components are structured by default in a previous [blog post][blog post] about using CXF's WS-Security with Spring Security.

I later had to expand the authentication setup with [rate limiting][rate limiting] to prevent repeated attempts to login to our service, in this way after x unsuccessful login attempts we suspend the user account. This means [brute force][brute force] attackers can be countered easily without reducing usability. If a user inputs an incorrect login x times then this is a sign that either they are not a genuine user or that for reasons we cannot predict their password has changed. A genuine user will have access to out of band support and communication with the system administrator who can then verify the user and re-enable their account. 


### LimitedDaoAuthenticationProvider
This is an extension of our previous `DaoAuthenticationProvider`, it contains a map of usernames and failed login attempts along with an injectable number `loginFailureLimit`.  
This class is the core mechanism for enforcing the rate limiting, every time a user fails to authenticate we increment the failure count. 
```
	...
		} catch (BadCredentialsException e) {
			//Will throw a custom exception if too many failed logins have occurred

			if (authentication instanceof RateLimitedAuthentication){
				RateLimitedAuthentication rateAuth = (RateLimitedAuthentication)authentication;
				if (!rateAuth.isRateLimited()){
					LOG.error("The user is not rate limited");
					throw e;
				}
			}
			String username =  authentication.getName();
			this.incrementRateLimit(username);
	...
```
Note that we are only acting if the authentication class is of type `RateLimitedAuthentication` and has rate limiting enabled, this allows us to either disable rate limiting or be backwards compatible with standard spring authentication if required.

If the count limit is reached then we disable the user and throw a custom exception, if the limit is not reached then we pass on the authentication exception. 
```
	...
			this.incrementRateLimit(username);
			if (this.rateLimitReached(username)){
				//disable the account
				User user = this.userDao.get(username);
				
				user.setEnabled(false);
				this.userDao.update(user);

				throw new RateLimitedException("Too many incorrect logins have been attempted. Account has been disabled.", e);
			} else {
				throw e;
			}
	...
```

### RateLimitedAuthentication
This is an extension of Spring's `UsernamePasswordAuthenticationToken`, it will add a new boolean field called `isRateLimited` to our token which will be used later on in the authentication process by our new `LimitedDaoAuthenticationProvider` as seen above, simply override both constructors to pass in our boolean (don't forget to provide a getter method to provide access later on):
```
	public RateLimitedAuthentication(Object principal, Object credentials, boolean isRateLimited) {
		super(principal, credentials);
		this.isRateLimited = isRateLimited;
	}

	public RateLimitedAuthentication(Object principal, Object credentials, 
		Collection<? extends GrantedAuthority> authorities, boolean isRateLimited) {
		
		super(principal, credentials, authorities);
		this.isRateLimited = isRateLimited;
	}
```

### Extending our UsernameTokenValidator
Our UsernameTokenValidator is also expanded to allow for a new boolean `rateLimited` which will be used to specify that we wish to rate limit access to the web service.
```
	<jaxws:endpoint id="myService"
	... 
				<bean id="usernameTokenValidator" 	class="com.companyname.security.UsernameTokenValidator">
					...
					<property name="rateLimited"	ref="isWebServiceRateLimited"/>
				</bean>
	...
	</jaxws:endpoint>
```
This very simply allows us to pass the boolean to construct our new `RateLimitedAuthentication` object, then it is passed to the AuthenticationManager as we did before. Except this time we'll be wiring up the LimitedDaoAuthenticationProvider as the AuthenticationManager.

### Returning meaningful errors
Now that you have a means to restrict access to your service via a custom `Authentication Provider` you will want to throw and handle specific exceptions.
You can do this by extending the AuthenticationFailureHandler, this handler will allow you accept the AuthenticationException (standard ones or of your own definition) and perform specific actions based on different exceptions and with different logging and HTTP status codes.
```
	public class RateLimitedSimpleUrlAuthenticationFailureHandler implements
		AuthenticationFailureHandler {
	@Override
	public void onAuthenticationFailure(HttpServletRequest request,
			HttpServletResponse response, AuthenticationException exception)
	...
		if (exception instanceof BadCredentialsException){
	...
		else if (exception instanceof RateLimitedException) {
```
You then wire this up in spring in this example I've set it redirect to different pages based on the type of failure: 
```
	<beans:bean id="auth-failure" class="com.companyname.security.RateLimitedSimpleUrlAuthenticationFailureHandler">
		<beans:property name="loginFailureUrl" 		value="/spring/login-failure"/>
		<beans:property name="loginDisabledUrl" 	value="/spring/login-disabled"/>
		<beans:property name="loginRateLimitedUrl" 	value="/spring/login-rate-limted"/>
	</beans:bean>
```
### Pulling it all together
We need to update our `authenticationManager` bean to point to our `RateLimitedDaoAuthenticationProvider` class, it will then be picked up by spring automatically since it is a subclass of the AuthenticationManager.  

```
	<beans:bean id="authenticationProvider" class="com.companyname.security.LimitedDaoAuthenticationProvider">
	...
		<beans:property name="loginFailureLimit" 	ref="loginFailureLimit"/>
	...
	</beans:bean>
```

For the web service bean we only need to add the aforementioned rateLimited boolean, the previously referenced `authenticationManager` bean does not need to be changed since it is still a subclass of the AuthenticationManager.

Finally wire up the `RateLimitedSimpleUrlAuthenticationFailureHandler` to the form-login bean:
```
	<form-login login-page="/spring/views/login"			
			default-target-url="/spring/default-login"
			always-use-default-target="true"
			authentication-failure-handler-ref="auth-failure"/>
```

### Improvements and variations
It should be noted that this solution wouldn't work on a multi instance set up unless a load balancer matches sessions or you have a distributed in-memory cache, with these additions it should scale.  
Another way to share state across instances is to use a database but when being brute force attacked this would still result in you consulting your database which can adversely impact performance since databases tend to be a bottleneck anyway and adding extra load is asking for trouble.  
From a usability perspective I'm increasingly won over by the idea of a time based lockout, e.g. five minutes is long enough to thwart a brute force attack by making it impractical. It is not so long as to majorly inconvenience users, they could go off and pop a cup of tea on and come back, it also removes the need for painful telephone support calls or emails.  


[blog post]:		/spring/security/soap/2016/03/08/the-soap-spring-security.html
[rate limiting]: 	https://en.wikipedia.org/wiki/Rate_limiting
[brute force]:		https://en.wikipedia.org/wiki/Brute-force_attack	





















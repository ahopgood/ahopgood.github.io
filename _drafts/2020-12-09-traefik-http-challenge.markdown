---
layout: post
title:  "Traefik and the HTTP Challenge"
date: 2020-12-09
categories: traefik letsencrypt
---

I've recently written a blog post on [Traefik and TLS Passthrough][TLSPassthrough] and in the intro I covered why I'm interested in using [traefik](https://traefik.io/traefik/) as a reverse proxy.  
In this blog post I'm going to cover an interesting issue I encountered when setting up a Traefik test environment. 

### The Test Environment - The Theory
I am a big proponent of testing and having test environments that are as close to production as possible. This provides a safe space to experiment with new features or configuration and gives you a higher degree of confidence that it will work in production.  
Not having a viable test environment makes me feel like I'm flying blind and in the long term will result in  outages and a time sink in getting a unique production environment back up.  

To this end I want a traefik test environment and a **big** requirement is the ability to test my TLS/Let's Encrypt set up against the [staging environment](https://letsencrypt.org/docs/staging-environment/) because the production service is rate limited and I don't want to lock out my production services when running configuration tests.   

In order for Let's Encrypt to work you need the following things:
* Your service needs to be accessible **externally** so that Let's Encrypt can perform challenges (HTTP or TLS) against your service to prove ownership.
* Your service needs to be linked to the domain it is hosted under and requesting certificates for; this can be done via direct DNS resolution, Virtual Hosts or reverse proxying.
* Let's Encrypt's certbot client needs to be able to persist and modify challenge and subsequent certificate information locally 

The problem with this is:
1. I do not want my test environment exposed to the internet as it is a place I play with features and configuration and it is not always in a final secure state
2. I can only have a single mapping of ports `80` (HTTP) and `443`(HTTPS) on my inbound router to a destination which will be utilised by my production environment.

The set up I desire looks like the following:  
![diagram-traefik-test-environment.svg](/assets/diagram-traefik-test-environment.svg)
1. DNS requests for `mydomain.com` and `test.mydomain.com` hit the router and are forwarded to the **Production Server**
2. The production traefik instance handles all `*.mydomain.com` requests
3. Production service requests are forwarded to the appropriate docker containers
4. Requests that match `*.test.mydomain.com` are forwarded to the **Test Server**
5. The test server will then match the requests to test services and forward to the appropriate tests docker containers


### The Test Environment - In Practice
In a previous post I covered how to [Traefik and TLS Passthrough][TLSPassthrough].  
I thought a similar solution would work for delegating requests to a second traefik instance, I was wrong, oh so wrong.  

In my [dynamic file configuration][traefik-dynamic-file] (virtual-machines.toml) I configured the TCP pass through [**service**][traefik-service] for HTTPS/port `443` access just like for my VM:
```
[tcp]
    [tcp.services.test-traefik-vm-secure.loadBalancer]
      [[tcp.services.test-traefik-vm-secure.loadBalancer.servers]]
          address = "192.168.xxx.xx:443"
```
I also configured a HTTP pass through [**service**][traefik-service] for HTTP/port `80`, again similarly to my VM:
```
[http]
    [http.services.test-traefik-vm]
      [http.services.test-traefik-vm.loadBalancer]
        [[http.services.test-traefik-vm.loadBalancer.servers]]
          url = "http://192.168.xxx.xxx:80"
```
Unlike my VM I chose to use _docker labels_ to create a [router][traefik-router] on the traefik instance so I could take advantage of environmental variable substitution, thereby enabling me to use the **same** docker-compose file for both testing and production:
```
- "traefik.http.routers.test-traefik-vm.rule=HostRegexp(`{wildcard:.+}.${TRAEFIK_TEST_DOMAIN}mydomain.com`)"
- "traefik.http.routers.test-traefik-vm.service=test-traefik-vm@file"
- "traefik.http.routers.test-traefik-vm.entrypoints=web"
- "traefik.tcp.routers.test-traefik-vm-secure-tcp.rule=HostSNI(`service1.${TRAEFIK_TEST_DOMAIN}mydomain.com`,`service2.${TRAEFIK_TEST_DOMAIN}mydomain.com`..."
- "traefik.tcp.routers.test-traefik-vm-secure-tcp.service=test-traefik-vm-secure@file"
- "traefik.tcp.routers.test-traefik-vm-secure-tcp.entrypoints=secure,web"
- "traefik.tcp.routers.test-traefik-vm-secure-tcp.tls.passthrough=true"
```
In the test environment the pass through sub-domain doesn't go anywhere as it is an empty value, in production it goes to my configured `*.test.mydomain.com`.  
Note here that for the HTTP router, we can use a wildcard but for the HTTPS one we need to **explicitly** state the subdomains via the `HostSNI` declaration, this means we need to add an entry for **every new service** we wish to test with HTTPS.  
This is not ideal but I could not find a better solution.  
A keypart here is to use the `tls.passthrough=true`.  

So far so good, I rolled out the configuration to production, my certificate resolver was configured to use the HTTP challenge:
```
- "--certificatesresolvers.myletsencryptresolver=true"
- "--certificatesresolvers.myletsencryptresolver.acme.caserver=${LETSENCRYPT_HOST}"
- "--certificatesresolvers.myletsencryptresolver.acme.email=me@mydomain.com"
- "--certificatesresolvers.myletsencryptresolver.acme.storage=/letsencrypt/acme.json"
- "--certificatesresolvers.myletsencryptresolver.acme.httpchallenge=true"
- "--certificatesresolvers.myletsencryptresolver.acme.httpchallenge.entrypoint=web"
```   
### Trouble in Paradise
When starting up **both** the production and test instances of traefik I would see the correct certificates issued by Let's Encrypt on my production services, lovely!  
When browsing to my **test** services I was being provided with the traefik default certificate, not what I wanted at all, the traffic pass throughs were working but the certificates were not being issued.  

Inspecting the traefik logs from the test instance showed the HTTP challenge was not being answered:
<pre><code>
time="2020-07-16T18:58:12Z" level=error msg="Unable to obtain ACME certificate for domains \"service1.test.mydomain.com\": 
unable to generate a certificate for the domains [service1.test.mydomain.com]: 
acme: Error -> One or more domains had a problem:[service1.test.mydomain.com] 
acme: error: 403 :: urn:ietf:params:acme:error:unauthorized :: Invalid response from http://service1.test.mydomain.com/.well-known/acme-challenge/ckPUVZloEKoA1kBf6eoEoKfqQy9WxCSuOs2MK23ulmA [xxx.xxx.xxx.xxx]: 404, url: 
"providerName=myletsencryptresolver.acme routerName=service1 rule="Host(`service1.test.mydomain.com`)"
</code></pre>

The traefik logs on my production instance also showed an issue with the HTTP challenge:
<pre><code>
time="2020-07-16T18:48:53Z" level=error msg="Error getting challenge for token retrying in 25.075435899s" providerName=myletsencryptresolver.acme
time="2020-07-16T18:48:59Z" level=error msg="Cannot retrieve the ACME challenge for token eHDDehqDesaa3VhwRzmxres-L9Sa0_bns2HRlWw-k2w: cannot find challenge for token eHDDehqDesaa3VhwRzmxres-L9Sa0_bns2HRlWw-k2w" providerName=myletsencryptresolver.acme
</code></pre>

The test logs show that the Let's Encrypt client has setup the challenge token on my test server and Let's Encrypt's service is reporting an error when looking for that challenge on my test domain.  
The production logs show the **production** traefik instance is servicing a request to try find to find the challenge which naturally it cannot find because the challenge is on my test server.  
It seems that the external inbound request to verify the challenge is being intercepted/serviced by the production instance when the challenge can in fact be found on the test instance.  

DIAGRAM HERE? 


### Fixing the Let's Encrypt Challenge

Looking into the code for the [Traefik http challenge](https://github.com/containous/traefik/blob/e9d0a16a3bb6397ee329b1825902bd700f7c1a5d/pkg/provider/acme/challenge_http.go) and the [ACME http challenge](https://github.com/go-acme/lego/blob/master/challenge/http01/http_challenge.go)

* [HTTP entrypoint](https://github.com/containous/traefik/blob/e9d0a16a3bb6397ee329b1825902bd700f7c1a5d/pkg/provider/acme/provider.go#L76)
* [Someone with a similar issue](https://community.containo.us/t/running-custom-http-challenge-controller-in-traefik-well-known/4383)

Switching to the `tls` challenge resolved the issue, I can now issue challenges within the test instance and have them passthrough the production instance to resolve in the test instance. 

* Add detail that `/.well-known/acme-challenge/` urls are being intercepted by a default traefik router even if you specify your own router



[TLSPassthrough]: /traefik/letsencrypt/2020/07/18/traefik-tls-passthrough
[traefik-services]: https://doc.traefik.io/traefik/routing/services/
[traefik-router]: https://doc.traefik.io/traefik/routing/routers/
[traefik-dynamic-file]: https://doc.traefik.io/traefik/providers/file/
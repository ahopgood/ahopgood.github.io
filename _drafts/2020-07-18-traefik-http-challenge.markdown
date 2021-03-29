---
layout: post
title:  "Traefik and the HTTP Challenge"
date: 2020-07-18
categories: traefik letsencrypt
---

### The Problem
* Error `Retrieving the ACME challenge for token` is on the wrong traefik instance
* Response from the external / prod instance
```
time="2020-07-16T18:48:53Z" level=error msg="Error getting challenge for token retrying in 25.075435899s" providerName=myletsencryptresolver.acme
time="2020-07-16T18:48:59Z" level=error msg="Cannot retrieve the ACME challenge for token eHDDehqDesaa3VhwRzmxres-L9Sa0_bns2HRlWw-k2w: cannot find challenge for token eHDDehqDesaa3VhwRzmxres-L9Sa0_bns2HRlWw-k2w" providerName=myletsencryptresolver.acme
```
* Response from the internal / test instance
```
time="2020-07-16T18:58:12Z" level=error msg="Unable to obtain ACME certificate for domains \"bookstack.test.alexanderhopgood.com\": unable to generate a certificate for the domains [bookstack.test.alexanderhopgood.com]: acme: Error -> One or more domains had a problem:\n[bookstack.test.alexanderhopgood.com] acme: error: 403 :: urn:ietf:params:acme:error:unauthorized :: Invalid response from http://bookstack.test.alexanderhopgood.com/.well-known/acme-challenge/ckPUVZloEKoA1kBf6eoEoKfqQy9WxCSuOs2MK23ulmA [141.0.150.202]: 404, url: \n" providerName=myletsencryptresolver.acme routerName=bookstack rule="Host(`bookstack.test.alexanderhopgood.com`)"
```
### The Solution
* [Traefik http challenge][https://github.com/containous/traefik/blob/e9d0a16a3bb6397ee329b1825902bd700f7c1a5d/pkg/provider/acme/challenge_http.go]
* [ACME http challenge](https://github.com/go-acme/lego/blob/master/challenge/http01/http_challenge.go)
* [HTTP entrypoint](https://github.com/containous/traefik/blob/e9d0a16a3bb6397ee329b1825902bd700f7c1a5d/pkg/provider/acme/provider.go#L76)
* [Someone with a similar issue](https://community.containo.us/t/running-custom-http-challenge-controller-in-traefik-well-known/4383)

Switching to the `tls` challenge resolved the issue, I can now issue challenges within the test instance and have them passthrough the production instance to resolve in the test instance. 

* Add detail that `/.well-known/acme-challenge/` urls are being intercepted by a default traefik router even if you specify your own router
---
layout: post
title:  "Spring Boot @ControllerAdvice doesn't take its own advice"
date: 2017-09-25
categories: Spring-boot
---

## The issue
* Works with @ExceptionHandler and @ControllerAdvice( assignableTypes={})
* Fails to work with @ControllerAdvice when the class extends EntityBodyAdvice class
* Ordering is the only way I was able to get my BodyAdvice to work

## The Apache Reverse Proxy / Gateway

## Local host resolution
 
## The future

[BIND]: https://en.wikipedia.org/wiki/BIND
[proxypreservehost]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypreservehost
[proxypass]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypass
[proxypassreverse]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypassreverse
[location]:	https://httpd.apache.org/docs/2.4/mod/core.html#location
[CIDR]: https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

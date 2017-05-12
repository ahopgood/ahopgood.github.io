---
layout: post
title:  "The Spring Security Rate Limiting"
date: 2017-02-04
categories: spring security
---

I have covered how Spring Security components are structured by default in a previous [blog post](link to previous post about spring security) about using CXF's WS-Security with Spring Security.

I later had to expand the authentication setup with [rate limiting][rate limiting] to prevent repeated attempts login to our service, in this way after x unsuccessful login attempts we suspend the user account. This means [brute force][] attackers can be countered easily without reducing usability. If a user inputs an incorrect login x times then this is a sign that either they are not a genuine user or that for reasons we cannot predict their password has changed. A genuine user will have access to [out of bounds][] support and communication with the system administrator who can then verify the user and re-enable their account. 

Extending the AuthenticationProvider with the DaoAuthenticationProvider.
Implementing rate limiting
Note that this wouldn't work on a multi instance setup unless a load balancer matches sessions. You'd need an inter-instance cache.
Wiring up the provider


[rate limiting]:
[brute force]:
[out of bounds]:





















---
layout: post
title:  "The CORS, SRI and CSP Trifecta"
date: 2016-10-04
categories: apache html css javascript
---


```
```
## Cross Origin Resource Sharing - CORS
[CORS][CORS]
### What does it do?
### How does it do it?

## Sub Resource Integrity - SRI
[SRI][SRI]
### What does it do?
### How does it do it?

## Content Security Policy - CSP
[CSP][CSP]
Install headers in Apache
`sudo a2enmod --force headers`
Restart the servers
`sudo service apache2 restart`
Add your CSP directive:
`Header set Content-Security-Policy "default-src 'self';"`

The useful site [content-security-policy][CSP Values] provides a great breakdown of which directives and sources you can setup.

### What does it do?
### How does it do it?


[CORS]:			https://wikipedia.co.uk/CORS
[SRI]:			https://en.wikipedia.org/wiki/Subresource_Integrity
[CSP]:			https://en.wikipedia.org/wiki/Content_Security_Policy
[CSP Values]:	https://content-security-policy.com/





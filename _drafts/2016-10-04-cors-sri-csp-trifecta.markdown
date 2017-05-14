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
### What does it do?
[SRI][SRI] allows a web page to specify an *expected* hash for externally hosted resources that the page uses, such as stylesheets and JavaScript files hosted on a Content Delivery Network (CDN).  
By specifying the hash for an expected file any tampering of the file can be detected.
### How does it do it?
The browser is responsible for calculating the hash of the delivered file.  
Difference hashing strategies can be specified by the web page, currently only the following are allowed in the W3 spec:
* sha256
* sha384
* sha512  

### Caveats
* Requires browser support, see [caniuse.com](https://caniuse.com/#feat=subresource-integrity) or to [test your browser](http://w3c-test.org/subresource-integrity/subresource-integrity.sub.html).  
* Requires the end user to calculate the hash, if they do this incorrectly or enter a malformed hash their resource won't load. An [online hash generator](https://www.srihash.org/) can be used instead.
* Only applies to `<script>` and `<link>` tags currently (i.e. stylesheets and JavaScript)

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





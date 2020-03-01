---
layout: post
title:  "The CORS, SRI and CSP Trifecta"
date: 2018-04-05
categories: CORS CRI CSP
---

There are three similar sounding security acronyms that you can take advantage of to help secure your websites and services:

* `CORS` - Cross Origin Resource Sharing
* `SRI` - Sub-Resource Integrity 
* `CSP` - Content Security Policy

Each one has a purpose and solves a specific issue(s).

## Cross Origin Resource Sharing - CORS
### What does it do?
The [same-origin policy][SOP] is a **browser** based security mechanism to ensure content is served only from the same **origin** (a top level domain to you and I, e.g. [http://good.com]()) on which it is hosted.  
This essentially means that [http://evil.com]() cannot request the content from [http://good.com]() and present it as its own, this prevents our evil website from creating a fake login page and intercepting all the usernames and passwords for our valued [http://good.com]() users. 

In fact for many cookie based credentials systems a Cross-Site Request Forgery [CSRF][CSRf] (as these attacks impersonating a legitimate user are known) can be submitted without even needing to mock up a fake login page. Any suspect page could try to talk to [http://good.com]() and would be given access to the cookie storage for the domain it is _trying_ to talk to, which is why the same-origin policy is important.    
 
And this made sense for a while as website presentation and the server that provided the presentation data (and any logic behind it) tended to be on the same domain.  
Except with the advent of web based Application Programming Interfaces (APIs) suddenly there were many domains that not only provided data and logic for their own presentation (same-origin) but they were also wanting to open up their APIs to other websites on different domains or were hosting their front ends separately from their APIs.  

This is where Cross Origin Resource Sharing ([CORS][CORS]) comes in to allow sharing of resources (often APIs provide these resources) across different origins (domains).   

### How does it do it?
A CORS enabled web server will provide a list of **allowed origins** that can access its resources.  
When a client (typically a web browser) submits a request to read or modify a resource on a web server it will pass its domain in the `Origin` header, in the case of [http://evil.com]() this will be rejected by the web server with a `403 Forbidden` response as it is not on our allowed origin list.  

![CORS in action][CORS-image]

The [Enable CORS][Enable CORS] page provides the means to enable CORS on many popular web servers.  

### Caveats
* Requires browser support; check [caniuse.com][CORS caniuse].
* Security is limited to the sites you set in your policy, if one of these sites are compromised there's not much a CORS policy can do for you.
* Many people opt for a top-level wildcard policy in their development environments e.g. `*` which allows **any** origin and then they forget to tighten it in production, don't be this person.
* If your data, presentation and logic are handled on the _same domain_ then you don't need a CORS policy, don't even open yourself up to misconfiguration (see wildcard point above).  
* You cannot wildcard sub-domains e.g. `*.mydomain.com` so you need to enter _each sub-domain explicitly_ into your policy.

## Sub Resource Integrity - SRI
### What does it do?
[SRI][SRI] allows a web page to specify an **expected** hash for externally hosted resources that the page uses, such as stylesheets and JavaScript files hosted on a Content Delivery Network (CDN).  
By specifying the hash for an expected file any tampering of the file can be detected.

### How does it do it?
The browser is responsible for calculating the hash of the delivered file.  
Different hashing strategies can be specified by the web server, currently only the following are allowed in the W3 spec:
* `sha256`
* `sha384`
* `sha512`

The browser then compares the calculated hash against the one provided by the web server, if the hashes do not match then this indicates the file has changed in an unexpected way and the resource will not be loaded.  

![SRI in action][SRI-image]

An example of a sha384 integrity check on jQuery:
```
<script src="https://code.jquery.com/jquery-3.2.1.min.js" 
	integrity="sha384-xBuQ/xzmlsLoJpyjoggmTEz8OWUFM0/RC5BsqQBDX2v5cMvDHcMakNTNrHIW2I5f" 
	crossorigin="anonymous">
</script>
```

### Caveats
* Requires browser support, see [caniuse.com][SRI caniuse].  
* Requires the end user to calculate the hash, if they do this incorrectly or enter a malformed hash the resource won't load. An [online hash generator][SRI Hash] can be used instead.
* Only applies to `<script>` and `<link>` tags currently (i.e. stylesheets and JavaScript)

## Content Security Policy - CSP

Cross-Site Scripting (shortened to [XSS][XSS]) is a common attack whereby a malicious user takes advantage of a web page that displays user submitted data without any checks.
An example flow would be a comments section on a blog:  
1. The malicious user will submit some code (usually Javascript) to the web page as a user comment
2. The server then serves up that content to other users
3. The browser trusts this content provided by the server but as the content is actually a script the browser will **trust** and execute this script
4. Now we have a script executing on our blog domain with full access to the browser side storage where it can steal credentials stored in cookies or even harvest user data as they enter it.

![XSS in action][CSP-before-image]

### What does it do?
A Content Security Policy ([CSP][CSP]) is designed to allow you to tell a browser what resources you expect to be trustworthy.  
This takes the form of domains you allow resources to be loaded from and the browser will only execute those resources that originate from source files on those domains.  

Furthermore the CSP can also disable execution of _inline_ (`<script>`) and `eval()` scripts, this is particularly useful in our blog example where the content is being loaded from the same domain by our own web server. In this way we can protect against the injected code hiding in our comments.  

### How does it do it?
The server specifies a `Content-Security-Policy` header containing the _directives_ of your policy, this essentially tells the browser the types of resource you expect to be executed and the browser will honour this.

![CSP in action][CSP-after-image]

The useful site [content-security-policy.com][CSP Values] provides a great breakdown of which directives and sources you can setup.  

Below are the steps to implement a CSP on Apache:
* Install headers in Apache `sudo a2enmod --force headers`
* Restart the Apache server to load the module `sudo service apache2 restart`
* Add your CSP directive: `Header set Content-Security-Policy "default-src 'self';"`

Our policy will prevent **any** execution of resources except those that originate from the same origin (`self`) of our page, this is the default fallback for **all** CSP directive types, inline resources are denied by default. 

### Caveats
* The effectiveness of a CSP relies heavily on the support of the browser, [caniuse.com][CSP caniuse] will let you know what the current state of browser support is.
* It is still possible to specify an _insecure_ Content Security Policy, use a tools such as [Google's CSP Evaluator][CSP Evaluator] to check you haven't left a directive open that you were not planning to.

## Summary
These three different mechanisms provide the means to protect against the following attacks on your web site:
* [Cross-Site Request Forgery][CSRF] - use a Cross Origin Resource Sharing (CORS) policy
* Content Delivery Network (CDN) compromise - use Sub-Resource-Integrity (SRI)
* [Cross-Site Scripting (XSS) attacks][XSS] - use a Content-Security-Policy (CSP)

Sadly these features are only as good as the browsers that support them, it may be worthwhile to be selective around the browsers you support and feature functionality you allow them to access. 

[CORS]:				https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
[SOP]:				https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy
[Enable CORS]:		https://enable-cors.org/
[CORS caniuse]:		https://caniuse.com/#feat=cors
[CSRF]:				https://developer.mozilla.org/en-US/docs/Glossary/CSRF
[SRI]:				https://en.wikipedia.org/wiki/Subresource_Integrity
[SRI caniuse]:		https://caniuse.com/#feat=subresource-integrity
[SRI Hash]:			https://www.srihash.org/
[CSP]:				https://en.wikipedia.org/wiki/Content_Security_Policy
[CSP caniuse]:		https://caniuse.com/#feat=contentsecuritypolicy
[CSP Values]:		https://content-security-policy.com/
[XSS]:				https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting
[CSP Evaluator]:	https://csp-evaluator.withgoogle.com/
[CSP fallback]:		http://www.debug.is/2015/10/18/fallback-for-cdn-provided-js-when-using-csp/


[CORS-image]: 		/assets/CORS-vs-SRI-vs-CSP/CORS.png
[SRI-image]: 		/assets/CORS-vs-SRI-vs-CSP/SRI.png
[CSP-before-image]: /assets/CORS-vs-SRI-vs-CSP/Before-CSP.png
[CSP-after-image]: 	/assets/CORS-vs-SRI-vs-CSP/After-CSP.png
---
layout: post
title:  "Java's Regex Grouping"
date: 2018-02-18
categories: Java
---

I recently used Java's regex matching and powerful grouping feature and yet again remembered just how powerful it can be.

Compile pattern.compile()

Use the matcher to `find` a match for an input string.
Note compiling the pattern can be done once and then reused many times over.
`[a-z]{2}[0-9]`
## Grouping 
`([a-z]{2})([0-9])`

0 = whole group
1 = first group

## Grouping by name
`([a-z]{2})([0-9])`


Using grouping can make debugging and building up a regex much easier as you can print off the group content to see what it matches on and then continue with your expression.

[BIND]: https://en.wikipedia.org/wiki/BIND
[proxypreservehost]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypreservehost
[proxypass]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypass
[proxypassreverse]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypassreverse
[location]:	https://httpd.apache.org/docs/2.4/mod/core.html#location
[CIDR]: https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

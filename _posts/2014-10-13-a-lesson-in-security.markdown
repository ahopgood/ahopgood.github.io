---
layout: post
title:  "A lesson in security testing"
date:   2014-10-24
categories: security ws-security testing cve
---
Recently I was submitted a bug report for a web service and administration web pages that I created over a year and a half ago. This bug report stated that our service was completely accessible **without** authentication via a basic `http GET` request. 

*"What, this cannot be!"* I thought.

*"I definitely remember testing basic http access against the web service component"* I said.
 
Now this was a standalone project that was only tangenitally related to our main project and was designed as a one off creation. For these reasons we only had unit test coverage, there was no higher level [Behavioural Driven Development][BDD] style tests for the web / web service layer. Instead we stuck with some manual testing, after all this was a small self contained project with few edge cases, this is easily testable by a human right? 

Right and wrong there.

*Yes* it was testable in a reasonable amount of time by a human **but** and it is a big but, these human tests are only cost effective if they are done once and only when the project is code complete and not going to change. There are problems with this approach:

* When the code changes you need to drag your human back into testing every variation.
* Usually the test plan is not tightly coupled to the code base, this can become out of date quickly and easily.
* It is easy to make changes assuming you haven't broken anything.

So what happened?

I then spent hours trawling the web looking for similar problems, no luck.

I started looking into how the [web service security layer][WSSE] interacts with the web security framework I was using. I could block the `http GET` but that would then block access to the web service by the web service clients and the service would be functionally useless. If I allowed access for the web service clients then I would leave open the vulnerability making a mockery of trying to protect the service from unauthorised access.

I was about ready to let my manager know the good news that we had a serious security issue that I had no idea how to fix and had no idea how long it would take. We were incredibly busy with an impressive backlog of items to work on so this news was going to blow a gaping wide hole in our upcoming releases.

Then in a stroke of luck a colleague forwarded on a [Common Vulnerabilities and Exploits][CVE] listing for the web service dependency in said project (we use this particular package in our main project for consuming web services, not producing as is the purpose of this project). It turns out that the exact issue I was looking to resolve by hook or crook was in fact a *known vulnerability*, eureka! No more contemplating horrible hacks or hours of endless and futile searching, instead all I needed to do was upgrade to a newer version without the vulnerability.

How did this slip through my manual testing?

Then I found it, looking through the commit logs before the system went live:

**Updated dependency xxx to improve reliability**

Oh, yeah, that would do it wouldn't it? So due to a lack of automated testing and an over reliance on manual testing, a simple library upgrade opened up a serious security vulnerability. The lesson learnt here is that whilst automated testing may take a while to setup (and isn't infallible) it will increase your odds of catching such errors, the main benefits being (and not restricted to):

* Quickly knowing when a change has broken your system
* The tests themselves help document the system
* They can be run automatically, no human intervention required, your human can be working on something else of value.

In the meantime I have also introduced the [OWASP Dependency check maven plugin][OWASP Dep Checker] to our main project's parent `pom.xml` this can be run locally (warning it takes around 20-30 mins on first run for it to download the vulnerability database) and / or can be run as part of your maven site generation. This plugin will scan all your dependencies (aka libraries) and will attempt to match them up with known vulnerabilities in the [Network Information Security & Technology][NIST] Vulnerability Database from which the [CVE][CVE] database is derived. In this way you can also check your builds for vulnerabilities pre release, this combined with a decent set of automated tests should give you a reasonable amount of protection from unexpected changes brought about by updating libraries

[Owasp Dep Checker]: https://www.owasp.org/index.php/OWASP_Dependency_Check
[NIST]:	http://nvd.nist.gov/
[BDD]: 	http://en.wikipedia.org/wiki/Behavior-driven_development
[WSSE]: http://en.wikipedia.org/wiki/WS-Security
[CVE]: 	https://cve.mitre.org/

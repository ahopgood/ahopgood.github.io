---
layout: post
title:  "The Security Pincer"
date: 2015-03-23
categories: security java
---

In my role as a Team Lead I attend monthly company wide security meetings with representatives of each team (in the form of other Team Leads), the head of operations, the VP of engineering and the CTO. In these meetings we discuss the latest security exploits and how they might used against our products and infrastructure.

Our company wide security meetings would frequently rely on the diligence of the attendees to read about and understand the implications of security exploits in order for us to categorise and prioritise remedial actions (if any). Considering the other responsibilities these attendees have on a day to day basis this isn't an optimal approach. 

### Notification of new exploits

I found myself wondering how we could improve on this?

I did some research and discovered that [NIST][NIST] applies a Common Vulnerability Scoring System (CVSS) score to the Common Vulnerabilities and Exploits (CVEs) database maintained by [MITRE][MITRE] and expresses the applicability of these vulnerabilities using the Common Platform Enumeration (CPE) it then publishes these as an RSS feed of exploits.  
 
One is published immediately after the exploit is confirmed and the second is after the exploit has been [analysed][NIST Analysed] and its publishing lags behind the initial exploit feed by a few days. I chose this second feed as the analysis is useful to us, it provides more information about the severity of the exploit and the higher level software it impacts (e.g. an exploit in [libgc's `getIaddr()`][libgc-exploit] method will impact Apache) and since our meetings are monthly the delay seemed to be acceptable in the face of more clarity.

We now have the list of exploits as they are classified, although as RSS feeds don't persist how do we ensure our monthly security council knows about them? Using [If This Then That][IFTTT] I set up the RSS feed as a source and used a connector to my work email account, this would fire off an email for every new item on the feed. Now every exploit will be recorded in the destination email address ready for evaluation at our security council meetings.

### Backtracking to cover old exploits

I also run regular security meetings with my own team for them to raise general security issues that they have identified or have reservations about. This helps us cover the security exploits that are generated in the way in which we write our code, this is a matter of team training around security anti-patterns and best practises at all stages of the development life-cycle.

I felt that I now had a handle on the emergence of new exploits due to the NIST RSS feed via IFTTT to my email account but what I didn't have was a historical view of exploits in our software stack. As any developer knows, keeping libraries and frameworks up to date is a difficult task even without security risks being thrown in to raise the priority and up end any backlog ordering.

I discovered the [OWASP Dependency Check][dependency-check] plugin for maven a [while ago][a lesson in security testing], this very cleverly pulls down information on CVEs from NIST and creates a local database. This database is then used to calculate the CVEs that apply to your maven artifacts, this process produces matches with a certain calculated degree of accuracy.

[IFTTT]:			https://ifttt.com/
[NIST]:				https://nvd.nist.gov/
[MITRE]:			https://cve.mitre.org/find/
[NIST Analysed]:	https://nvd.nist.gov/download/nvd-rss-analyzed.xml
[libgc-exploit]:	https://www.exploit-db.com/exploits/39454/
[dependency-check]:	https://www.owasp.org/index.php/OWASP_Dependency_Check
[a lesson in security testing]: https://ahopgood.github.io/security/ws-security/testing/cve/2014/10/24/a-lesson-in-security.html
























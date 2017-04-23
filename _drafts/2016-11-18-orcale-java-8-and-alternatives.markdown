---
layout: post
title:  "Oracle Java 8 and Alternatives"
date: 2016-10-04
categories: Java8 Oracle RedHat CentOS Puppet
---
Explain what my puppet module does (install major version, remove minor version on centos if default is set and then install alternatives for each entry) 
Explain behaviour in upgrade-downgrade cycle
Explain that it doesn't happen in downgrade-upgrade cycle
Observation that when running in --debug mode the install calls to alternatives seemed to be passing
Observation that set calls were failing.
List of calls that were failing, note they are all /jre/bin executables 
Error message on set call
```
```
List of /etc/alternatives
```
```
Output of alternatives --display orbd
```
```
Notice that install call would actually fail when running manually.
Notice that `echo $?` would return 0 - success erroneously.
Note the google article with the closest matching search suggested checking /var/lib/alternatives
```
```
See that removing the entry allowed things to proceed.
Conclusion that based on observations that Java 8 after a certain version was making use of alternatives, couldn't test as there were nearly a hundred updates between my testing versions.

Install Java 8u111
Output of alternatives --display java
```
```
Note that they are slaving many of the /jre/bin executables which matches the install calls that were failing.

Link to Oracle page explaining that Java 8u40 onwards now uses alternatives

Modify puppet module to add orbd? to Java entry as a slave as a proof of concept, now it doesn't fail.

Change all to be slaves
Note the the `--parser=future` is needed for puppet 3.7.x or higher up to puppet 4.0.0

[]:	
[]:
[]:





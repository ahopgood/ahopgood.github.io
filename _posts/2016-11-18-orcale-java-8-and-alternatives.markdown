---
layout: post
title:  "Oracle Java 8 and Alternatives"
date: 2016-10-04
categories: Java8 Oracle RedHat CentOS Puppet
---
<!--
<img src="/assets/Debian-Logo.png" width="200" alt="Debian Logo">
-->
![CentOS Logo](/assets/centos-icon.svg){: .padded-fixed-width-image }
![Java Logo](/assets/java.svg){: .padded-fixed-width-image }
![Puppet Logo](/assets/puppet.svg){: .padded-fixed-width-image }

<!--
<img src="/assets/java.svg" width="200" alt="Java Logo">
<img src="/assets/puppet.svg" width="200" alt="Puppet Logo">
-->
### My puppet Java module
I have written a Java puppet module to help develop my puppet "skillz", on the whole it has been a valuable learning experience. I have learnt to write separate manifests to handle differences in linux distros (CentOS & Ubuntu), to have major versions of Java cohabit via multi tenancy on the same OS and to manage Java related non-core functionality such as upgrading the Java Cryptography Extensions.

In order to allow switching between major versions of Java on the same OS I make use of the alternatives framework to set the default version, this is the version which will respond when `java --version` is entered on the command line.

The module on CentOS will install the specified version (either major or update version) and then use a call to query rpm for other installed versions. If we've specified that major versions are allowed multi tenancy then this will just remove update versions, if we only allow one major version then this will remove all major and update versions.

Whilst running tests on my module I noticed a very specific failure; essentially upgrading to Java 8 from Java 6 and then downgrading back to Java 6 would result in the alternatives values not changing when downgrading. The flow was as follows:
>Java 6u45 -> Java 8u112 -> Java 6u45

Interestingly it didn't happen in scenarios where we start with Java 8 and then downgrade to Java 6, you need to have upgraded first for the downgrade to fail.

### Downgrade Failure
When downgrading from 8u112 to 6u45 the scripts install the alternatives but fail on setting a subset of the alternatives entries, an example is provided below:
```
Notice: /Stage[main]/Main/Java[java-6]/Java::Default::Set[set-default-to-java-6]/Alternatives::Set[orbd-set-alternative]/Exec[set-alternative-orbd]/returns: failed to read link /usr/bin/orbd: No such file or directory
Error: alternatives --set orbd /usr/java/jdk1.6.0_45/jre/bin/orbd returned 2 instead of one of [0]
```
Trying to run the set command manually resulted in the same failure message so I knew it wasn't an issue with puppet. Interestingly the list of calls that were failing, were all /jre/bin executables:
```
Error: alternatives --set orbd /usr/java/jdk1.6.0_45/jre/bin/orbd returned 2 instead of one of [0]
Error: alternatives --set policytool /usr/java/jdk1.6.0_45/jre/bin/policytool returned 2 instead of one of [0]
Error: alternatives --set pack200 /usr/java/jdk1.6.0_45/jre/bin/pack200 returned 2 instead of one of [0]
Error: alternatives --set tnameserv /usr/java/jdk1.6.0_45/jre/bin/tnameserv returned 2 instead of one of [0]
Error: alternatives --set servertool /usr/java/jdk1.6.0_45/jre/bin/servertool returned 2 instead of one of [0]
Error: alternatives --set rmid /usr/java/jdk1.6.0_45/jre/bin/rmid returned 2 instead of one of [0]
Error: alternatives --set keytool /usr/java/jdk1.6.0_45/jre/bin/keytool returned 2 instead of one of [0]
Error: alternatives --set ControlPanel /usr/java/jdk1.6.0_45/jre/bin/ControlPanel returned 2 instead of one of [0]
Error: alternatives --set unpack200 /usr/java/jdk1.6.0_45/jre/bin/unpack200 returned 2 instead of one of [0]
Error: alternatives --set javaws /usr/java/jdk1.6.0_45/jre/bin/javaws returned 2 instead of one of [0]
Error: alternatives --set rmiregistry /usr/java/jdk1.6.0_45/jre/bin/rmiregistry returned 2 instead of one of [0]
```
When running puppet in `--debug` mode the install calls to alternatives seemed to be passing with a zero status showing success.
```
Debug: Executing 'alternatives --install /usr/bin/orbd orbd /usr/java/jdk1.6.0_45/jre/bin/orbd 306 --slave /usr/bin/orbd.1.gz orbd.1.gz /usr/java/jdk1.6.0_45/man/man1/orbd.1.gz '

Notice: /Stage[main]/Main/Java[java-6]/Java::Default::Install[install-default-to-java-6]/Alternatives::Install[java-6-orbd]/Exec[java-6-orbd-install-alternative]/returns: executed successfully
```
### Proof of install failure
Trying to work out the current state of alternatives I decided to query alternatives itself and viewing the linking files in /etc/alternatives.  
Focussing on the orbd command the output of `alternatives --display orbd` returned:
```
$ alternatives --display orbd
failed to read link /usr/bin/orbd: No such file or directory
```
The link from /etc/alternatives to the location in the /jre/bin directory is missing, only the man page remains:
```
$ ls -l /etc/alternatives/ | grep orbd
lrwxrwxrwx  1 root root 40 Apr 20 12:29 orbd.1.gz -> /usr/java/jdk1.8.0_31/man/man1/orbd.1.gz
```
These findings indicate that the install had also failed, running the install line from the previous section which had reported `executed successfully` showed the same error as the set call, except running `echo $?` to get the exit code showed an exit code of `0` so it was **failing but reporting a success**!

The google result with the [closest matching search][closest matching search] for this error type suggested checking /var/lib/alternatives, which I duly did for a specific entry `orbd`:
```
$ ls -l /var/lib/alternatives/ | grep orbd
-rw-r--r--  1 root root  213 Apr 20 08:00 orbd
```
It would seem that alternatives is still retaining some linking files which is preventing the installing or setting of a different alternative with the same name. The rest of the directory had entries for **every** /jre/bin binary that had failed in the puppet call previously so there is definitely a link here.
Removing this entry as suggested in the google search allowed the install to proceed.

### Java 8 update 31 vs update 112
I was able to replicate the same experience between two versions of Java 8; update version 31 **didn't** have any issues installing on its own, upgrading to update version 112 also **didn't** exhibit any issues. However downgrading **back** to update version 31 **failed** to set the alternatives (and install them as discovered previously).
I concluded that based on these observations that Java 8 after a certain version is somehow making use of alternatives, this is difficult to test and peg to a paricular update version as there are nearly eighty updates between my testing versions.

In order to prove that alternatives entries were being manipulated by a certain update version of Java 8 I went through a manual .rpm install of Java 8u112.
After which I queried the output of `alternatives --display java`
Interestingly Java 8uxxx post 31 (based on anecdotal experience) indeed now installs to alternatives:
```
[vagrant@java-dev-centos7 ~]$ sudo alternatives --display java
java - status is auto.
 link currently points to /usr/java/jdk1.8.0_111/jre/bin/java
/usr/java/jdk1.8.0_111/jre/bin/java - priority 180111
 slave ControlPanel: /usr/java/jdk1.8.0_111/jre/bin/ControlPanel
 slave javaws: /usr/java/jdk1.8.0_111/jre/bin/javaws
 slave jcontrol: /usr/java/jdk1.8.0_111/jre/bin/jcontrol
 slave jjs: /usr/java/jdk1.8.0_111/jre/bin/jjs
 slave keytool: /usr/java/jdk1.8.0_111/jre/bin/keytool
 slave orbd: /usr/java/jdk1.8.0_111/jre/bin/orbd
 slave pack200: /usr/java/jdk1.8.0_111/jre/bin/pack200
 slave policytool: /usr/java/jdk1.8.0_111/jre/bin/policytool
 slave rmid: /usr/java/jdk1.8.0_111/jre/bin/rmid
 slave rmiregistry: /usr/java/jdk1.8.0_111/jre/bin/rmiregistry
 slave servertool: /usr/java/jdk1.8.0_111/jre/bin/servertool
 slave tnameserv: /usr/java/jdk1.8.0_111/jre/bin/tnameserv
 slave unpack200: /usr/java/jdk1.8.0_111/jre/bin/unpack200
 slave java.1: /usr/java/jdk1.8.0_111/man/man1/java.1
 slave javaws.1: /usr/java/jdk1.8.0_111/man/man1/javaws.1
 slave jjs.1: /usr/java/jdk1.8.0_111/man/man1/jjs.1
 slave keytool.1: /usr/java/jdk1.8.0_111/man/man1/keytool.1
 slave orbd.1: /usr/java/jdk1.8.0_111/man/man1/orbd.1
 slave pack200.1: /usr/java/jdk1.8.0_111/man/man1/pack200.1
 slave policytool.1: /usr/java/jdk1.8.0_111/man/man1/policytool.1
 slave rmid.1: /usr/java/jdk1.8.0_111/man/man1/rmid.1
 slave rmiregistry.1: /usr/java/jdk1.8.0_111/man/man1/rmiregistry.1
 slave servertool.1: /usr/java/jdk1.8.0_111/man/man1/servertool.1
 slave tnameserv.1: /usr/java/jdk1.8.0_111/man/man1/tnameserv.1
 slave unpack200.1: /usr/java/jdk1.8.0_111/man/man1/unpack200.1
Current `best' version is /usr/java/jdk1.8.0_111/jre/bin/java.
```
Note that they are slaving all of the /jre/bin executables which match the install/set calls that were failing.
When my puppet module installed a value into alternatives for each binary in `/jre/bin` individually it would break as Java 8uxxx would remove this entry but leave in place our manual java 8 entries and leave behind orphaned stubs.

I found an Oracle page explaining that Java 8u40 onwards now uses alternatives, turns out it commenced from update version 40 according to the [linux install notes from Oracle][linux install notes from Oracle]:   
> Starting with version 8u40, the JDK installation is integrated with the alternatives framework and after installation, the alternatives framework is updated to reflect the binaries from > the recently installed JDK. Java commands such as java, javac, javadoc, and javap can be invoked from the command line.

### How to fix
There are two solutions to this issue:
1. Manually remove the `/var/lib/alternatives` stubs after uninstalling Java 8uXXX where XXX>39
2. Modify the puppet module to install java & javac in alternatives with matching `--slave` entries as Java 8u40 onwards instead of an independent entry for each binary.

Note that in order to pass in the collection of slaves to our Java/alternatives module the puppet apply parameter: `--parser=future` is needed for puppet 3.7.x or higher (up to puppet 4.0.0, after which is it featured in the standard parser) to merge and then flatten the data.

[closest matching search]:         https://johnglotzer.blogspot.co.uk/2012/09/alternatives-install-gets-stuck-failed.html
[linux install notes from Oracle]:  https://docs.oracle.com/javase/8/docs/technotes/guides/install/linux_jdk.html#A1098871

---
layout: post
title:  "Debian Java Packaging"
date: 2015-11-05
categories: java debian linux
---

Intro - why doesn't Debian provide Oracle installers for Java?
What issues did I find with the online repository I found? Link
What issues did I find with following debian packaging guidelines? Java binary seems to be marked as changed by the debian packager compared to the .orig file. 
Step by step guide to creating the package
Warnings about the generated package working on only the version of debian/ubuntu that it is created on


Essentially installing offline Oracle Java packages for Debian

The oracle java repositories for Debian/Ubuntu are managed by webupd8team.  
Add the repository: `sudo add-apt-repository ppa:webupd8team/java`  
Perform an update: `sudo apt-get udpate`  
Install the jdk package: `sudo apt-get install oracle-java8-installer`  

Write up the current situation where .rpms are provided but .deb files are not.  
Write up that there is a third party repository that provides these .deb files. Include repo name.
Write up the following issues with these .deb files:
* They wget the source code from the oracle site, meaning you cannot use these .deb files offline.
* By retrieving only the latest version of the java source code you cannot specify a version, which is not useful for system admins that have only performed quality analysis on a particular version.  
* It is also missing JCE extensions for Java 6.  



#### Making your own Java packages
[A helpful guide on Java Packing](https://wiki.debian.org/JavaPackage)  
Add the debian repo, either through the `settings -> Software & Updates -> Other Software -> Add` section of the gui adding the line `http://httpredir.debian.org/debian/ jessie main contrib` or using the command line adding `deb http://httpredir.debian.org/debian/ jessie main contrib` to the `/etc/apt/sources.list` file.  
`apt-get update` to update the repository listings.  
`apt-get install java-package` to install the java package program.  
Download the binary files (either .bin or .tar.gz from the Oracle website).  
Run `make-jpkg <binary-name>`.  
The package you create will have dependencies local to the Ubuntu version you are creating it on.  
For example creating a Java .deb file on wily will require libasound2 >= 1.0.16 and libgtk2.0-0 >= 2.24.0.  
It will also restrict whether you are able to create an x586 or x64 version.  

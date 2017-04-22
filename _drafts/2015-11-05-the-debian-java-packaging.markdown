---
layout: post
title:  "Debian Java Packaging"
date: 2015-11-05
categories: java debian linux
---

<img src="/assets/Debian-Logo.png" width="200" alt="Debian Logo">

### Intro - why doesn't Debian provide Oracle installers for Java?
The [Oracle download page][Oracle download page] provides installers for Red Hat linux (in .rpm form) and as generic source (in gzipped tar balls) but no installers are provided for Debian based systems and hence not for Ubuntu as it is derived from Debian too.
This is because the Oracle license for Java does not allow for binaries to be hosted on a Personal Package Archive (PPA). 

There are oracle java repositories for Debian/Ubuntu managed by the [webupd8team][webupd8team].  
Add the repository: `sudo add-apt-repository ppa:webupd8team/java`  
Perform an update: `sudo apt-get udpate`  
Install the jdk package: `sudo apt-get install oracle-java8-installer`  

These will prompt you to accept the Oracle license.
Unfortunately these installers actually result in a wget call to the Oracle download site to retrieve the generic source and then install it, this poses two problems:

1. The **.deb** installer files are not able to be installed without an internet connection making them unsuitable for isolated/offline systems.
2. You cannot specify the version you want due to the fact that the wget call only pulls the latest version from Oracle meaning that a system admin who wants a specific version is unable to control the update version that gets installed. 

Bearing in mind that an update could be happening over multiple machines with limited if any internet connection over time resulting in inconsistent versions across an install base. This is not desirable as only a specific version may have been tested with other system components.  

### Making your own Java packages
Luckily there are tools to help, a guide on [Java Packaging][Java Packaging] for example details the use of the Java Package utility:

* Add the debian repo, either through the gui or command line:
	* Using Ubuntu's home menu `settings -> Software & Updates -> Other Software -> Add` section of the gui adding the line `http://httpredir.debian.org/debian/ jessie main contrib` 
	* Using the command line adding `deb http://httpredir.debian.org/debian/ jessie main contrib` to the `/etc/apt/sources.list` file.  
* `apt-get update` to update the repository listings.  
* `apt-get install java-package` to install the java package program.  
* Download the binary files (either .bin or .tar.gz from the Oracle website).  
* Run `make-jpkg <binary-name>`.  

The package you create will have dependencies local to the Ubuntu version you are creating it on.  
For example creating a Java .deb file on Ubuntu 15.10 (wily) will require libasound2 >= 1.0.16 and libgtk2.0-0 >= 2.24.0.  
It will also restrict whether you are able to create an x686 or x64 version.


[Oracle download page]:	https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
[webupd8team]:			http://www.webupd8.org/2012/01/install-oracle-java-jdk-7-in-ubuntu-via.html
[Java Packaging]: 		https://wiki.debian.org/JavaPackage
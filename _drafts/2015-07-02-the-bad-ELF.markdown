---
layout: post
title:  "The bad ELF"
date: 2015-08-15
categories: java linux 64-bit
---

Whilst writing a puppet module for CentOS I came across an interesting issue with 64-bit compatibility. 

When trying to install a 32-bit version of Java onto a 64-bit version of CentOS, puppet spat out this not so informative error: 


> /lib/ld-linux.so.2: bad ELF interpreter: No such file or directory java

What this means to you and me is that the linux kernel doesn't support the architecture of Java (32-bit) that you are trying to install.

Installing the matching architecture type; 32-bit Java on a 32-bit linux kernel will solve this. 
 
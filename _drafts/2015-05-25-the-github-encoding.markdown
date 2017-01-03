---
layout: post
title:  "The github encoding"
date: 2015-05-25
categories: version control github windows linux
---
Currently I have a Windows based host that runs linux based vagrant VMs to test puppet modules I write.  
Recently after checking out and firing up the VM for my tomcat module on a newly formatted Windows host, one of the shell scripts failed to run. 

Linux file on VM -> windows Host -> github  
A linux script is created in a linux VM, the file is committed to github via the Windows host this results in a file that is converted into the LF line ending.  
The file will continue to work on this machine as the file ending on the local filesystem is still in LF.  

Linux VM <- Windows Host <- github
The script file with LF line endings is checked out and converted into CRLF on the Windows host by git and run on the linux VM, this will fail due to the conversion to CRLF on checkout. 


![Git providing the choice of line endings](/assets/GitLineEndingsChoice.png)

What I should have chosen was **Checkout as-is, ** for puppet linux projects, in this way 

Per project setting of core.autocrlf should be set to false to ensure that 

[dos2unix]:			http://dos2unix.sourceforge.net/


https://stackoverflow.com/questions/5834014/lf-will-be-replaced-by-crlf-in-git-what-is-that-and-is-it-important




















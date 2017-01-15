---
layout: post
title:  "The github encoding"
date: 2015-05-25
categories: version control github windows linux
---
## The Problem
Currently I have a Windows based host that runs linux based vagrant VMs to test puppet modules I write.  
Recently after checking out the project from git and firing up the VM for my tomcat module on a newly formatted Windows host, one of the shell scripts failed to run. 

`bad interpreter: No such file or directory`

Both operating systems use different methods for the end of a line: 
* Windows uses Carriage Return (CR) + Line Feed (LF) 
* Linux uses a single Line Feed (LF).  

Quickly running the [dos2unix][dos2unix] app on the files or saving them with Notepad++ via `edit` > `EOL Conversion` > `UNIX  Format` will fix this.

Rerunning the bash script shows the problem is solved.

Unfortunately this will continue happen again on check out to another windows machine.

## The Cause
The scenario I was seeing was that I would have:  
Linux bash file on VM (`LF`) -> Commit on Windows Host -> github converts (`LF`)    

A linux script is created in a linux VM, the file is committed to github via the Windows host this results in a file that is converted into the LF line ending.  
The file will continue to work on this machine as the file ending on the local filesystem is still in LF, provided I don't save it via the host.  

Then on checkout on a new Windows host I would have:  
Linux bash file running on VM <- Git Clone on Windows Host (`CRLF`) <- github stored (`LF`)    

The script file with LF line endings is checked out and converted into CRLF on the Windows host by git and run on the linux VM, this will fail due to the conversion to CRLF on checkout.

When installing git on Windows you are provided with a dialogue box for choosing your line endings:

![Git providing the choice of line endings](/assets/GitLineEndingsChoice.png)

I had chosen, before I started playing around with Linux VMs and puppet, the **Checkout Windows-style, commit Unix-style line endings** option. This means that my linux scripts would always be converted on a Windows machine to CRLF line endings.

The other two options are of interest:

**Checkout as-is, commit Unix-style line endings** means that my scripts would work if committed with LF line endings but then none of my Windows formatted files would have the correct line endings as on commit then would be turns into unix-style line endings.

The final option **Checkout as-is, commit as is** isn't much better, whilst my scripts would work and my puppet manifests would work, they would only work for the machine architecture that I commit them; none of my Windows formatted puppet manifests will work on Linux and vice versa for those written on a Linux machine.

## The Solution
Okay so the git installer gave us some options but because of the mix of architectures being used (Windows host, Linux guest) we need a solution that works per project and doesn't break for OS level changes.

Enter [EditorConfig][editorconfig] a widely supported plugin for most Integrated Development Environments (IDEs), it provides the ability to set line endings, tab spacing, charset and other cross platform formatting quirks per file extension. 
```
[*.sh]
end_of_line = lf
```
So now I can set my git client line ending property to be what works best on my Windows host (Checkout Windows-style, commit Unix-style line endings) and have EditorConfig handle my bash script line endings ensuring I don't run into or waste time on the scripts not running.

[dos2unix]:			http://dos2unix.sourceforge.net/
[editorconfig]:		http://editorconfig.org/





















---
layout: post
title:  "The Upstart"
date: 2017-05-10
categories: Ubuntu Upstart
---

https://hazan.me/control-jekyll-as-a-service/

Startup is a mechanism on Ubuntu for handling services that can be triggered by various events, these are known as *jobs*.  

Your job will need to live in `/etc/init` and takes the form `jobname.conf`, this file is then referenced as *jobname* and does not need to be executable.  

Notes on format:
* `#` denotes a full line comment
* Spaces and tabs, unless in single or double quotes are treated as whitespace and ignored
* Newlines are allowed within quotes or if preceeded by a backslash `\`
* `$` and quotes will be passed to the shell for interpretation

All jobs need either an [exec](#exec) or a [script](#script) stanza.  
You can specify preconditions and postconditions known as [pre-start and post-stop](#pre-start-post-stop).

<a name="exec"></a>
## exec
With the exec call you provide it a path to an executable binary on the filesystem.  
You can include any options you wish to pass to it, any quoted or variable ($) special characters will result in the shell being passed the command for execution.  
```
exec 
```

<a name="script"></a>
## script
```
script

end script
```

<a name="pre-start-post-stop></a>
## pre-start and post-stop conditions

## Job Control
`start jobname`
`stop jobname`
`status jobname`

## Errors
`Name "com.ubuntu.Upstart" does not exist` results when you run upstart without `sudo`.  


[]:	
[]:	
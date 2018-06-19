---
layout: post
title:  "The Augtool"
date: 2017-03-12
categories: augeas augtool linux
---
![augeas logo](/assets/augeas-logo.png){: .padded-fixed-width-image }

In a previous post on [augeas in puppet](/augeas/puppet/linux/2016/07/14/augeas.html) I mentioned I'd be writing another post on debugging with the command line augeas tool since the puppet augeas provider doesn't provide the clearest way of debugging. 
Puppet with augeas requires the `--debug` flag to be set for it to print out the statements it is running via augeas but by the time you've got an error in your manifest run, the issue might not be replicable; such as a malformed insertion resulting in an *onlyif* check failing and allowing other statements to run.  
Using the command line tooling will enable you to get your syntax correct without flushing the changes to disk (the `save` command) or having to run your puppet manifest every time you try to construct a `match` query for example, it makes for a much quicker process.

## Augtool
Augtool is the command line Augeas tool, it is useful for prototyping changes before you run puppet (as provisioning a whole system can take time).  
It is installed via apt-get: `sudo apt-get install augeas-tools`.  
Lenses are used to allow Augeas to read and manipulate file formats such as .xml, .conf etc. they are stored in either `/usr/share/augeas/lenses/` or `/usr/local/share/augeas/lenses`.  

Starting the tool:  
`augtool --noload --noautoload --echo` will start the augeas command line tool.  

Install the lens to use:  
`set /augeas/load/xml/lens/ "Xml.lns"`  

Add the file you wish to parse (adds this file to the existing list of files):  
`set /augeas/load/xml/incl/ "/filepath.xml"`  

Load these settings:  
`load`


Now you're ready to query your file contents:  
`augtool print /files/<filepath>` will print the augeas representation of the file to standard out, this is very useful for debugging and knowing how to reference parts of a file.  
`augtool print /files/<filepath> > some.txt` will capture the output into a file.  

Augtool (and the augeas resource by proxy) has a number of **operations** you can perform on a file:
* `set path/in/file value` set a value for the specified entry
* `set path/in/file[last()+1] value` will create a new entry after the last in the list of  entries with a new value.
* `rm path/in/file` will remove the entry
* `clear path/in/file` will remove any sub entries or attributes from the entry, best used before remove a bit like doing `rm dir/*` before `rmdir dir`
Note these operations can have different value syntax based on the lens used.
* `ins`
* `match /files/etc/httpd/conf/httpd.conf/directive[. = 'LoadModule']/arg[. = 'headers_module'] size == 0`

Flush your changes to disk:  
`save`  
### <a name="debug"></a>Debugging with Augtool
`print /augeas//error` will print off the errors tha augeas has encountered.  
`ls /files/<path>` can be used like ls in linux to query what augeas can see, also brings auto-tab completion.  

The following:
```
/augeas/files/var/lib/jenkins/config.xml/error = "mk_augtemp"
/augeas/files/var/lib/jenkins/config.xml/error/message = "Permission denied"
```
Is encountered when augeas doesn't have permission to modify a file, run the tool with admin permissions (e.g. `sudo` or `su`).  

## Conclusion
Sensible use of Augeas should prevent overly large and verbose `.erb` templates from becoming common place in your puppet code. The main thing hindering more widespread use of augeas is the rather sparse documentation, especially when it comes to the lenses, instead you tend to have to rely on loading up Augtool with the lens and a process of trial and error to see how the file gets parsed and modified.

[augeas]:	http://augeas.net
[lenses]:	http://augeas.net/stock_lenses.html   
---
layout: post
title:  "The Augtool"
date: 2017-03-12
categories: augeas augtool linux
---
![augeas logo](/assets/augeas-logo.png){: .padded-fixed-width-image }

In a previous post on [augeas in puppet](/augeas/puppet/linux/2016/07/14/augeas.html) I mentioned I'd be writing another post on debugging with the command line augeas tool since the puppet augeas provider doesn't provide the clearest way of debugging. 
Puppet with augeas requires the `--debug` flag to be set for it to print out the statements it is running via augeas but by the time you've got an error in your manifest run, the issue might not be replicable; such as a malformed insertion meaning an onlyif check failing and allowing other statements to run.  
Using the command line tooling will enable you to get your syntax correct without flushing the changes to disk (`save`) or having to run your puppet manifest every time you try to construct a `match` query for example, it makes for a much quicker process.

## Augtool
Augtool is the command line Augeas tool, it is useful for prototyping changes before you run puppet (as provisioning a whole system can take time).  
Install via apt-get `sudo apt-get install augeas-tools`.  
Lenses are stored in either `/usr/share/augeas/lenses/` or `/usr/local/share/augeas/lenses`  

Starting the tool:  
`augtool --noload --noautoload --echo` will start the augeas command line tool.  
Install the lens to use:  
`set /augeas/load/xml/lens/ "Xml.lns"`
Add the file you wish to parse (adds this file to the existing list of files):  
`set /augeas/load/xml/incl/ "/filepath.xml"`  
Load these settings:  
`load`


Print the output from your query:  
`augtool print /files/<filepath>` will print the augeas representation of the file to standard out, this is very useful for debugging and knowing how to reference parts of a file.  
`augtool print /files/<filepath> > some.txt` will capture the output into a file.  

Augtool (and the augeas resource by proxy) has a number of **operations** you can perform on a file:
* `set <path> <value> ` set a value
Note these operations can have different <value> syntax based on the lens used.
XML operations:
* `set <path>#attribute/<name> =  "<value>"` will set the attribute for the designated tag  
* `set <path>#text = "<value>"` will set the text value for the designated tag.  

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
Is encountered when augeas doesn't have permission to modify a file.  

## Conclusion
Sensible use of Augeas should prevent overly large and verbose .erb templates from becoming common place in your puppet code. The main thing hindering more widespread use of augeas is the rather sparse documentation, especially when it comes to the lenses, instead you tend to have to rely on loading up Augtool with the lens and a process of trial and error to see how the file gets parsed and modified.

[augeas]:	http://augeas.net
[debug]:	#debug
[changes]:	#changes
[lenses]:	http://augeas.net/stock_lenses.html   
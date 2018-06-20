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
* `rm path/in/file` will remove the entry
* `clear path/in/file` will remove any sub entries or attributes from the entry, best used before remove a bit like doing `rm dir/*` before `rmdir dir`
Note these operations can have different value syntax based on the lens used.
* `ins path/in/file value` will create an entirely new entry, a bit like `set` but will fail if an entry already exists, whereas set will overwrite
* `match path/in/file/arg size == 0` can be used for conditional execution (using puppet's `onlyif`) in this example we are checking if the arguments of the file leaf are of size 0.

When performing any of the operations above you can also use a rich assortment of [path expressions][expressions]:
* `set path/in/file[last()+1] value` the built in function last() can be used within square brackets to handle positional path manipulation in this example to insert a new entry after the last one. 
* `path/in/file[. = 'value']` will match on a path where the current entry (denoted by the period) matches the specified string.
* `path/in[file = 'value']` is equivalent to the above example except we're matching from the perspective of the `in` node and examining if the child `file` matches with the `value`
* `and` and `or` can be used to match multiple predicates 
* Ordering of predicate evaluation is important `/files/etc/services/service-name[port = '22'][last()]` will find the last service with a port of 22 whereas `/files/etc/services/service-name[last()][port = '22']` will match if the last service out of **all** services has a port of 22. 
* There are many more to play around with as detailed in [path expressions][expressions] such as **self**, **child**, **parent**.

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
[expressions]: https://github.com/hercules-team/augeas/wiki/Path-expressions
---
layout: post
title:  "debconf and Puppet"
date: 2016-07-14
categories: debconf puppet linux debian
---

One of the issues that I have with puppet templates for managing configuration files is that they are fairly rigid in their layout and don't handle conditional structuring very well. For example if I have a tomcat `tomcat-users.xml` file that can specify a console/script user and a gui user for tomcat's manager application then I would need to include placeholders in the form `<%= @tomcat_manager_username %>` for each value I need.  

Now what if I only need these values when a module specifies them? In production I might only want a script user and in development I want a script **and** a GUI user? I'd have to wrap each value in Ruby style conditionals:

```
<% if @tomcat_manager_username != nil && @tomcat_manager_password != nil && @tomcat_manager_username != "" && @tomcat_manager_password != "" %>	
	<user username="<%= @tomcat_manager_username %>" password="<%= @tomcat_manager_password %>" roles="manager-gui"/>
<% end %>
```

So far so good, well so verbose and a bit boiler plate heavy.  

This works for files that I have complete control over, yet there are other applications that use configuration files that I cannot say I have absolute control over. The file might have changes required after those made by my module, such as enabling an apache plugin or changes made by other puppet modules. A good example would be changes made to the PHP configuration by a Kanboard module to allow it to run or adding a virtual host to Apache in one puppet manifest and adding the headers module in another. There is no way I can predict these file changes in the main puppet module. So what can be done?  

Enter Augeas...  

## Augeas
[Augeas][augeas] is a tool to replace parts of a configuration file without creating an inflexible erb template or needing to know the contents of the entire file. This allows a PHP module for example to declare a `php.ini` file and for another module to search and modify or add to the file later on as it sees fit.  
This is a first class citizen in puppet's resource structure.  
Augeas treats files as trees of values, a bit like xpath.  
A typical puppet declaration of the augeas resource looks like this:  
```
augeas{ "configure-jekins-login":
  incl => "/var/lib/jenkins/config.xml",
  lens => "Xml.lns",
  context => "/files/var/lib/jenkins/config.xml/hudson",
  changes => $jenkins_changes,
}
```
It should be noted that when using Augeas with puppet in most cases it will tend to fail silently, see [Debugging with Augtool][debug].  
Another gotcha is that it will make these same changes everytime puppet is run so using an `onlyif => ` clause is advisable.  
Luckily the onlyif can also make use of augeas [changes][changes], e.g. `match dir[/ = '/foo'] size == 0` or **even better** you can make use of the `context` argument to ensure you don't create duplicates, as per the example above where the `hudson` prefix is being used in the context field to ensure the change we want to make is fully qualified.
  
### incl
This property is used to inform augeas of the location of the file it is making changes to.  

### lens
A lens is used by augeas to parse a particular file type.  
A list of stock lenses can found [here][lenses]  
Lenses that I have confirmed to work with puppet in my experience so far are:
* `Xml.lns` is used by xml files
* `Php.lns` is used by php files
* `Httpd.lns` is used by apache httpd config file

### Context
In order to identify the `context` element for the property you want to change you should use the `augeastool`, run this with the `print` command on the file you wish to view.
This will provide you with a list of `paths` and their `values` as seen by augeas.  

The prefix of */files/* is required to be appended to the absolute location of the file you wish to view or operate on. I do not know if there is any other sort of context that can be used with augeas.

### <a name="changes"></a>Changes
These are very similar to the syntax used by the augtool command line program.  
A useful tip is to make use of an array to make multiple declarations of changes or use a hiera array.  
**List of change operations should go here**
[tour of augeas](http://augeas.net/tour.html)
* set
* rm
* ls
* match
* get
* erm what else?

#### Notes on quotes in the changes string
Handling quotations within the changes string is difficult as it involves both escaping with a backslash and wrapping the text in the alternate quotation, e.g. single quotes (') when trying to represent double quotes and double quotes (") when trying to use single quotes:  
* `"set attribute value"` will result in `attribute value` in the file
* `"set attribute \"'value'\""` will result in `attribute 'value'` in the file
* `"set attribute '\"value\"'"` will result in `attribute "value"` in the file

## Augtool
Augtool is the command line Augeas tool, it is useful for prototyping changes before you run puppet (as provisioning a whole system can take time).  
Install via apt-get `sudo apt-get install augeas-tools`.  
Lenses are stored in either `/usr/share/augeas/lenses/` or `/usr/local/share/augeas/lenses`  

Start the tool:  
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





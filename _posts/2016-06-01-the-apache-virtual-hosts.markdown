---
layout: post
title:  "Virtual hosts on Apache"
date: 2016-06-01
categories: linux apache virtual_hosts
---
I have setup an apache server to serve static resources for various domains and sub-domains.  
So that I don't need to create separate apache servers for each one I decided to make use of **VirtualHosts**.  

This is done using the configuration file found at `/etc/apache2/sites-enabled/example1-com.conf`

	<VirtualHost incomingAddress:incomingPort>
		DocumentRoot "/var/www/pathToSite"
		ServerName domainname
		ServerAlias otherdomainname, anotherdomainname
	</VirtualHost>

* **incomingAddress** can be a wildcard \* or a specific ip address that the request is inbound on.  
* **incomingPort** can be a wildcard or a specific port number that the request is inbound on.  
* **DocumentRoot** this is the location on the apache file system of the site you which to serve.  
* **ServerName** this is the domain name associated with the site you wish to serve.  
* **ServerAlias** this is a list of domains that are also going to be aliased to this ServerName separated by spaces. There can be multiple ServerAlias entries on separate lines too. **Remember** that `www.domainname` and `domainname` are not the same and you may need the www. entry as an alias.  

Each site requires an **index.html** to serve up as the index of the site.  
In this way I have been able to setup multiple placeholder sites for multiple domains.  





















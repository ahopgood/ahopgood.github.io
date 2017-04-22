---
layout: post
title:  "The x-clacks"
date: 2015-12-17
categories: apache linux terry_pratchett
---

<img src="/assets/TerryPratchett.jpg" alt="Terry Pratchett Image" width="400">

### Terry Pratchett
[Terry Pratchett][Terry Pratchett] was the author of the highly successful [Discworld][Discworld] series of books; set in a flat disc shaped world propped on the shoulders of four elephants who are flying through space standing on the back of a giant turtle.
These funny, insightful and cleverly written books parody real life situations, institutions and society with a fantastical backdrop of trolls, wizards, dwarves, politicians and many other minorities.

It was a testament to Terry Pratchett's popularity that when he died on the 12th of March 2015 that technically minded fans sought to create a fitting tribute to him that would both honour him and tie in with the rich fictional world he had created that held up a mirror to our own.

### John Dearheart & GNU
In one of his later books *[Going Postal][Going Postal]* the **clacks** were introduced, these devices were towers spaced apart that would flash messages between each other above the fields and cities with different patterns relating to different words. This replaced the more traditional method of sending letters by hand/horseman.
In essence a cross between the old telegraph systems with their many relay points to pass messages from one location to another and semaphore flags which communicate in a code that could be translated at a distance based on height, colour and sequence of flags.
In this he was foreshadowing the internet that we all use today.

In Going Postal when John Dearheart son of the clacks inventor Robert Dearheart is killed, the operators of each clacks tower did the following:

> His name, however, continues to be sent in the so-called Overhead of the clacks.   
> The full message is "GNU John Dearheart", where the G means, that the message should be passed on, the N means "Not Logged" and the U that it should be turned around at the end of the line.   
> So as the name "John Dearheart" keeps going up and down the line, this tradition applies a kind of immortality as "a man is not dead while his name is still spoken".

This use of the term [GNU][GNU] is a play on the recursive acronym *GNU's Not Unix* project used by the technical community for releasing open source software in the form of the [GNU operating system][GNU OS] and widely used GNU tools ([wget][wget], [bash][bash], [grep][grep]) that is free for use by anyone and gives it's name to the license that is distributed with software to ensure it continues to be free for use.

### The Tribute
In tribute the technical community is honouring Terry Pratchett by implementing a similar idea to the John Dearheart clacks message.
By adding a new header to web servers called the [X-Clacks-Overhead][x-clacks-overhead] you can forward Terry Pratchett's name in http headers and symbolically keep it moving around the internet like John Dearheart's.

For the Apache web server set-up it is recommended to add the following to your `[.htaccess][.htaccess]` file and enable the headers module:  
```
<IfModule headers_module>
  	header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
```

### Why you shouldn't use .htaccess
By default as of Apache 2.3.9 the `AllowOverride` directive that allows for processing of .htaccess files is set to `None` so .htaccess values won't be processed, this is because there are a few [good reasons][dontusehtaccess] not to set values in .htaccess files and instead should set such values in the main config file.  

When using .htaccess files apache has to look in both the directories below **and** above in the hierarchy for other .htaccess files to correctly assess the permissions and overrides collectively implemented by various .htaccess files on a site and this is computationally expensive.

Further to this there are the ongoing security and maintenance issues with having values set in various locations by the users of the sites outside of the control of the central configuration file which as a system administrator you need to decide if you're comfortable with.

We have access to the main `apache2.conf/httpd.conf` file so should use this instead to add our new `X-Clacks-Overhead` directive to either an applicable `Directory` or `VirtualHost` block, an example of adding it to a Directory configuration block is given below:
```
<Directory "/var/www/html/">
	<IfModule headers_module>
		header set X-Clacks-Overhead "GNU Terry Pratchett"
	</IfModule>
</Directory>
```

I've included this tribute in the apache server that hosts my personal CV and you can see in the image below that the response headers have our X-Clacks-Overhead
<img src="/assets/X-Clacks-Overhead-in-action.png" alt="The X-Clacks-Overhead in action">

It might not be much but it is a small nod from a fan such as myself to an author who brightened up my adolescence and continued to make me laugh as an adult.

[Terry Pratchett]:	https://en.wikipedia.org/wiki/Terry_Pratchett
[Discworld]:		https://www.terrypratchettbooks.com/discworld-reading-order/
[Going Postal]:		https://en.wikipedia.org/wiki/Going_Postal
[GNU]:				https://en.wikipedia.org/wiki/GNU_Project
[GNU OS]:			https://www.gnu.org/home.en.html
[wget]:				https://www.gnu.org/software/wget/
[bash]:				https://en.wikipedia.org/wiki/Bash_(Unix_shell)
[grep]:				https://en.wikipedia.org/wiki/Grep
[x-clacks-overhead]:https://www.gnuterrypratchett.com/
[.htaccess]:		https://www.gnuterrypratchett.com/#apache
[dontusehtaccess]:	https://httpd.apache.org/docs/current/howto/htaccess.html#when
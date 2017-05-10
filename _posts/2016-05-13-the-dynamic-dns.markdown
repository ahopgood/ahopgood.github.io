---
layout: post
title:  "Multiple dynamic DNS entries on namecheap"
date: 2016-05-13
categories: dns linux dynamic_dns raspberry_pi namecheap 
---
I've been playing with a few domains lately using [namecheap](#namecheap).  
Namcheap provide their own dynamic DNS service, in their **advanced** section for your domain, you can select to enable the dynamic DNS service in there.
![Advanced Namecheap Settings](/assets/Namcheap_DNS_Advanced.png)
For each domain prefix or subdomain you need to add an **A+ dynamic** record in the dynamic DNS configuration section at the bottom of the page.  
![Enabling Namecheap Dynamic DNS](/assets/Namcheap_Enable_DynamicDNS.png)
For now you just need to enter an obviously dummy address (e.g. 127.0.0.1) as once configured the dynamic DNS service will replace this with the IP address from where you are running the dynamic DNS client from.  
Make a note of the **Dynamic DNS password**, you need this for your client to authenticate with the namecheap servers.
Next you will need to setup your dynamic DNS client to allow your IP address to be assigned to your domain even when your Internet Service Provider (ISP) decides to assign you a new one every few weeks.  

## ddclient
I made use of [ddclient](#ddclient) on linux, it is available in x86, x86_64 and ARM binaries making it very versatile, in my case I've chosen the ARM version as a **.deb** file for my Raspberry Pi running Raspberian as an OS.  
The configuration format for **/etc/ddclient.conf** takes the following form:

	protocol=namecheap
	use=web, web=dynamicdns.park-your-domain.com/getip
	ssl=yes
	server=dynamicdns.park-your-domain.com
	login=<yourdomain.com>, password='<yourpassword>' \
	@.<yourdomain.com>, www.<yourdomain.com>
	
Your **login** will be the fully qualified domain name of the domain you are registering.  
Your **password** is the dynamic DNS password you saved earlier from the namecheap web interface.  
After the login and password you list the possible prefixes and subdomains that you want to be updated via dynamic dns(e.g. www.<yourdomain.com>, @.<yourdomain.com> subdomain.<yourdomain.com>).  
You don't want your login and password to be sent as plaintext because then someone could usurp your domains, setting `ssl=yes` will ensure that the credentials are sent via an encrypted channel.

It should be noted that your login and password are different for every **high level domain** that you have so you'll need to add configuration for each one to **/etc/ddclient.conf**.  
I set up my eight domains and created a series of **VirtualHost** entries in Apache server to serve up some static content for each domain.  

It turns out that only **version 3.8.3** or higher of ddclient can deal with multiple domain-api key setups for the namecheap dynamic DNS service, prior to this ddclient would only register the first domain configuration that it encountered in the config file before bailing out.  
This resulted in only the first of my registered domains working as expected, the rest just failed silently, it took me a while to find the information that pointed to the 3.8.3 version having fixed this for the namecheap service.   
Obtaining version 3.8.3 can be difficult, making use of the [pkgs.org][pkgs.org] website helped me track down the correct binaries.

[ddclient]:		https://sourceforge.net/projects/ddclient/
[namecheap]:	https://www.namecheap.com
[pkgs.org]:		https://pkgs.org/






















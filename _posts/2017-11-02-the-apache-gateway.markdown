---
layout: post
title:  "Setting up Apache as a local gateway"
date: 2017-11-02
categories: Apache Gateway
---

## The issue
I have a few virtual machines on a local server at home that provide a few services, they are all on my local network but I'm not quite ready to set up my own [BIND][BIND] server to provide Domain Name System (DNS) lookup as I feel that is probably a bit heavy handed for now.  
This still leaves me with a bunch of servers/services which can only be referenced by IP address and port combos which are hard to remember, especially since they can change from time to time.  
My initial hacky solution to this was to maintain a `/etc/hosts` file mapping host names to specific IP addresses but this had a few downsides:
1. Ports cannot be mapped in a hosts file, many of my services operate on ports that aren't limited to `80` so this forward would be incomplete
2. This would work only for the machine I work on, not for others without passing around and updating the hosts file continuously, this wouldn't scale
3. Mapping multiple domains to a single service requires multiple entries (e.g. `myservice.mydomain.com` and `myservice.mydomain.co.uk`
4. If at any point in the future I wanted to make these services publicly accessible on one of my own domains this whole solution would need to be thrown out and another implemented.

My solution is to run an apache instance (one which I already have running anyway) with some virtual host entries acting as gateways to my services.

## The Apache Reverse Proxy / Gateway

Below is an example of virtual host entry (in `/etc/apache/sites-available/www.myservice.mydomain.com.conf`) that will act as a gateway for your specified domain name to a particular server (192.168.0.5) and port (8080).

```
<VirtualHost *:80>
        <IfModule proxy_module>
                ProxyPreserveHost On
                ProxyPass "/" "http://192.168.0.5:8080/"
                ProxyPassReverse "/" "http://192.168.0.5:8080/"
        </IfModule>
        ServerName www.myservice.mydomain.com
</VirtualHost>

```
The `ProxyPreserveHost On` will ensure that the hostname we use will be passed to the service (see [ProxyPreserveHost][proxypreservehost].  
The `ProxyPass` directive will handle mapping of incoming requests to the destination server: `public.com/foo` becomes `backend.com/foo` (see [ProxyPass][proxypass]).
The `ProxyPassReverse` directive handles mapping of response requests from the destination server back to the origin server, `backend.com/bar` becomes `public.com/bar` (see [ProxyPassReverse][proxypassreverse]).  
Note it will require the `proxy_module` and the `proxy_http_module` to be installed as modules in apache for this to work.  

## Restricting Access
We use the [location][location] directive to place restrictions on access to the root of this virtualhost ("/"), we could be more specific but since our ProxyPass and ProxyPassReverse are operating on the root also this should match up:
```
<IfModule proxy_module>
	...
	<Location "/">
		Require ip 192.168.0.0/24
	</Location>
</IfModule>
``` 
This will restrict the gateway to only work when the **origin** IP address is from within the address range `192.168.0.0 - 192.168.0.255` on my local network.   
I am able to use a range like this thanks to the use of a subnet mask in Classless Inter-Domain Routing format (see [CIDR][CIDR]), this is the `/24` at the end which indicates that the subnet mask will apply to the first 24 bits of the IP address (in other words a mask of 255.255.255.0), each block of 8-bits in binary is represented by the range 0-255 in decimal and an IP address consists of four of these 8-bit blocks `x.x.x.x`. 
So now I have restricted access to only the machines on my local network who are on the `192.168.0.x` subnet.  

## Local host resolution

I will then create entries in the `C:\Windows\System32\drivers\etc\hosts` file on my machine to resolve domain names to the apache server running the virtualhosts:
```
	192.168.0.2		service1.mydomain.com
	192.168.0.2		service2.mydomain.com
	192.168.0.2		service3.mydomain.com
	192.168.0.2		service4.mydomain.com
```
In this way my local machine will resolve the service names to the apache server which will capture the request and forward it to my service's `IP:port` pair.
 
## The future
This solution whilst a bit hacky does solve some of my key issues:
1. I can use domain names (of a sort) to reference my services, these can now be bookmarked since underlying IP address changes won't impact the resolution provided the virtualhost entry is updated
2. I am able to map services that run on non-standard ports
3. I have a single source to change if a service IP address changes instead of in multiple places
4. I do not need any extra resources to run this since I already have apache running
5. I can restrict the gateway to only work on machines already in my local network
6. The current solution does not rely on external DNS so an ISP outage will still result in lookup working on the local network.

There are still some issues this solution presents:
1. If my apache instance changes IP address I'll need to update my hosts file
2. I still need a hosts file for each machine and will need to update it if I introduce new services/domain names
3. This solution only works on my local network

These issues not withstanding the solution is extensible enough that should I in future implement a BIND server or add the services to my registered domains I can do so without having to throw much away:
1. If I want to use DNS (via one of my registered domains) instead of the hosts file I can remove the hosts file, add an A record to the subdomain and a ddclient entry on the apache server to update the A record. No change is required for the virtualhost entry whilst still blocking IP addresses that aren't from my local network. 
2.  If I want to open a service up to the wider world I can follow the steps above to use DNS and then remove the `Require ip` block from the virtualhost entry. 

[BIND]: https://en.wikipedia.org/wiki/BIND
[proxypreservehost]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypreservehost
[proxypass]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypass
[proxypassreverse]: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypassreverse
[location]:	https://httpd.apache.org/docs/2.4/mod/core.html#location
[CIDR]: https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

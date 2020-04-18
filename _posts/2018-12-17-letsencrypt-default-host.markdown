---
layout: post
title:  "LetsEncrypt and the default Apache Host"
date: 2018-12-17
categories: LetsEncrypt Apache SSL
---

I've recently been exploring the excellent [LetsEncrypt][LetsEncrypt] project for generating TLS/HTTPS certificates for my sites.  
Whilst using the `certbot --test-cert` parameter with a test domain `test.alexanderhopgood.com` I noticed that other sites hosted on the same Apache instance would redirect to this domain if I used **https://**.  
It is nice that it tried to redirect to a secure connection but the fact is it is for a **completely different site!**.  


![Example site with another site's certificate](/assets/2019-12-17-incorrect-certificate.png)

A look on the LetsEncrypt forums for configuration issues suggested the following command:  
`sudo apache2ctl -S`  

Jumping into the command line help show the following brief explanation:  
>   -t -D DUMP_VHOSTS  : show parsed vhost settings  
  -t -D DUMP_RUN_CFG : show parsed run settings  
  -S                 : a synonym for -t -D DUMP_VHOSTS -D DUMP_RUN_CFG  


This provided the following (abbreviated) output:
```
$ sudo apache2ctl -S
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
VirtualHost configuration:
*:443                  is a NameVirtualHost
         default server test.alexanderhopgood.com (/etc/apache2/sites-enabled/test.alexanderhopgood.com-le-ssl.conf:3)
         port 443 namevhost test.alexanderhopgood.com (/etc/apache2/sites-enabled/test.alexanderhopgood.com-le-ssl.conf:3)
...
*:80                   is a NameVirtualHost
         default server 127.0.1.1 (/etc/apache2/sites-enabled/000-default.conf:1)
         port 80 namevhost 127.0.1.1 (/etc/apache2/sites-enabled/000-default.conf:1)
         port 80 namevhost test.alexanderhopgood.com (/etc/apache2/sites-enabled/test.alexanderhopgood.com.conf:2)
...
ServerRoot: "/etc/apache2"
Main DocumentRoot: "/var/www/html"
Main ErrorLog: "/var/log/apache2/error.log"
Mutex watchdog-callback: using_defaults
Mutex rewrite-map: using_defaults
Mutex ssl-stapling-refresh: using_defaults
Mutex ssl-stapling: using_defaults
Mutex proxy: using_defaults
Mutex ssl-cache: using_defaults
Mutex default: dir="/var/run/apache2/" mechanism=default
PidFile: "/var/run/apache2/apache2.pid"
Define: DUMP_VHOSTS
Define: DUMP_RUN_CFG
User: name="www-data" id=33
Group: name="www-data" id=33
```

The most interesting part of this output was the difference between the _default server_ entries for port _443_ (HTTPS) and port _80_ (HTTP).  

The alphabetical naming of the VirtualHost files that listen on `port 443` dictates which configuration file is used as a _default_.  

As I hadn't set up the HTTPS VirtualHosts for the other sites on my server yet they were **defaulting** to the test domain and serving the test domain certificate.  

Due to the fact `mod_ssl` automatically handles any request that Apache deems to be secure (in this case port 443) it looks for valid certificates for the domains before further processing.

This means you would need to be able to provide some sort of certificate before being able to do any sort of redirection _regardless of the domain_.  

Hence it isn't possible to set up a default ssl configuration to capture HTTPS requests and redirect them _back to HTTP_ without capturing **all** HTTPS requests.

The **temporary** solution I've come up with is to setup a redirect within my test domain whereby if it _doesn't_ match the domain then the request is rewritten to use _HTTP_.

```
RewriteEngine on
RewriteCond %{SERVER_NAME} !=test.alexanderhopgood.com
RewriteRule ^ http://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
```

Your users will still initially be warned by your browser that the certificate doesn't match the domain but you will then be redirected to the standard HTTP VirtualHost.

In this way it won't interfere with any new certificates I roll out mainly due to my naming policy being `www.subdomain.domain` resulting in `test.domain` becoming the default if a domain does **not** match.

The end solution obviously is to roll out SSL to **all** by sites and sub-domains.

[LetsEncrypt]: https://letsencrypt.org/

---
layout: post
title:  "Upgrading to Let's Encrypt Version 2"
date: 2020-03-23
categories: letsencrypt
---

### The Problem
Some time ago I received an email from [Let's Encrypt](https://letsencrypt.org/) on the email address I had used to register my [certbot](https://certbot.eff.org/) client with.  

> According to our records, the software client you're using to get Let's
Encrypt TLS/SSL certificates issued or renewed at least one HTTPS certificate
in the past two weeks using the ACMEv1 protocol. Here are the details of one
recent ACMEv1 request from each of your account(s):
>
> Client IP address:  xxx.xxx.xxx.xxx  
>
> User agent:  CertbotACMEClient/0.23.0 (certbot; Ubuntu 18.04.3 LTS) Authenticator/webroot Installer/apache (run; flags: ) Py/3.6.8
>
> Hostname(s):  "www.subdomain.mydomain.com","subdomain.mydomain.com" ... "subdomain.mydomain.co.uk"
> 
> Request time:  2020-01-29 19:51:50 UTC  
> Beginning June 1, 2020, we will stop allowing new domains to validate using
the ACMEv1 protocol. You should upgrade to an ACMEv2 compatible client before
then, or certificate issuance will fail. For most people, simply upgrading to
the latest version of your existing client will suffice.

It turns out it was **not** as simple as I or the above email thought it would be...

### Debugging
Useful information when debugging your Let's Encrypt installation:
* Find your Let's Encryp log files at `/var/log/letsencrypt/letsencrypt.log`
* Using the timestamp from your warning email find the call corresponding to your renewal, verify it is indeed using the V1 API calls.


### Upgrading
For some reason it seems that my installation had become broken when I saw these messages in my log files:
> 2020-03-09 20:15:06,019:WARNING:certbot.renewal:expected /etc/letsencrypt/live/www.subdomain.mydomain.com/cert.pem to be a symlink  
> 
> 2020-03-09 20:15:06,019:WARNING:certbot.renewal:Renewal configuration file /etc/letsencrypt/renewal/www.subdomain.mydomain.com.conf is broken. Skipping.  

I ran `--reinstall` on my certbot instance against the legacy V1 API to reinstate my certificate symlinks and apache configuration files.

Now for the upgrade itself.
* `apt-get install --upgrade-only certbot` to upgrade your certbot installation
	* Then you can re-run your renewal or your installation depending on how close to your certificate expiry you are.
* As the production version of LetsEncrypt is rate limited you'll want to test it out on the staging environment first using the dry-run command:
	* `--dry-run -i apache -a webroot -d www.subdomain.mydomain.com -w /var/www/mysite/`

At this point you may see the following error in your logs:
> Link: <https://acme-staging-v02.api.letsencrypt.org/directory>;rel="index"
>
> b'{\n  "type": "urn:ietf:params:acme:error:malformed",\n  "detail": "Method not allowed",\n  "status": 405\n}'

* Run `apt-get install --upgrade-only python3-acme` to update the python3-acme package which solves the *Method not allowed** error you _may_ get on staging.

Now you should be able to rerun the dry-run successfully.  

`/etc/letsencrypt/accounts/` will have directories listing the accounts you've used, the API versions are in the names of these accounts, if you have `acme-v02.api.letsencrypt.org` then you've been successful.

### Summary
I had to upgrade more than just my certbot client:
* python3-acme was at `0.23.0-1`, upgraded to `0.31.0-2`
* certbot was at `0.23.0-1`, upgraded to `0.27.0-1`

Also it helps to verify that your installation for V1 is still working as expected too.  
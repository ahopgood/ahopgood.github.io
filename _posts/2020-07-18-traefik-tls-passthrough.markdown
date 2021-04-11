---
layout: post
title:  "Traefik and TLS Passthrough"
date: 2020-07-18
categories: traefik letsencrypt
---

I've recently started testing using [traefik](https://traefik.io/traefik/) as a reverse proxy, for me it has a couple of compelling features:
* Easy and dynamic discovery of services via docker labels
	* I don't need to update my base docker image to include and manage certbot when I add a new service, I just update a few docker labels on my service. 
* Support for [Let's Encrypt](https://letsencrypt.org/) to provide HTTPS/TLS
	* This removes the need to configure Let's Encrypt for service at the docker image level, instead the reverse proxy will manage, update and secure connections to your docker service
* Useful middlewares to provide functionality in front of my services
	* Basic Authentication
	* IP whitelisting
	* Rate Limiting
	* Load balancing
	* Many more
* Support for non-docker services (think VMs or bare metal hosts) via static configuration files 

### Why do I need a TLS passthrough?
Well, because learning is a journey of multiple stages and at the moment my infrastructure also reflects this.  
My plan is to use [docker][docker] for all my _future_ services to make the most of my limited hardware **but** I still have existing services that are Virtual Machines (also known as a VM or VMs).  
Using Traefik will relieve one VM of the responsibility of being a [reverse proxy/gateway][reverse-proxy] for other services, none-the-less these VMs still have significant responsibilities that will take time to decompose and integrate into my new docker ecosystem, until that time they still need to be accessible and **secure**.  

Traefik can provide [TLS][traefik-tls] for services it is reverse proxying on behalf of and it can do this with [Let's Encrypt][traefik-letsencrypt] too so you don't need to manage certificate issuing yourself.  
This is perfect for my new docker services:
* Traefik will grab a certificate from Let's Encrypt for the hostname/domain it is serving the docker service under, communications between the outside world and Traefik will be encrypted.
* The docker service will not be directly reachable from the internet; it will have to go through the TLS link to Traefik
* Communications between Traefik and the proxied docker service will all happen on the local docker network
* No ports need to be opened up on the physical server for the docker service

Now we get to the VM, Traefik will also be a proxy for this **but** the VM will handle the creation and issuing of certificates with Let's Encrypt itself.  
This means we **don't** want Traefik intercepting and instead letting the communications with the outside world (and Let's Encrypt) continue through to the VM.  

![Diagram of expected passthrough](/assets/diagram-traefik-tls-passthrough.svg "Test Title")

### How to do the passthrough
We need to set up routers and services.  
There are two [routers][traefik-routers]; one for TCP and another for HTTP:

#### TCP
The TCP router requires the use of a `HostSNI` (SNI - Server Name Indication) entry for matching our VM host and only TCP routers require it.  
The `tls` entry requires the `passthrough = true` entry to prevent Traefik trying to intercept and terminate TLS, see the [traefik-doc][traefik-tls-passthrough] for more information.     
<pre><code>
[tcp]
...
  [tcp.routers]
	[tcp.routers.secure-tcp]
	  rule = "HostSNI(`www.vm.mydomain.com`)"
	  service = "vm-secure"
	  entryPoints = ["secure","web"]
	  [tcp.routers.secure-tcp.tls]
        passthrough = true
</code></pre>

#### HTTP
The HTTP router is quite simple for the basic proxying but there is an important difference here.  
We need to add a **specific** router to match and allow the HTTP challenge from Let's Encrypt through to the VM otherwise Traefik will intercept these requests.  
Here we match on:
* The `Host` name
* The `Path` of `/.well-known/acme-challenge/` which is where Let's Encrypt will try to retrieve the challenge files from
* And the ``Method(`GET`)`` to ensure this rule will only apply to retrieval of the challenge files, there is no need to allow anyone external to modify these!
<pre><code>
[http]
... 
  [http.routers]  
    [http.routers.vm]
      rule = "Host(`www.vm.mydomain.com`)"
      service = "vm"
      entryPoints = ["web"]

    # Add the router for LetsEncrypt HTTP-01 challenge e.g. GET /.well-known/acme-challenge/yK1iwHnN-_RFgGed5cyyHfi2IjCx7Xbi-DeMaY8zoJw
    [http.routers.vm-acme-challenge]
      rule = "Host(`www.vm.mydomain.com`) && Path(`/.well-known/acme-challenge/`) && Method(`GET`)"
      service = "vm"
      entryPoints = ["web"]
</code></pre>

#### Services
We define two [Services][traefik-services] for the VM traffic that will be a TCP service (used by the TCP router) and a HTTP service (used by the standard http router and the Let's Encrypt HTTP challenge):
<pre></code>
[tcp]
...
  [tcp.services]
    [tcp.services.vm-secure.loadBalancer]
      [[tcp.services.vm-secure.loadBalancer.servers]]
          address = "192.168.x.x:4443"
</code></pre>


<pre><code>
[http]
...
    [http.services.vm]
      [http.services.vm.loadBalancer]
        [[http.services.apache-vm.loadBalancer.servers]]
          url = "http://192.169.x.x:8080"
</code></pre>

At this point we are now passing through **any** requests for our VM including at the TCP level, the HTTP level **and** the HTTP Challenge ones that Traefik would intercept by default.  
The VM is now able to use certbot/LetsEncrypt to manage its own certificates whilst having Traefik act as its reverse proxy!

[docker]: https://www.docker.com/
[reverse-proxy]: https://en.wikipedia.org/wiki/Reverse_proxy
[traefik-tls]: https://doc.traefik.io/traefik/https/tls/
[traefik-letsencrypt]: https://doc.traefik.io/traefik/https/acme/
[traefik-services]: https://doc.traefik.io/traefik/routing/services/
[traefik-routers]: https://doc.traefik.io/traefik/routing/routers/
[traefik-tls-passthrough]: https://doc.traefik.io/traefik/routing/routers/#passthrough
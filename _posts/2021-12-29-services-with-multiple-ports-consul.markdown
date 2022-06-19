---
layout: post
title:  "Services with Multiple Ports in Consul"
date: 2021-12-29
categories: consul traefik docker
---

### Why are services with multiple ports a problem?
Typically a consul service definition only allows a single port per definition.  
When Traefik reads service information from consul via the service's `tags` it will create a single router for this service.  

Some services use multiple ports to serve different content; such as an admin interface vs an anonymous interface. This poses a problem since consul and by extension Traefik will only recognise a single service and port.  

To make matters more complicated, Traefik provides automatic LetsEncrypt certificates _per router_ based on the router's `Host` rule.  
A `Host` rule consists of a full qualified domain, so if we allocate say port `80` for the anonymous service to the host `mymulti.port.service.com` then this host cannot be reused for another port.  


### How can this issue be managed?
Ubooquity is a good example of a service with a separate port for its admin interface:
* `2203` is the admin port
* `2022` is the anonymous port

What we can do is register the same service **twice** with consul, once for each port with a **different** `Host` entry for the Traefik routing.  
In this way we'll have a domain mapped to each port:
* `ubooquity.mydomain.com` -> `2202`
* `ubooquity.admin.mydomain.com` -> `2203`

#### Multiple Traefik routers
We can register the service twice in Traefik by creating **two routers** with different sub-domains:
* `ubooquity.mydomain.com`
* `ubooquity.admin.mydomain.com`

This will allow Traefik to register each router to a service:
* `"traefik.http.routers.ubooquity.service=ubooquity-secure"`
* `"traefik.http.routers.ubooquity-admin.service=ubooquity-admin-secure"`

Each of these services can then be mapped to their respective ports:
* `"traefik.http.services.ubooquity-secure.loadbalancer.server.port=2202"`
* `"traefik.http.services.ubooquity-admin-secure.loadbalancer.server.port=2203"`


#### Multiple Consul Service Definitions
We can support multiple ports in consul by defining **two service definitions** for Ubooquity.  
Each one will have a unique name and port mapping:  
* `"service": { "name": "ubooquity-secure", "port": 2202 }`
* `"service": { "name": "ubooquity-admin-secure", "port": 2203 }`

### Summary
Now we have two consul services mapped to separate domains and ports for the same Ubooquity service allowing each to be served separately without clashing.  

Another option could be to use `Path` matching in combination with the `Host` matching so both use the same domain.  
I'm unsure if this will work with both rules and services using the same LetsEncrypt resolver and also as the anonymous port (2202) will use the root of the domain `/` I don't think the path matching for `/admin` will resolve correctly.  

### Appendix - Full Service Definitions
#### ubooquity-admin Service Definition
**ubooquity-secure** service with port 2202 and host **ubooquity.mydomain.com**
```
{
    "service":
    {
        "name": "ubooquity-secure",
        "tags": [
            "app",
            "traefik.http.routers.ubooquity.entrypoints=web",
            "traefik.http.routers.ubooquity.rule=Host(`ubooquity.mydomain.com`)",
            "traefik.http.routers.ubooquity.middlewares=local-network@file,https-redirect@file",
            "traefik.http.routers.ubooquity.service=ubooquity-secure",
            "traefik.http.routers.ubooquity-secure.entrypoints=secure",
            "traefik.http.routers.ubooquity-secure.rule=Host(`ubooquity.mydomain.com`)",
            "traefik.http.routers.ubooquity-secure.middlewares=local-network@file",
            "traefik.http.routers.ubooquity-secure.tls=true",
            "traefik.http.routers.ubooquity-secure.tls.certresolver=myletsencryptresolver",
            "traefik.http.routers.ubooquity-secure.service=ubooquity-secure",
            "traefik.enable=true"
        ],
        "port": 2202,
        "address": "127.0.0.1",
        "check": {
            "id": "ubooquity-check",
            "name": "Is ubooquity accessible?",
            "http": "http://127.0.0.1:2202",
            "method": "GET",
            "interval": "10s",
            "timeout": "3s"
        }
    }
}


```
#### ubooquity-admin-secure Service Definition
**ubooquity-admin-secure** service with port 2203 and host **ubooquity.admin.mydomain.com**
```
{
    "service":
    {
        "name": "ubooquity-admin-secure",
        "tags": [
            "app",
            "traefik.http.routers.ubooquity-admin.entrypoints=web",
            "traefik.http.routers.ubooquity-admin.rule=Host(`ubooquity.admin.mydomain.com`)",
            "traefik.http.routers.ubooquity-admin.middlewares=local-network@file,https-redirect@file",
            "traefik.http.routers.ubooquity-admin.service=ubooquity-admin-secure",
            "traefik.http.routers.ubooquity-admin-secure.entrypoints=secure",
            "traefik.http.routers.ubooquity-admin-secure.rule=Host(`ubooquity.admin.mydomain.com`)",
            "traefik.http.routers.ubooquity-admin-secure.middlewares=local-network@file",
            "traefik.http.routers.ubooquity-admin-secure.tls=true",
            "traefik.http.routers.ubooquity-admin-secure.tls.certresolver=myletsencryptresolver",
            "traefik.http.routers.ubooquity-admin-secure.service=ubooquity-admin-secure",
            "traefik.enable=true"
        ],
        "port": 2203,
        "address": "127.0.0.1",
        "check": {
            "id": "ubooquity-admin-check",
            "name": "Is ubooquity-admin accessible?",
            "http": "http://127.0.0.1:2203/admin",
            "method": "GET",
            "interval": "10s",
            "timeout": "3s"
        }
    }
}

```

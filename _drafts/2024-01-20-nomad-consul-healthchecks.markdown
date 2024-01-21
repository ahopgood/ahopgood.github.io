---
layout: post
title:  "Consul healthchecks on Nomad"
date: 2024-01-20
categories: nomad consul consul-connect
---
When moving your services into Consul's Connect secured service mesh you'll need to ensure a few things are configured:
* Use the `expose = true` value in the check
  * Opens a new port specifically for the healthcheck
  * Doesn't need to be a named port
* Ensure that your service stanza has the `connect{ sidecard_service{} }` set up
* If using Traefik, ensure Traefik has connect properties set
   * `- "--providers.consulcatalog.connectAware=true"`
   * `- "--providers.consulcatalog.connectByDefault=false" # we want to declare consul services` as connect capable ourselves right now`
* Remove static port from task group's network
* Enable connect in nomad configuration

### Debugging your health checks
I've identified four steps to debugging health checks when using Nomad, Consul and Consul's Connect service mesh, starting with the most simple set up to the most complex to help eliminate points of failure:
1. Docker compose & curl
	1. This verifies that your expected health check works in the simplest of set ups
2. Nomad static port & curl with no Consul Connect
	1. Now with static port you ensure that Nomad's networking isn't at fault
3. Nomad, Consul Connect and no health check
	1. With no health check present but the Connect service mesh enabled you can verify that the container starts up correctly and is accessible via the mesh without the health check getting in the way.
4. Nomad, consul Connect, healthcheck & connect proxy
	1. Finally you should be able to put all the pieces together and the only thing you need to work on is the Connect service mesh settings.

#### Docker Compose & Curl
* Ensure you've mapped the correct internal docker port to an external port
* Use Curl to target the HTTP endpoint you'll be using as a health check
	* E.g. `curl -X GET -w "\n%{http_code}\n" -v --url 0.0.0.0:8083/login`
	* `-w "\n%{http_code}\n"` output the status code so you'll know if you encounter a `404` not found or `504` gateway timeout
	* `-v` means "verbose" mode so curl will print off all headers and statuses, useful for debugging if there's a redirect to a login page in place via a `Location` header

#### Nomad static port & curl with no Consul Connect
* Similar to our docker compose set up, make sure that Nomad is mapping to the correct internal port in the docker service
```
service {
	name = "${NOMAD_GROUP_NAME}"
	port = 8083
	...
}
```
* And use a static port in the network block to ensure the host port you're going to query is consistent between deployments/tests
```
network {
	port "http" {
		static = 8083
		to = 8083
	}
	...
}
```
* Use curl in the same way we did for the regular docker test (making sure you stopped that previous test or use a different port) to verify the health check endpoint works as we expect 
	* `curl -X GET -w "\n%{http_code}\n" -v --url 0.0.0.0:8083/login`
* Redeploy the service with a health check
```
check {
	method = "GET"
	type     = "http"
	interval = "10s"
	timeout  = "2s"
	path     = "/login"
	name = "${NOMAD_GROUP_NAME}-via-connect"
}
```
	* The health check values should mirror those we used for curl
	* Note that we don't need the IP address as Nomad & Consul's networking will find that for us
	* Same goes for specifying a port, the `check` will inhert the same internal port as the service 

#### Nomad, Consul Connect and no health check
* Add your service to Consul Connect with the following stanza:
```
service {
	...
	connect {
		sidecar_service {}
	}
}
```
* Next we remove/comment out the `check` stanza as we don't want it getting in the way of verifying that we can get our service into the Connect service mesh and communicate with it
* Use a connect proxy to forward a port to our service in the mesh
	* `consul connect proxy -service web -upstream <task-name>:9191`
	* `<task-name>` is the name in your `task` stanza in nomad
* Now you should be able to use curl on port 9191 to connect to your service
	* `curl -X GET -w "\n%{http_code}\n" -v --url 0.0.0.0:9191/login`

#### Nomad, consul Connect, healthcheck & connect proxy
* Enable the health `check` stanza
```
check {
	expose   = true
	method = "GET"
	type     = "http"
	interval = "10s"
	timeout  = "2s"
	path     = "/login"
	name = "${NOMAD_GROUP_NAME}-via-connect"
}
```
	* `expose = true` is important to ensure that your healthcheck is aware of Consul Connect
* Use a connect proxy to forward a port to our service in the mesh like our previous test
	* `consul connect proxy -service web -upstream <task-name>:9191`
* Now you should be able to use curl on port 9191 to connect to your service
	* `curl -X GET -w "\n%{http_code}\n" -v --url 0.0.0.0:9191/login`
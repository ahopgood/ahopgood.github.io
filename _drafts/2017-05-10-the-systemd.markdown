---
layout: post
title:  "The systemd"
date: 2017-05-10
categories: Ubuntu Upstart
---

https://www.linux.com/learn/understanding-and-using-systemd
https://wiki.debian.org/systemd#Managing_services_with_systemd
https://wiki.ubuntu.com/SystemdForUpstartUsers
https://unix.stackexchange.com/questions/47695/how-to-write-startup-script-for-systemd

https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files

Systemd is a mechanism on Ubuntu for handling services that can be triggered by various events, these are known as *units*.  

Your unit will need to live in `/usr/lib/systemd/system` and takes the form `unitname.service`, this file is then referenced as *systemcl unitname* and does not need to be executable.  

`/etc/systemd/system` maintains a list of symlinks for systemd services, your unit is installed/enabled via the call `systemctl enable unitname.service` which will result in the symlink being created in the right place.  

# Syntax
Sections within the unit file are denoted by a pair of square '[]' brackets.
A section name is contained within these brackets and nothing else, the name is case sensitive.  
The section continues until the next declaration.  
Entries in the unit file are `key=value` pairs.  
```
[Unit]
Description=Power-off gpu

[Service]
Type=oneshot
ExecStart=/usr/bin/vgaoff

[Install]
WantedBy=multi-user.target
```
<a name="install"></a>
## Install
```
[Install]
WantedBy=multi-user.target
```
<a name="unit"></a>
## Unit
```
[Unit]
Description=Power-off gpu
```

<a name="service"></a>
## Service
```
[Service]
Type=oneshot
ExecStart=/usr/bin/vgaoff
```

### ExecStart
ExecStart is the
Systemd doesn't provide any special support for shell scripts, for quick and dirty calls you can call `sh` directly:   
`ExecStart=/bin/sh -ec 'echo hello'`

Ideally though you'll be wanting a script that can be called from outside the unit.  
`ExecStart=/usr/bin/vgaoff`

### ExecStop


<a name="pre-start-post-stop></a>
## pre-start and post-stop conditions

<a name="unit_control"></a>
## Unit Control
* `systemctl start unitname`
* `systemctl stop unitname`
* `systemctl restart unitname`
* `systemctl status unitname`
* `systemctl daemon-reload` to reload unit files after changes are made
* `systemctl list-units --type service` lists the services that are installed and have init scripts
	* enabled - has a symlink in the .wants directory
	* disabled - doesn't have a symlink in the .wants directory
	* static -  missing the [install] section in the init script, normally because this service is a dependency of another service
 

## Errors


[]:	
[]:	
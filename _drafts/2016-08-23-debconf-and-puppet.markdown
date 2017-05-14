---
layout: post
title:  "debconf and Puppet"
date: 2016-08-23
categories: debconf puppet linux debian
---

When installing MySQL on Ubuntu/Debian you are prompted for a root password and then asked to confirm this again via a minimal GUI. This poses problems when attempting to script the installation of MySQL and these problems are then compounded when attempting to do so via puppet.  

### Disabling Debconf Interaction
You can turn off the interactive GUI that the MySQL installer uses to prompt for the root username and password by exporting a shell variable: 
```
export DEBIAN_FRONTEND="noninteractive"
```
This "frontend" is actually part of [debconf][debconf] which is the Debian Configuration Management system, this is the system that installers can ask questions of (in the case of re-installation or upgrades) or through (in the case of first time install) to get user preferences for installation. Essentially it provides a gui to query the user for information and a database to store it.

### Setting the debconf values 
In order to know what the entries in debconf look like for setting the root password I installed MySQL via the installer and entered a default root password at each prompt and various other non-critical settings it asks for. Then I queried debconf directly for values relating to mysql using the following command:
`sudo debconf-get-selections | grep mysql`.  
  
From that ouput the two following entries piqued my interest:
```
mysql-community-server mysql-community-server/root-pass password
mysql-community-server mysql-community-server/re-root-pass  password
```

Now we need to find a way of putting these values into debconf so they can be referenced by the installer, this is done using */usr/bin/debconf-set-selections* through puppet exec calls: 
```
  exec {"set root password":
    path => "/bin/",
    command => "/bin/echo mysql-community-server mysql-community-server/root-pass password ${password} | /usr/bin/debconf-set-selections",
  }

  exec {"confirm root password":
    path => "/bin/",
    command => "/bin/echo mysql-community-server mysql-community-server/re-root-pass  password ${password} | /usr/bin/debconf-set-selections",
  }
```
### Disabling Debconf interaction with Puppet
The export for disabling debconf interaction mentioned previously doesn't work for puppet as shell variables cannot be exported via puppet's `exec` resource using the `command` parameter which presents a problem as we cannot implicitly set this value via an exec call. The `package` resource type doesn't provide a way to export these values either.  
This rules out making an exec call to export the `DEBIAN_FRONTEND=noninteractive` global variable followed by installation using puppet's `dpkg` package provider.
```
  exec {"mysql-community-server":
    path => ["/usr/bin/","/bin/","/usr/sbin", "/sbin", "/usr/local/sbin"],
    environment => ["DEBIAN_FRONTEND=noninteractive"],
    command =>  "dpkg -i ${local_install_dir}${mysql_community_server_file}",
    logoutput => on_failure,
    notify => Service["mysql"],
    require =>  [File["${mysql_community_server_file}"],
      Package["libmecab2"],
      Package["mysql-client"],
      Exec["set root password"],
      Exec["confirm root password"],
    ]
  }
```
Although as can be seen above it **is** possible to use an `exec` resource to install the package using dpkg (debian package manager) and then take advantage of the `environment` parameter to set our environmental/shell variable=value. 

Now we have a way of entering values into debconf ready for an unassisted installation of MySQL and have a way of making puppet honour the `DEBIAN_FRONTEND=noninteractive` global variable so that the unassisted installation doesn't hang waiting for user input.

[debconf]:	https://wiki.debian.org/debconf




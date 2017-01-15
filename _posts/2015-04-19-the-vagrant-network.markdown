---
layout: post
title:  "The Vagrant Network"
date: 2015-04-19
categories: VMs networking VirtualBox Vagrant
---
I have found myself spending more time than I should configuring Vagrant networking with my Vagrant files and VirtualBox over the past year and figured it was about time to put some of this knowledge down somewhere.

## Public Networking
[Public networking][public-networking] allows your vagrant machines to be allocated IP addresses as if they were physical devices on your network: `config.vm.network "public_network"`, you also can attempt to manually set the IP address yourself `config.vm.network "public_network", ip: "192.168.0.17"`.
### Pros
* Your VMs are available to the wider network making for easy access to development stacks
* IP allocation if using the defaults will be handled for you, no hassle

### Cons
* Uses up IP allocation on your network via DHCP
* Vagrant's use of a default insecure key and password for the vagrant user means your VMs will be exposed unless you stake explicit steps to secure them. 
* Manually specifying the IP address in public networking rarely seems to work in my experience/configuration. 

## Private Networking
[Private networking][private-networking] allows you to provide your machines with IP addresses within the vagrant subnet (192.168.33.x)  
You can either specify these yourself `config.vm.network "private_network", ip: "192.168.33.25"`.  
Or you can allow vagrant to assign these itself `config.vm.network "private_network", ip: "auto"`.  
If you want external access on a port then port forwarding is required: `config.vm.network "forwarded_port", guest: 80, host: 8080`. 

### Pros
* Control over IP address allocation if you want it
* As they are on the same subnet inter-VM communication just works
* No DHCP IP allocation issues on the wider network
* No external systems can access your VM over the network

### Cons
* IP Address clashes - if **you** don't keep track of addresses you've allocated and the machines you're running then your chances of getting an IP address clash go up.
* Lack of external access
* Requires [port forwarding][forwarded-ports] from host to guest OS if you require access beyond SSH
 
## MAC address static IP allocation.
Technically this is a subset of public networking but has proven to be more useful than trying to use the static IP option. What I do is set up a public network then [bridge][bridge] the adapter and specify a MAC address for the virtual machine.

An example of a Linux / Mac OS bridge:  
`config.vm.network "public_network", :mac => "080027D3418E, :bridge => "en1: Wi-Fi (AirPort)"`

An example of a Windows bridge:  
`config.vm.network "public_network", :mac => "080027D3418E", :bridge => "Realtek PCIe GBE Family Controller"`

I find myself creating a define section (`config.vm.define "profile_name" do |profile_name|`) in the vagrant config for each physical machine as the bridging requires the OS level name of the network adapter, this can be found using `ifconfig` on linux/Mac OS and `ipconfig /all` for Windows.

Now in my router settings I can configure a static IP based on MAC address (and even port forwarding should I wish), ensuring that I can host services from my vagrant files and will find them at a consistent IP address allowing me to use a modified hosts file to alias this address to a nice readable/memorable domain.

### Pros
* You can allocate an IP address at the router level to ensure you get the same IP address each time
* Combining defined profiles with the MAC address and physical networking adapters allows for creation of dev, test etc environments at fixed places on particular machines. 

### Cons
* There is very little documentation around about using bridged adapters, support varies across VM providers as well it seems.
* Not portable across physical machines or OS's as they will have different named networking adapters 

## Aside
I'm currently making use of all the above vagrant networking styles as each has a strength and weakness. Typically for services I'm hosting on a small Dell server I'll allocate an IP address to MAC addresses for each VM, I then maintain a little network diagram so I'm aware of the MACs and IPs I'm using. For writing puppet modules I tend to stick with private networking and for proof reading and viewing layout of this blog I'll do a private network with an allocated ip. 


[private-networking]: 	https://www.vagrantup.com/docs/networking/private_network.html
[forwarded-ports]:		https://www.vagrantup.com/docs/networking/forwarded_ports.html
[public-networking]:	https://www.vagrantup.com/docs/networking/public_network.html
[bridge]:				https://friendsofvagrant.github.io/v1/docs/bridged_networking.html























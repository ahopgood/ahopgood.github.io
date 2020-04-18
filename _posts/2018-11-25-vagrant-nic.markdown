---
layout: post
title:  "The Vulnerable Vagrant NIC"
date: 2018-11-25
categories: vagrant virtualbox
--- 

Recently when running vagrant on one of my existing virtual machines I received the following warning:  
>
==> ServerUbuntu16: Vagrant has detected a configuration issue which exposes a  
==> ServerUbuntu16: vulnerability with the installed version of VirtualBox. The  
==> ServerUbuntu16: current guest is configured to use an E1000 NIC type for a  
==> ServerUbuntu16: network adapter which is vulnerable in this version of VirtualBox.  
==> ServerUbuntu16: Ensure the guest is trusted to use this configuration or update  
==> ServerUbuntu16: the NIC type using one of the methods below:  
==> ServerUbuntu16:  
==> ServerUbuntu16:   https://www.vagrantup.com/docs/virtualbox/configuration.html#default-nic-type  
==> ServerUbuntu16:   https://www.vagrantup.com/docs/virtualbox/networking.html#virtualbox-nic-type  

After some digging around it turns out that this issue was fixed in VirtualBox version 5.2.2 but due to the way Oracle document their releases on a quarterly basis no mention was made of it.  
There are two solutions to this issue then:
1. Upgrade to virtualbox `5.2.2` or higher, this comes with the usual caveats of upgrading VirtualBox where **all** VMs need to be stopped and you need to be vigilant of contract changes in VirtualBox's manager interface.
2. Switch NIC type in the virtual machine
	1. Find list of `nictype` from the [virtualbox manual](https://www.virtualbox.org/manual/ch08.html) under the `modifyvm` command
    1. As it currently stands they are `Am79C970A|Am79C973|82540EM|82543GC|82545EM|virtio`
    1. Set the [nic type](https://www.vagrantup.com/docs/virtualbox/networking.html#virtualbox-nic-type) via vagrant:
    ```
    config.vm.network "private_network", ip: "192.168.50.4",
      nic_type: "virtio"
    ```


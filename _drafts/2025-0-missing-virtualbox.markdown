---
layout: post
title:  "The missing Virtualbox"
date: 2025-0
categories: vagrant virtualbox
---

So I had to take down a machine the other day at short notice and when it came back up vagrant reported that there was no provider available.   

I decided to check what virtualbox thought of this:
```
alexander@cupboard-server-2:~/git-checkouts/infrastructure/vm/jenkins$ VBoxManage --version
WARNING: The character device /dev/vboxdrv does not exist.
         Please install the virtualbox-dkms package and the appropriate
         headers, most likely linux-headers-generic.
```
* I did have `virtualbox-dkms` installed but tried again anyway `sudo apt-get remove virtualbox-dkms`
* I Tried uninstalling and re-install virtualbox and still received an error on `sudo service virtualbox status`
```
Oct 07 06:25:07 cupboard-server-2 virtualbox[574284]:  * No suitable module for running kernel found
```
* I'm not sure what happened but a full remove and reinstall of `virtualbox-dkms` fixed the issue:
    * sudo apt-get remove virtualbox-dkms
    * sudo apt-get install virtualbox-dkms



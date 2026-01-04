---
layout: post
title:  "Increasing Vagrant disk sizes on Ubuntu"
date: 2026-0
categories: vagrant virtualbox ubuntu
---

I've recently found that the disk size on my vagrant boxes can be a bit small in some cases.  
My base boxes use Virtualbox's expandable disk format (`.vdi`) but this is then compressed by Vagrant when the box is exported.  
When running the boxes the disk size doesn't expand to the full size you might expect.  
To get around this I ended up increasing the disk size manually:
```
sudo lvextend -L+5G /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs  /dev/ubuntu-vg/ubuntu-lv
```
* These command assume the default Ubuntu LVM layout with a volume group of `ubuntu-vg` and a logical volume of `ubuntu-lv`
* `lvextend` increases the size of the logical volume by 5GB
* `resize2fs` resizes the filesystem to use the new size of the logical volume
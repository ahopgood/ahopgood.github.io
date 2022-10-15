---
layout: post
title:  "How to grab old Dropbox versions on linux"
date: 2022-04-16
categories: dropbox linux
---
Recently I had to find an older version of the Dropbox installer for Linux in order to do some specific testing on a platform.  
Unfortunately at the netime there wasn't an obviously available archive page to download older versions from (this may change in the future), at least not one officially sourced from Dropbox themselves, other sources such as [oldversion.com](https://oldversion.com) or [uptodown.com](https://dropbox.en.uptodown.com/windows/versions) do exist but there is no guarantee they have not been maliciously tampered with.
  

* My search started with a post from the [Desktop Client Forum](https://www.dropboxforum.com/t5/Dropbox-desktop-client-builds/bd-p/101003016).  
* From this I found a page for downloading a [beta release](https://www.dropboxforum.com/t5/Dropbox-desktop-client-builds/Beta-Build-160-3-4611/td-p/628576)
* Using the offline links I was able to construct / infer the URL structure for downloading offline installers for different OSes.

## Windows and Mac
* `https://www.dropbox.com/downloading?build=119.3.1762&plat=win&type=full`
  * `build` is the build/version number you want e.g. `119.3.1762`
  * `plat` is the platform you want the installer for; `win` - windows, `mac` - macOS
  * `type` is `full` or `autosignin`

## Linux
Linux installers use a different download domain and pattern based on file name, both are full distributions packaged as gzipped tar archives and offers 32 or 64 bit versions:
* `https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.<arch>-<version>.tar.gz`
  * \<arch\> is `x86` (32-bit) or `x86_64` (64-bit)
  * \<version\> is the same as the build parameter for windows or mac e.g. `124.4.4910`.

## Example URLs
Here are example URLs all for the `124.4.4910` version on Windows, mac and linux:  
* [https://www.dropbox.com/downloading?build=124.4.4910&plat=win&type=autosignin](https://www.dropbox.com/downloading?build=124.4.4910&plat=win&type=autosignin)  
* [https://www.dropbox.com/downloading?build=124.4.4910&plat=win&type=full](https://www.dropbox.com/downloading?build=124.4.4910&plat=win&type=full)  
* [https://www.dropbox.com/downloading?build=124.4.4910&plat=mac&type=autosignin](https://www.dropbox.com/downloading?build=124.4.4910&plat=mac&type=autosignin)    
* [https://www.dropbox.com/downloading?build=124.4.4910&plat=mac&type=full](https://www.dropbox.com/downloading?build=124.4.4910&plat=mac&type=full)  
* [https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86-124.4.4910.tar.gz](https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86-124.4.4910.tar.gz)  
* [https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86_64-124.4.4910.tar.gz](https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86_64-124.4.4910.tar.gz)  
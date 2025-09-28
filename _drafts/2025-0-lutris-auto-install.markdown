---
layout: post
title:  "Writing a Lutris script to auto-install on GOG"
date: 2025-0
categories: lutris
---

## Using a local install script
There are [Example Scripts](https://github.com/lutris/lutris/blob/master/docs/installers.rst#example-scripts) in the Lutris github repository you can use as a starting point or just to test installing locally:
```
lutris -i ~/path_to_script/script.yml
```
You'll notice that there are different ways to provide installer files:
1. By asking the end user to provide them via a file picker dialog
2. By hosting them on the web

## Hosting your installers on a web server
To test locally you can host your files via a web server by running the following in the directory your local install scripts or installers are located:
```
python3 -m http.server 8080
```
Then reference them via http://locahost:8080/.  
This provides a faster feedback loop than having to push them to github or another web server.

### Conditional local hosting
```
```

## Auto-fetching gog games via scripts
* `service: gog` is required for Lutris to know we're going to auto-fetch the game
* `service_id: '<somenumber>'` is required to identify the game 
These can be obtained via [Lutris.net](https://lutris.net/games/star-wars-dark-forces/) and right-clicking on the `GOG(Auto) version` install button and copying the link e.g. `lutris:gog:1421404433`
You need to assign a placeholder for the gog file via `files: - gogsetup: N/A:Select the installer from GOG`
Also to auto-install you need to set the `installer: - autosetup_gog_game: "gogsetup" field`, note this references the name of the file you created earlier.

Here is an example of my installer:
```
runner: linux
service: gog
service_id: '1421404433'
script:
  files:
    - gogsetup: N/A:Select the installer from GOG
  installer:
    - autosetup_gog_game: "gogsetup"
...
slug: star-wars-dark-forces-gog-tfe
steamid: 32400
version: GOG + TFE
year: 1995
```


## Conclusion
I now have the following benefits when developing Lutris install scripts:
* I can test my script locally without having to push to github or another web server
* I can host my installers or scripts locally via a simple web server
* When ready my script will use the web hosted versions of installers or scripts
* I can auto-fetch the game installer from GOG without having to download it manually
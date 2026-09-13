---
layout: post
title:  "Writing a Lutris script to auto-install on GOG"
date: 2026-09-13
categories: lutris linux
---

Around a year ago I was experimenting with Lutris on linux to install a game that was an old favourite of mine; Star Wars Dark Forces.  
This was the game that convinced me I needed my own computer and it's sequel; Star Wars Dark Forces II: Jedi Knight, inspired me to build my first computer by hand.  
I'm keen to move away from Windows and the only thing holding me back is being able to play games, I'd heard great things about gaming on Linux improving so thought I'd try a retro game.  

I've purchased the game on GOG (Good Old Games) and Lutris allowed me to install it without issue, but I soon realised that the game hadn't aged well with the screen resolution and controls not being a great experience.  
I noticed the Lutris installer offered another install option; installation using [The Force Engine](https://theforceengine.github.io/) an open source project that allows you to play the game with modern controls and screen resolutions, it still requires a legitimate version of the game though.  

The install worked but my game wasn't working correctly, I was missing the mission loading page and couldn't load my saved games.  

I wanted to see if I could write a Lutris script to:
1. build a newer version of The Force Engine from source that fixes this issue
2. use this version of the engine with Dark Forces
3. and auto-install the game from a local GOG installer without having to download the installer manually each time.

## Using a local install script
There are [Example Scripts](https://github.com/lutris/lutris/blob/master/docs/installers.rst#example-scripts) in the Lutris github repository you can use as a starting point or just to test installing locally:
```
lutris -i ~/path_to_script/script.yml
```
You'll notice that there are different ways to provide installer files:
1. By asking the end user to provide them via a file picker dialog
```
script:
  files:
  - installer: "N/A:Select the game's setup file"
```
  * This requires user interaction to select the file
  * Once selected it is faster as it doesn't have to be downloaded from the web each time
2. By hosting them on the web
```
script:
  files:
  - myfile: https://example.com/mygame.zip
```
  * This doesn't require any user interaction
  * But does require downloading the file each time.


## Hosting your installers on a web server
I figured I could get the best of both worlds by hosting my installers on a web server and referencing them in my Lutris script, this way I get the speed up of local files without requiring human interaction.  
To test locally you can host your files via a web server by running the following in the directory your local install scripts or installers are located:
```
python3 -m http.server 8080
```
Then reference the web server via http://locahost:8080/ in your lutris script:
```
script:
  files:
    - engine: http://locahost:8080/theforceengine.tar.xz
```
This provides a faster feedback loop than having to push them to github or another web server.  

### Conditional local hosting
By default I let my script use the force engine located on github.  
I generate a new local lutris script with a bash script and the `sed` command to replace the github URL with my locally hosted version:
```
FILENAME="Star Wars - Dark Forces - GOG - TFE"
HOST=$1

if [ -z $HOST ];then
   HOST="http://localhost:8080"
fi

GITHUB=https://github.com/somelocation/raw/master/Star%20Wars%20-%20Dark%20Forces

# Escape forward slashes before calling sed
GITHUB=$(echo $GITHUB | sed 's/\//\\\//g')
HOST=$(echo $HOST | sed 's/\//\\\//g')

cat "${FILENAME}".yaml | sed "s/${GITHUB}/${HOST}/" > "local.${FILENAME}".yaml
```
This allows me to do local testing whilst leaving my main script to use the web hosted version of the installer.

## Auto-fetching gog games via scripts
* `service: gog` is required for Lutris to know we're going to auto-fetch the game
* `service_id: '<somenumber>'` is required to identify the game
  * These service IDs can be obtained via [Lutris.net](https://lutris.net/games/star-wars-dark-forces/) and right-clicking on the `GOG(Auto) version` install button and copying the link e.g. `lutris:gog:1421404433`
* You need to assign a placeholder for the gog file via `files: - gogsetup: N/A:Select the installer from GOG`
* Finally to auto-install you need to set the `installer: - autosetup_gog_game: "gogsetup" field`, note this references the name of the file you created earlier.

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

    I later discovered that [Dark Forces Remastered](https://www.gog.com/en/game/star_wars_dark_forces_remaster) is now available that fixes many of the gameplay niggles I had, I've yet to try it on Linux...
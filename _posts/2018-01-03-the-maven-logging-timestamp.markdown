---
layout: post
title:  "The maven logging timestamps"
date: 2018-01-03
categories: maven intellij macos
---

## The issue
Maven is a very useful build tool that has a plethora of plugins and its functionality has grown accordingly.  
The problem with this growth in utility is that the maven build cycle can now take a significant amount of time to complete when you consider multiple static code analysis tools (cobertura, findbugs, pmd etc), reporting, testing, packaging and in some cases deploying.
 
Recently it was necessary for me to debug how maven was spending its time, now maven does provide a module based breakdown of run times and it does provide a good amount of informative logging. But it does not go into granular detail in these logs in relation to time, what is needed is a timestamp for each log entry in the same way our Java applications perform logging.  

There are a few guides on how to add logging to maven but none had really covered how to do so with the **bundled** maven that comes with **IntelliJ** IDE.   

## Solution 
As per most solutions we need to create a logging properties file `touch simplelogger.properties` typically this will be placed into a `/conf/logging/` directory in the home directory of your maven installation.

Then you add the following lines to enable the logging and the format you want within the properties file:  
```
org.slf4j.simpleLogger.showDateTime=true
org.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss
```

Finally you need to place the logging configuration file into the correct location for the IntelliJ bundled maven distro.  
Below is an example of the location of the bundled maven (version 3) on macos for IntelliJ:  
```
sudo cp simplelogger.properties /Applications/IntelliJ\ IDEA.app/Contents/plugins/maven/lib/maven3/conf/logging/
```

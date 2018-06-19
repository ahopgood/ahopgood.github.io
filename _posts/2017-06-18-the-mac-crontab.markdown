---
layout: post
title:  "The Mac OS crontab"
date: 2017-06-18
categories: MacOS cron
---

As part of a recent job change I've had to become acquainted with a Macbook Pro and MacOS. I find that there are a certain number of tasks that I do every morning to get my docker and project files up to date; a `docker pull`, `git fetch` and `git pull`. Naturally I figured that I could script these operations but I still found myself having to run them every morning, then I remembered MacOS is a unix derivative and should have the ability to schedule cron jobs, it is pretty similar to doing it in Linux.

To set up a script to use cron scheduling in Mac OS you will need to add the script to the crontab.  
This can be done via `crontab -e` to launch the vi editor.  
If you (like me) prefer nano you can specify an editor as a variable `EDITOR=nano crontab -e`.  

Next you'll need to decide when to fire your script, this follows the typical [crontab][crontab] pattern of space separated values:  
1. minute 0-59
2. hour 0-23
3. day of month 1-31
4. month 1-12
5. day of week 0-6 (Sunday to Saturday)
6. commands

An example that will run *myscript.sh* every minute of every hour of every day of every month is below:  
`* * * * * myscript.sh`

Each value can take various forms:
* \* meaning every minute/hour/day/month etc depending on the position of the value
* numerical for a specific trigger, e.g. 1 to fire at the 1st minute of an hour
* comma separated to define a sequence e.g. 1,2,3 to fire on the 1st, 2nd and 3rd minute of an hour
* hyphens (-) to define a range e.g. 0-29 to fire every minute for the first half of an hour
* with a denominator e.g. */2 to fire every other minute

When saved you can check your crontab listing to see all scripts registered to fire according to a cron schedule `crontab -l` will print the schedule out to the console.

## Debugging
Once your script is set up in the crobtab how do you know it has fired?  
What if your script has noticeable side effects but you cannot see them indicating your script has not run correctly?  
The first step to debug is to capture any standard out or standard error console output, you do this like you would any script.   
`30 8 * * 1-5 cd /some/path && myscript.sh >> /tmp/cron.log 2>&1`
In the above example instead of appending separately for stdout and stderr we output via `>>` to stdout and then redirect stderr to stdout using `2>&1`.  
Now we can see any output or errors we might be getting.  

The following commands will also prove useful to set up as crontab tasks to aid with learning about the environment in which scripts are run under the crontab user:
* `30 8 * * 1-5 whoami` which user is running the script (indicates permissions levels, groups, sudo access etc)
* `30 8 * * 1-5 echo $PATH` discover the state of the $PATH variable for cron, this could be severely limited, again similar to permissions issues.
* `30 8 * * 1-5 env` get the output of the current environment.

## Notes
Most likely crontab is running with a reduced `$PATH` variable so you can either use [env][env] to configure the path variable for your script in the crontab entry or you can create a local version of the path variable in the script itself although this will make the script a little more brittle and less portable.  

[crontab]: 	https://en.wikipedia.org/wiki/Cron
[env]: 		https://en.wikipedia.org/wiki/Env
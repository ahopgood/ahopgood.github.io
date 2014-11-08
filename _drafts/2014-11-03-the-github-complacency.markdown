---
layout: post
title:  "The Github Complacency"
categories: security aws github
---
![AWS Logo](/assets/aws_logo_small.png)  ![Github Logo](/assets/github_logo_small.jpg)

###The problem###

I received an email from Amazon web services (AWS) this morning informing me my account had been compromised.

*Oh Shit!*

It turns out that Amazon diligently scrapes the web for patterns that match AWS credentials and they'd found mine...

*Cringe!*

Yes it turns out whilst performing a demonstration of Amazon's Simple Notification Service (SNS) in an effort to get the code from my personal laptop onto my work desktop I pushed it to github so that changes could be tracked.

I had accidentally committed the AWS credentials as a properties file, I was in such a rush I neglected to add the file to the git .ignore, doh!

I received this email at around 8:43am, I proceeded to log into the AWS console, something I hadn't done in a while.

I could see that 20 large 3.8x windows instances per region (except the new Frankfurt region) had been created at around 06:29am. 

The Amazon email notified me that they had put restrictions on the ability to create new instances via the AWS console. *Ok* so this was a *slight* silver lining, no more instances could be created on my account. This meant I only had to deal with the existing instances. 

This did not prepare me for the billing page, this indicated that they had been running for a cumulative total of 240 hours per region this activity for a short period of time had racked up a bill of **$7,866.81**!

For comparison my usual bill is $1.64 per month.

###The Recovery###

First things first, I quickly logged into github, deleted the offending file and made the repository private. Now if anyone wanted access to this project I would have to authorise it. I also added the file to the .gitignore file so it couldn't be absent mindedly committed again in future.

Now my github repository should no longer be a vulnerability.

Next **I deleted the AWS key**, now the credentials were useless to everyone, onto the bigger problem; I needed to terminate the unauthorised instances.

To make matters more problematic whoever had done this had enabled a feature called *termination protection*, this feature means that an instance cannot be terminated without removing this protection. Now I assume the intended use case for this is to prevent a vital service being *select all'd* and then terminated by mistake. Each instance needed the protection removed individually before termination would work.

In my case it mean I had to remove this protection **one instance at a time** for 20 instances over 8 regions, 160 select -> right click -> disable protection -> confirm combinations, only then could I terminate then en-mass, that was a fun hour... 

Prior to this I *stopped* all the instances first in an attempt to prevent racking up more onto my bill until I could terminate them.

The fact that this was happening on my day off was total [Murphy's Law][Murphy's Law].

Now it was time to contact Amazon customer support, I had done everything I could do on my side of thing:

- I had deleted the offending credentials,
- Removed them from the repository, 
- Made the repository private,
- Prevented them being committed again in future using .gitignore, 
- Deleted the key within AWS,
- Terminated all running instances. 

Using the custom service interface on the AWS account page I initialised a call, this uses the website to call your provided phone number, pretty neat really, I found myself on hold without making the call myself. It may only be a small thing but knowing you aren't being charged to stay on hold made the 10 minute wait a benign experience.

Something else to note here is that when the call was picked up it was by Shane who was clearly American, now I'm British and I found this reassuring, a native English speaker meant one less barrier to getting this resolved. Not only that but the line was *good* no lag or crackling on the line, again another potential barrier gone. 

Shane had my account information from the form I submitted through the customer service interface, was already looking at my account after the initial "hello" and clearly read the information I had submitted, wow this wasn't how overseas support calls are supposed to go at all...

After checking I had terminated  the instances on the account and that the offending key had been deleted, I was reassured about what the next stages would be; the account would be monitored for unauthorised use over 24 hours followed by a concession request for the billed unauthorised usage.

One question that should have popped into your head by now is **why didn't I know of this account activity earlier?** Well it turns out that there is a setting for enabling email notifications but this setting is off by default, I have made sure that was not the case now.

###The Do better###
The following are things this experience taught me I should do better or bear in mind:

* Don't ever commit unencrypted credentials to github.
* Don't ever use a public github repository for projects that contain credentials.
* People **can** and **do** actively search through public github repos and commits for credentials to use towards nefarious ends.
* Amazon keys even if you only intend them for consumption of a low cost API (Simple notification service) can be used for *waaaaaay* more purposes than you can imagine.
* Use Amazon's [Identity and Access Management][Identity and Access Management] to give users specific privileges such as limiting their actions to specific subsets of functionality.
* Enable email notifications for account activity.

I'm currently awaiting the clearance of the concession request but can say that I'm very happy with Amazon's customer service, especially considering I was the source of my own security breach.

I have done a bit of research and it turns out I'm not the only person who has fallen victim to purloined AWS credentials, [Forbes][Forbes Report] reported on this earlier in the year. Turns out that these criminals are using the instances to mine for [litecoin][litecoin] a virtual currency lesser in value to bitcoin but easier to mine using conventional x86 processing power and doesn't favour GPUs or dedicated ASIC controllers like bitcoin does. This appears to be quite a [common strategy][Litecoin Mining]

[Identity and Access Management]: http://aws.amazon.com/iam/
[Forbes Report]: http://www.forbes.com/sites/runasandvik/2014/01/14/attackers-scrape-github-for-cloud-service-credentials-hijack-account-to-mine-virtual-currency/
[litecoin]: https://litecoin.org/
[Litecoin Mining]: http://vertis.io/2013/12/16/unauthorised-litecoin-mining.html
[Murphy's Law]: http://www.murphys-laws.com/


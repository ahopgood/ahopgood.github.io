---
layout: post
title:  "Jekyll Cannot Listen"
date: 2016-12-29
categories: Jekyll Ruby
---

This blog is written in Jekyll and hosted via [github pages][github pages] which provides the benefits of versioning, branching, automatic push-to-deploy on master as well as hosting.

One problem with writing in markdown and then pushing to github pages to view your changes is that any mistakes go live straight away and your git history becomes chock-a-block full of small commits such as `added line break between paragraphs 2 & 3` or `fixed image link`. Or even worse mistakes go unnoticed and it reflects badly on **you**.

[Jekyll][Jekyll] has a nifty feature where you can spin up an instance of Jekyll within its own web server and have it host your blog locally on port 4000.

`jekyll serve -s blog_source_directory -d blog_output_directory --watch --drafts --force_polling &`

* **-s blog_source_directory** is the blog source directory that Jekyll will compile content from.
* **-d blog_output_directory** is the destination directory you wish compiled static content to be sent to, this is the directory that the blog will be served from.
* **--watch** allows the Jekyll process to watch your -s blog_source_directory for changes.
* **--drafts** will include your drafts folder in the compilation and deploy process
* **--force_polling** this is used to poll for changes instead of using the inotify gem which sometimes doesn't work depending on your combination of gems and versions.
* **&** is used to run a process as a stand alone daemon in linux so it doesn't lock your terminal to the output/termination of your process.

With the above command Jekyll will be started as a daemon on linux and will watch the blog_source_directory for changes, it will then compile those changes to the blog_output_directory. These changes will be served to the `http://localhost:4000` address, it will include your drafts as well so you can view how they look as if they were promoted to _posts status. 

### The issue
This write up is for a solution I discovered a while ago but recently was reminded of how useful it was.

I tend to create puppetised virtual machines and control them using vagrant when creating a test environment. This allows for a repeatable environment to be created and means I'm not too reliant on running a particular operating system, I can run Windows on my laptop and have it create an Ubuntu box for Jekyll for example.

I encountered an issue when installing the Jekyll gem and its dependencies:
```
Error: Execution of '/usr/bin/gem install /etc/puppet/installers/listen-3.0.8.gem' returned 1: 
ERROR:  Error installing /etc/puppet/installers/listen-3.0.8.gem:
        "listen" from listen conflicts with installed executable from sass-listen
```
It seems that there is a clash between the `sass-listen` and the `listen` gems, the only source on the internet that could provide any insight was [stackoverflow][only other result] and that seemed to suggest that updating the version of Ruby to 2.2.5 would solve things.

### The solution
I then spent hours trying to find a way I could puppetise the installation of Ruby such that I can specify the version to use, this is complicated by the fact that the version of Ubuntu I am using (wily, 15.10) only has Ruby 2.2.3 available in the package manager repositories. If you're trying to find a way to replace the package manager provided Ruby version I'd advise you don't; the pain isn't worth it, I'm probably missing something here but I'm not a Ruby developer so instead I found a [kludge][kludge].

Make use of the `--force` parameter when installing the `sass-listen` provider and things seem to all install without issue, I even went overboard and added it to the Jekyll gem itself, overkill but hey so far I haven't seen any side effects and I'm able to preview my blog posts ahead of time! 

[github pages]:		https://pages.github.com/
[Jekyll]:			https://jekyllrb.com/
[only other result]:	https://stackoverflow.com/questions/40085215/listen-conflict-when-installing-jekyll-with-docker
[kludge]:			https://en.oxforddictionaries.com/definition/kludge





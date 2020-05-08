---
layout: post
title:  "Jenkins and the Github Private Repository"
date: 2019-06-08
categories: Jenkins github
--- 

## The Problem
When I change a public repository of mine in github to *private* via:  
_Settings_ -> _Options_ -> _Danger Zone_ -> _Make this repository private_  

I get an error in Jenkins when running `Scan Multibranch Pipeline Now`.  
Viewing the logs I can see the following error:
```
...
ERROR: [Wed Jun 26 20:28:41 UTC 2019] Could not update folder level actions from source eeeaef40-37d1-45a6-8e84-7652b9caeb03
hudson.plugins.git.GitException: Command "git ls-remote git://github.com/myuser/myProject.git" returned status code 128:
stdout: 
stderr: fatal: remote error: 
  Repository not found.
...
FATAL: Failed to recompute children of Markdown-pipeline
hudson.plugins.git.GitException: Command "git ls-remote git://github.com/myuser/myProject.git" returned status code 128:
stdout: 
stderr: fatal: remote error: 
  Repository not found.
...
```
No scanning is taking place to update the job with new branch events or push events.  
None of the branches in my pipeline will build if I try to build them manually.  

## The Background
* I have successfully configured a github personal access token (_Click Avatar_ -> _Settings_ -> _Developer Settings_ -> _Personal Access Tokens_)
* My token permissions are limited to appropriate ones: **repo** (_repo:status_, _repo_deployment_, _public_repo_, _repo:invite_) and **admin:repo_hook** (_write:repo_hook_, _read:repo_hook_). 
* I am the sole owner of the public repository.
* I have 2-Factor Authentication (2-FA or Multi-factor authentication-MFA) configured on my account.
* I have a `jenkinsfile` configured with a build stage to check out my project from the repository
* I also have a seed job in the form of a [groovy](https://groovy-lang.org/) script to seed my [multibranch pipeline](https://jenkins.io/doc/tutorials/build-a-multibranch-pipeline-project/) job that will use the `jenkinsfile`  

Jenkinsfile build stage:
```
stage('build') {
    steps {
        git credentialsId: 'github_token', url: 'git://github.com/myuser/myproject.git', branch: '${BRANCH_NAME}'
        sh 'mvn --version'
        sh 'mvn clean install'
    }
}
```
Seed job setup:   
```
branchSources {
    git {
        remote('git://github.com/myuser/myproject.git')

        credentialsId("github_token")
    }
}
```  

## The Solution
I remembered having a similar issue with IntelliJ's git operations a while back and stumbled on [this](https://intellij-support.jetbrains.com/hc/en-us/articles/206537004-How-to-access-GIT-remote-repositories-with-2-factor-authentication) post on their support page.  

Due to the use of 2FA on my account the git command line client cannot login when using the HTTPS access method unless I use a personal access token, which I already have.  

But I noticed that I was using the `git://` protocol in my calls and **not** HTTPS, so figured I should try switching the protocol to HTTPS with the personal access token.  

So to enable repository scanning I updated my groovy seed job to use the https protocol:
```
branchSources {
    git {
        remote('https://github.com/myuser/myProject.git')

        credentialsId("github_token")
    }
}
```
And for my branches in the `jenkinsfile` pipeline I also switched the build stage:
```
stage('build') {
    steps {
        git credentialsId: 'github_token', url: 'https://github.com/myuser/myproject.git', branch: '${BRANCH_NAME}'
        sh 'mvn --version'
        sh 'mvn clean install'
    }
}
```

Now I am able to perform repository scanning on a private repo.
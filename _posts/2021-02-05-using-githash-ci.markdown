---
layout: post
title:  "Using a githash for CI/CD"
date: 2021-02-07
categories: git CI CD
---

Continuous Integration and Continuous Deployment are the practices of continually building and deploying (respectively) your code when you commit it to version control.  

This means any time you commit code you can expect this code to make it to production after it has passed the various test (unit, integration, smoke, contract etc tests) and deployment phases of your CI/CD pipeline.  

Previous strategies of explicitly deciding on a release version to cut from the master or main branch and tagging it in version control no longer scales when every commit merged to master / main can be a valid deployment.  

This is also compounded by some CI/CD pipelines also running on branches on pre-release or bespoke branch environments too.  

Having a specific version is important to assist with rollbacks, release notes/change logs and bug reporting / bug remediation.

One way to accommodate these various concerns is to create a tag name for your docker images using the service name, current timestamp and githash.
```
#! /usr/bin/env bash

SHORT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date "+%Y-%m-%d")
BRANCH_NAME="$(git branch --show-current)"
BRANCH_NAME=$(echo $BRANCH_NAME | sed s/\\//-/)

printf "%s-%s-%s\n" "${BRANCH_NAME}" "${TIMESTAMP}" "${SHORT_SHA}"
```

In this way we have:
* a unique (well highly collision resistant) identifier thanks to our commit hash
* a temporal marker in the form of the timestamp, useful for rollback, rolling forward, bug report timings and general pointer for incident time lines
* a pre-merge indicator of which branch is deployed via the branch name when deploying to shared resource environments.
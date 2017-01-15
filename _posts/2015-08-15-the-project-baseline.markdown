---
layout: post
title:  "The project baseline"
date: 2015-08-15
categories: java project-management
---
Some of the charges levelled at Java development are that it *requires too much setup* or *you cannot get started quickly* when compared to newer languages such as Ruby with its rails framework or Javascript with its numerous frameworks for every need (so many in fact that there is a [web site][jscountdown] to track the length of time since the birth of the last framework). 

I believe these are fair charges, Java was designed long before web 2.0 or the agile methodology, the architects could not foresee how the industry could change. They did however build a language that removed any need for machine specific compilation and brought object oriented concepts to the mainstream. Little did they realise that Javascript would arrive using the browser as a (nearly) universal (not quite) consistent virtual machine or the rise of rapid full stack deployments requiring metrics and monitoring.

One thing that Java did manage though was widespread adoption amongst university faculties, businesses of all sizes and in the open source community, this was mostly due to Sun and IBM's backing early on and the advent of the OpenJDK with the open sourcing of a majority of Sun's Java Virtual Machine (JVM) and Java Development Kit (JDK).

With this adoption came libraries, lots of libraries, the [apache foundation][apache] is the guardian of many of the most widely used and popular Java projects; Tomcat Application Server, httpd web server, AXIS (a SOAP web services package) and commons utilities to name a few. As time progressed many libraries and frameworks emerged (see the hugely popular [spring][spring] framework) to solve problems or use cases that Java as a language could not, these were produced by this vibrant community of companies and enthusiasts. 

In this post I will run through a few tools I use to help generate a maven site full of information about the quality of my code, test coverage and history.

In a later post I'll cover frameworks and libraries.

## Maven site generation
Maven site generation is a great part of the maven lifecycle that enables a site to be generated for your project, it is useful for hosting all sorts of facts and information about your project gleaned through the build lifecycle.
* [Dependency check][depcheck] - OWASP plugin, include link
* [Cobertura][cobertura] - code coverage, can be broken down by line coverage and branch coverage.
I personally find branch coverage to be the more useful metric as I'm not fussed if someone doesn't cover a simple **get** or **set** call on a Java bean. I'm more concerned if someone isn't covering both sides of a decision / branch in the code since this has a real impact on the behaviour of a program.
Surefire - unit test runner, generates useful reports. I get suspicious when I see any tests that are being **@Ignore**d, if the test is genuinely no longer useful or valid then *please delete it!* don't leave it hanging around causing a smell. Otherwise I will consider it to be  
* [Findbugs][findbugs] - an excellent static analysis tool for logical error and bugs, sadly it seems to be a bit [dead in the water](https://news.ycombinator.com/item?id=12885549) at the moment, although the maintainer has finally made contact.
* [pmd plugin][pmd] - is another static code analysis tool that looks for copy and paste errors, cyclomatic complexity, unused variables, dead code and other semantic errors.   
* [Checkstyle][checkstyle] - Code formatting tool to help enforce coding standards
* [change log plugin][changelog] - used in conjunction with the source control management (SCM) settings to generate a changelog based on commit messages and diffs.
* [surefire test reports][surefire] - this plugin will parse the test result XML files from your build phase and generates a web page on which you can view which tests pass or fail and those which are ignored, presenting you with a visual cue on where in particular your build is failing.
* [project info reports][projectinfo] presents a one stop place for information on your project; where your issue tracker is, who works on your project, what your source control information is (branch, tag, trunk etc), dependency convergence, distribution management (e.g. maven central, artifactory, snapshot and release version locations etc) and 
dependencies being used.

[jscountdown]:			http://www.isaacchansky.me/days-since-last-new-js-framework/
[apache]:				http://www.apache.org
[spring]:				http://www.spring.io

[depcheck]:				https://www.owasp.org/index.php/OWASP_Dependency_Check
[cobertura]:			https://cobertura.github.io/cobertura/
[findbugs]:				http://findbugs.sourceforge.net/
[pmd]:					https://pmd.github.io/
[checkstyle]:			http://checkstyle.sourceforge.net/
[changelog]:			https://maven.apache.org/plugins/maven-changelog-plugin/
[surefire]:				https://maven.apache.org/surefire/maven-surefire-report-plugin/
[projectinfo]:			https://maven.apache.org/plugins/maven-project-info-reports-plugin/
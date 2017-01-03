---
layout: post
title:  "The project baseline"
date: 2014-12-15
categories: java project-management
---
Some of the charges levelled at Java development are that it *requires too much setup* or *you cannot get started quickly* when compared to newer languages such as Ruby with its rails framework or Javascript with its numerous frameworks for every need (so many in fact that there is a [web site][jscountdown] to track the length of time since the birth of the last framework). 

I believe these are fair charges, Java was designed long before web 2.0 or the agile methodology, the architects could not foresee how the industry could change. They did however build a language that removed any need for machine specific compilation and brought object oriented concepts to the mainstream. Little did they realise that Javascript would arrive using the browser as a (nearly) universal (not quite) consistent virtual machine or the rise of rapid full stack deployments requiring metrics and monitoring.

One thing that Java did manage though was widespread adoption amongst university faculties, businesses of all sizes and in the open source community, this was mostly due to Sun and IBM's backing early on and the advent of the OpenJDK with the open sourcing of a majority of Sun's Java Virtual Machine (JVM) and Java Development Kit (JDK).

With this adoption came libraries, lots of libraries, the [apache foundation][apache] is the guardian of many of the most widely used and popular Java projects; Tomcat Application Server, AXIS (a SOAP web services package) and commons utilities to name a few. As time progressed many libraries and frameworks emerged (see the hugely popular [spring][spring]framework) to solve problems or use cases that Java as a language could not, these were produced by this vibrant community of companies and enthusiasts. 

Below I will run through a few tools, frameworks and libraries that I find incredibly useful when creating a Java project; either a big project or a hobby. I incorporate these into a maven archetype project so that I have a source of preconfigured tools, frameworks and libraries at project start.

## Toolset
## Maven
Maven is a build tool that now encompasses many responsibilities, whether this is a good thing or a bad thing I'll leave this discussion for another time.  
Where it excels is simplifying the build process, be it creation of a **.jar** or a **.war** file and managing the project's dependencies during both development and building of the project artifact. Instead of each project requiring it's dependencies (libraries or frameworks) to be contained within (taking up space on the version control system, slowing down checkouts) it will contain the references within an xml file. The dependencies are then managed in a central repository on the local machine, this reduces project size and allows for easy library reuse and upgrade. 

### Maven site generation
[Cargo][cargo] - deployment
[Dependency check][depcheck] - OWASP plugin, include link
[Cobertura][cobertura] - code coverage, can be broken down by line coverage and branch coverage.
I personally find branch coverage to be the more useful metric as I'm not fussed if someone doesn't cover a simple **get** or **set** call on a Java bean. I'm more concerned if someone isn't covering both sides of a decision / branch in the code since this has a real impact on the behaviour of a program.
Surefire - unit test runner, generates useful reports. I get suspicious when I see any tests that are being **@Ignore**d, if the test is genuinely no longer useful or valid then *please delete it!* don't leave it hanging around causing a smell. Otherwise I will consider it to be  
[Findbugs][findbugs] - an excellent static analysis tool, sadly it seems to be a bit [dead in the water](https://news.ycombinator.com/item?id=12885549) at the moment, although the maintainer has finally made contact.  
[Checkstyle][checkstyle] - Code formatting tool to help enforce coding standards
[editorconfig][editorconfig] - provides some crossover with checkstyle but has more use with helping to standardise cross systems quirks such as line endings and tab spacing, has very good editor support.    
Mock framework - [Mockito][mockito], I believe if you require Powermock for static mocking then you've done something wrong.
Logging Facade - [SLF4J][slf4j], makes excellent use of string placeholders for efficiency and allows for seamless switching out of logging backends from log4j to logback.  
Metrics framework - requires spring but still useful.
Java versioning - Java 7 at the very least
Logging Framework - 

##Tomcat specific##
Memory settings
 * Java garbage collection logging
 * Perm gen size (due to spring-tomcat-cglib issues)
 * Jconsole
 * SSL logging
Connection settings

[jscountdown]:			http://www.isaachansky.me/days-since-last-new-js-framework/
[spring]:				http://www.spring.io
[apache]:				http://www.apache.org
[cargo]:				https://codehaus-cargo.github.io/cargo/Maven2+plugin.html
[depcheck]:				https://www.owasp.org/index.php/OWASP_Dependency_Check
[cobertura]:			http://cobertura.github.io/cobertura/
[findbugs]:				http://findbugs.sourceforge.net/
[checkstyle]:			http://checkstyle.sourceforge.net/
[editorconfig]:			http://editorconfig.org/
[mockito]:				http://site.mockito.org/
[slf4j]:				http://www.slf4j.org/
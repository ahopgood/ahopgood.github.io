---
layout: post
title:  "The project baseline part II"
date: 2016-02-05
categories: java project-management
---
In an [earlier post](../../../2015/08/15/the-project-baseline.html) I started laying out the maven site plugins I make use of on projects to aid with quality and .

In this post I'll cover frameworks and libraries that I find incredibly useful when creating a Java project with maven; either as a big project or a hobby. I incorporate these into various maven [archetype][archetype] projects so that I have a source of preconfigured tools, frameworks and libraries at project start.

### A brief word on Maven
Maven is a build tool that now encompasses many responsibilities, whether this is a good thing or a bad thing I'll leave this discussion for another time.  
Where it excels is simplifying the build process, be it creation of a **.jar** (java archive) or a **.war** (web archive) file and managing the project's dependencies during both development and building of the project artifact (the .war or .jar file). Instead of each project requiring its dependencies (in other words the libraries or frameworks) to be contained within (taking up space on the version control system and slowing down checkouts) it will contain the references within an xml file. The dependencies are then managed in a central repository on the local machine, this reduces project size and allows for easy library reuse and upgrade. 

### Maven plugins
Here are a few plugins and dependencies I regularly make use of:  
* [license maven plugin][license] - incredibly useful for automatically generating a license header within your source code in a single maven command, can also be used to clean up old licenses or incorrectly formatted ones.
* [Cargo][cargo] - deployment plugin allowing for deployments to remote running servers, e.g. tomcat, jetty etc. In this way you can build and deploy with a single maven command to your environments.
* [editorconfig][editorconfig] - provides some crossover with checkstyle (mentioned later) but has more use with helping to standardise cross system (*nix, Windows etc) quirks such as line endings and tab spacing, it also has very good editor support.    
* [Mockito][mockito] - a Java mock framework providing the ability to not only mock expected objects but also throw exceptions and the ability to perform argument capture, no support for mocking static classes though (I believe if you require Powermock for static mocking then you've done something wrong).
* [SLF4J][slf4j] - a logging facade, makes excellent use of string placeholders for evaluation efficiency. Typically when the logging level isn't set appropriately the calls on the logger's log method (e.g. `logger.debug()`, `logger.warn()` etc) still result in the log message being evaluated (i.e. string concatenation). SLF4J's placeholders remove the need to perform if-then checks on the `logger.isDebugEnabled()` method to prevent this log message evaluation and in the process remove lots of boilerplate code. It allows for seamless switching out of logging backends from log4j to logback too.  
* [spring][spring] - the spring framework is **huge** here are a few of the regular modules I use:
	* **Spring Dependency Injection (DI)** - A central place to wire up your implementations to your interfaces, after all you are programming to interfaces and building via composition instead of inheritance right? The downside is that historically this has always been done via XML which means you rely more on find/search mechanisms that on using the compiler to find out which implementation of an interface is being used.
	* **Spring Security** - has good documentation and if using it for defaults then is incredibly quick out of the box to get a basic login page going. You will lean heavily on the documentation though if wish to implement more bespoke aspects in the authentication chain yourself. 
	* **Spring Object Relational Mapping (ORM)** - this gets used heavily with Hibernate to manage transactions and help ensure you aren't loading an entire dependent object tree via the relational aspect of the data modelling.  
	* **Spring Model View Controller (MVC)** - I use this a lot less these days as I use AJAX with Json a lot more but Spring MVC certainly has a solid structure and is clean to use.
	* **Spring Aspect Orientated Programming (AOP)** - this is an amazingly powerful concept but with this power comes a loss of visibility. Your integrated development environment cannot help you now as the magic of AOP only happens at runtime. Again this is configured in XML so you need to rely on the find/search functionality to find the metaphorical thread to pull in order to see what code is being executed, where it is being executed and when. You select a method within a class to add a *pointcut* to, then you decide when you want your code to execute; before or after said method or both? As this is not explicitly declared in the source code for the class (it uses DI, proxying and annotations) it does not muddy your class with extra code. There are some scenarios (known as cross cutting concerns) where this is very useful, think logging or stats. Needless to say though this could form a blog post of its own, who knows I might get around to that one day.
* [flyway][flyway] - helps make database schema migration a bit easier, doesn't do rollbacks but I'd rather have it than nothing, although I've heard good things about liquibase so may look into that in future too.
* [jersey][jersey] - **the** reference for RESTful web services (JAX-RS) in Java, I'm not a huge fan of the DI mechanism but perhaps it is a grower. The annotations for media types, meta-data and construction of sensible API urls is awesome. 
* [dropwizard][dropwizard] - takes the benefits of jersey and bundles them with other excellent libraries (Jetty, Jackson, Metrics, Guava) at fixed versions to ensure compatibility, great stuff. Not so great if you go off trail though as changing the version of one library can bring the whole thing crashing down

[archetype]:			https://maven.apache.org/guides/introduction/introduction-to-archetypes.html
[license]:				https://code.mycila.com/license-maven-plugin/
[cargo]:				https://codehaus-cargo.github.io/cargo/Maven2+plugin.html
[editorconfig]:			https://editorconfig.org/			
[mockito]:				https://site.mockito.org/
[slf4j]:				https://www.slf4j.org/
[spring]:				https://www.spring.io
[flyway]:				https://flywaydb.org/
[jersey]:				https://jersey.java.net/
[dropwizard]:			http://www.dropwizard.io/1.0.5/docs/
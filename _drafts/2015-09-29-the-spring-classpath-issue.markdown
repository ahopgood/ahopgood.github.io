---
layout: post
title:  "The Spring Classpath Resource wars"
date: 2015-09-29
categories: java spring maven
---

Spring has a very useful class called [ClassPathResource][ClassPathResource] that can be used to load resources from the local classpath.

Recently I attempted an upgrade from Java 6 and Tomcat 6 to the pairing of Java 7 and Tomcat 7 due to the latter products having been stable for many years now and their predecessors being end of life (EOL).

The project in question is a multi pom maven project with the following structure:  
    
	parent module - pom.xml, site.xml
	|    
    \_Child module 1 - pom.xml
    |	- src/main/java
    |	- src/main/resources
    \_Child module 2 - pom.xml
    	- src/main/java
    	- src/main/resources
        
Now the parent module has no code or resources, all it has is the site.xml and pom.xml in it, the child module 1 is that project that get packaged into the distributable war file. Child project 2 is a dependency of child project 1. The resources of project 1 are stored in the WEB-INF/ folder and the classes are packaged into a war file within the WEB-INF/libs folder.

With Java 6 we could specify a resource using the **ClassPathResource (classpath:filename)** type in a Spring xml config file. This would load said resource without issue from the class path. In Java 7 this no longer seems to be the case.

After doing some investigation into the ClassPathResource class I spotted the following snippet in the [JavaDoc][ClasspathResource]. 

> Supports resolution as java.io.File if the class path resource resides in the file system, but not for resources in a JAR.

It would seem that the ClassPathResource was never designed to work from within **.war** / **.jar** files. Only by sheer luck did this arrangement work with Java 6.

[ClassPathResource]: http://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/core/io/ClassPathResource.html
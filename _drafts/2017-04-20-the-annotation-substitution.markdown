---
layout: post
title:  "The Annotation Substitution"
date: 2017-04-20
categories: Java Hibernate Annotations
---

The Spring and Hibernate frameworks both provide annotations to help with dependency injection and database persistence respectively. The idea of using annotations is that you don't spoil your Java beans with framework specific code, instead your Java bean remains just so with only getters and setters for the fields that it encapsulates. 

This is generally a "good thing" except you are pushing the problem to the periphery, now you have **framework specific** annotations all over your Java beans which inhibit you moving to other frameworks. 

The [JSR-330][#JSR-330] specification (a.k.a. javax-inject) provides a solution in the form of standardised cross-framework annotations. Now you can switch between DI frameworks without having to rewrite any of your beans; Spring to Guice and vice versa.  

Hibernate has a similar set of annotations to allow for persistence and validation of elements. To overcome this framework specific issue we have another JSR to the rescue this time it is [JSR-317][JSR-317] also known as the Java Persistence API (JPA).   

Below I've detailed some framework specific annotations and their javax counterparts that I've found useful:  

|Spring Annotation|JSR-330 Annotation|What they do|
|----|----|----|
|@Autowired|@Inject| Used by dependency injection frameworks to mark an *interface* for injection with an implementation from the current context. Can be set on a setter method or field|
|@Qualifier|@Named| Used on setter parameters and/or on fields with @Autowired/@Inject to specify a **specific** named implementation to inject |
|@Component|@Named|  |
|@Identifier|||
||||

|Hibernate Annotation|Persistence Annotation|What they do|
|----|----|----|
||@NotNull| A validation annotation to prevent null collections or values being used|
|@NotEmpty|| A validation annotation for ensuring that strings, collections or arrays are not null or empty|
|@Identifier|||
||||

The [JSR-339](#JSR-339) spec also known as the Java API for RESTful Web Services provides annotations that are portable between the Spring framework and the Jersey/Dropwizard framework.
|Spring Parameter|JSR-339|What they do|
|@RequestMapping|@Path||
|@RequestMapping(method=GET)|@GET||
|@RequestMapping(method=PUT)|@PUT||
|@RequestMapping(method=POST)|@POST||
|@RequestMapping(method=DELETE)|@DELETE||
||@HEAD||
||@Produces||
||@Consumes||
|@RequestParam|@QueryParam|Allow the method parameter to be used in a GET request as a parameter, allows for optional name mapping ("") so the method parameter can be named differently to the query parameter|
||@PathParam||


[JSR-330]:	https://github.com/javax-inject/javax-inject
[JSR-317]:	https://docs.oracle.com/javaee/7/api/javax/persistence/package-summary.html
[JSR-339]:	https://jcp.org/en/jsr/detail?id=339
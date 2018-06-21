---
layout: post
title:  "Java Annotations"
date: 2017-08-05
categories: Java
---

* [How to create an annotation](#creating)
* [Annotating with our new annotation](#annotating)
* [Processing our annotation](#processing)

Java annotations are very versatile and allow plain old Java objects (POJOs) to be enriched with useful meta-data that can change or add behaviour without requiring you to add logic to your POJOs.  
Until recently I've made do with using annotations provided by the JDK (e.g. @Inject) or by frameworks such as Spring (e.g. @Autowired) so haven't needed to create my own before.  
Usually the [type-safe config][type-safe-config] library and Spring Boot both provide functionality for populating properties from numerous sources such as files (.conf and .properties), the Java System Properties or Environmental Variables but it occurred to me that as an exercise I could write my own annotation to populate fields from Java System Properties. 

<a name="creating"></a>
### How to create an annotation
To create an annotation you need to create an interface class with a special `@interface` declaration.

You then specify the fields that can be set within your annotation:
```
String value() default "uninitialised";
String[] reviewers();
```   
These are called *annotation type element* declarations, you can specify a **default** value but this is optional.  

There two other annotations applied to this interface at the class level that will influence how your new annotation class can be used:
* [RetentionType][RetentionType] specifies how long the annotation is retained for, values can be: Source (i.e. the annotation is discarded by the compiler), Class (recorded in the class file but discarded at run time), Runtime (retained by the VM at run time and can be read reflectively).
* [TargetType][TargetType] specifies what element type your annotation can apply to: Type, Field, Method, Parameter, Constructor, Local Variable, Annotation Type and Package. Type Parameter and Type Use are new with Java 1.8

With this information we can create our simple annotation:
```
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface SystemProperty {
    String value();
}
```

<a name="annotating"></a>
### Annotating with our new annotation
Now we have an annotation we can annotate a field with it:
```
class myClass {
	@SystemProperty("cheese.type")
	private String cheese;
}
```
Next we need to decide **what** to do when we encounter our annotation, we've set the retention policy to runtime so our annotation will persist past compilation and we've annotated a field with it as per our target element type.  
These facts mean we should be able to use reflection to inspect the field at runtime and assign a value to it that matches a system property called `cheese.type`

<a name="processing"></a> 
### Processing our annotation
Using reflection we can process the class's declared fields for the object we have annotated.  
For each field we encounter we can extract an annotation class (if it is present) and can then inspect its **value**. 
This value can be used as you want; perhaps to assist in performing dependency injection or as per the example below to populate the object's field with a Java System Property with the same name as our annotation's value field:    

```
public void processSystemProperties() throws IllegalAccessException {
	for (Field field : this.getClass().getDeclaredFields()){
        SystemProperty property = field.getAnnotation(SystemProperty.class);
        if ( null != property ){
            String propertyValue = System.getProperty(property.value());
            field.set(this, propertyValue);
        }
    }
}
```

[type-safe-config]:	https://github.com/lightbend/config
[RetentionType]: 	https://docs.oracle.com/javase/8/docs/api/java/lang/annotation/Retention.html
[TargetType]: 		https://docs.oracle.com/javase/8/docs/api/java/lang/annotation/Target.html
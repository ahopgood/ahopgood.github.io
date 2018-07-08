---
layout: post
title:  "Spring Boot @ControllerAdvice doesn't take its own advice"
date: 2017-09-25
categories: Spring-boot
---
I recently ran into some puzzling behaviour concerning Spring's [`@ControllerAdvice`][ControllerAdvice] annotations where the `assignableType = {}` value of the annotation wasn't being honoured.

First a bit of background on the `@ControllerAdvice` annotation.  
When you create a series of either standard MVC controllers (`@Controller`) or REST controllers (`@RestController`) you can use the `@ControllerAdvice` to add cross cutting behaviour to your controllers without having to modify the code of every controller.
This works in a similar way to the [`@ExceptionHandler`][ExceptionHandler] annotation where the class you create will handle exceptions for all classes.

The class you annotate with `@ControllerAdvice` can extend a series of classes that come with some common behaviour:
* [`ResponseBodyAdvice`][ResponseBodyAdvice] will allow you to modify a response body before it is written
* [`RequestBodyAdvice`][RequestBodyAdvice] will allow you to modify a request body before it is written.

The `ResponseBodyAdvice` interface provides the ability to implement the follow methods:
* `boolean supports (MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType)` - allows you to limit the methods  this advice will apply to.
* `Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType, Class<? extends HttpMessageConverter<?>> selectedConverterType, ServerHttpRequest request, ServerHttpResponse response)` - allows for access the response (incl headers), the request and the entity body.


## The issue
Most of our REST controllers require a set of common headers to be set when we send a response entity. The most straightforward way to do this was to create a class called `CommonHeadersBodyAdvice` for setting these headers and then set the `@ControllerAdvice` annotation on this class.  

There was a scenario where these common headers didn't need to apply, having noticed that our exception handler class was able to limit the classes it applied to by using the `assignableType` value:
```
@ControllerAdvice(assignableTypes = {Controller1.class, Controller2.class})
```
I figured that I could do the same with our `SpecificHeaderBodyAdvice` class sadly when applied this made no difference and our `CommonHeaderBodyAdvice` continued to set headers I did not want.

I even attempted to restrict the classes that the `CommonHeaderBodyAdvice` applied against but every time I included the `SpecificHeaderBodyAdvice` at the same time it would not run against my desired class, instead I'd get the common headers.

## Solution
Ordering is the only way I was able to get my BodyAdvice to work. By allowing the `CommonHeadersBodyAdvice` to be actioned first using the [`@Order(0)`][Order] annotation then setting `@Order(1)` on the `SpecificHeaderBodyAdvice` I was able to ensure this advice would be executed afterwards.  

Unfortunately though this impacted **every** controller so I needed to limit how the `SpecificHeaderBodyAdvice` was applied, this is where the `supports` method came into play:  
```
public boolean supports(MethodParameter methodParameter, Class<? extends HttpMessageConverter<?>> converterType) {
        return SpecificController.class == methodParameter.getContainingClass();
}
```
The above example shows how I was able to limit my bespoke controller advice to a specific controller without using the `@ControllerAdvice = { assignableType = { SpecificController.class })` call which I had identified as not working as expected earlier.

## Conclusion
Whilst this "solution" works, I am unhappy about relying on the `@Order` annotation to help enforce behaviour as it isn't necessarily clear how the ordering will work on a complex code base. It would be quite easy for someone else to include a new `@ControllerAdvice` class with or without ordering that could introduce unintentional side effects since there isn't an easy single source of truth for the evaluation of execution ordering except to grep through the whole codebase.  

[ControllerAdvice]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ControllerAdvice.html
[ExceptionHandler]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ExceptionHandler.html
[ResponseBodyAdvice]: https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/web/servlet/mvc/method/annotation/ResponseBodyAdvice.html
[RequestBodyAdvice]: https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/web/servlet/mvc/method/annotation/RequestBodyAdvice.html
[Order]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/annotation/Order.html
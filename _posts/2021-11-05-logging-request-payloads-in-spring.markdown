---
layout: post
title:  "Logging Request Payloads in Spring"
date: 2021-11-05
categories: logging spring
---

## The problem
The Spring framework provides excellent support for building REST endpoints and I've used it in many previous jobs.  
One aspect where I've found it to be lacking is in observing the contents of a REST payload (POST, PUT, PATCH) where the _contents_ of the request aren't easy to inspect.  
Due to the way Spring will use the [Jackson][Jackson] framework to deserialise JSON into an object, it can fail in one of two ways (that I've experienced so far) based on how it is configured; it can be _strict_ and fail if the input JSON doesn't match the Object it is trying to deserialise into **or** it will be _lenient_ and will discard the fields it cannot match to fields in the object.  
When these sorts of failures happen you really need to know what the raw payload was **before** Spring started using Jackson to process it.  

So what's a dev to do?  
Try logging the payload before it gets processed right?  

Like in a previous blog post about [Testing MDC Logging][Testing MDC Logging] we could make use of a Spring [HandlerInterceptorAdapter][HandlerInterceptorAdapter] to intercept the HttpServletRequest using the `preHandle()` method.  
Welllllll, the problem encountered here is that once you attempt to call `readBody()` on the HttpServletRequest it will close the input stream making it unreadable for the controller processing the body later on in the application.  
That's not a good side effect, I mean we get the logging but then our application will fail.  

## A Solution
As we want our logging to be purely **observational** and not to modify our flow of control or any of our objects, having the Input Stream closed before our business logic can use it is **not** a good outcome.  

However Spring provides a [RequestBodyAdviceAdapter][RequestBodyAdviceAdapter] that implements the [RequestBodyAdvice][RequestBodyAdvice] interface which provide the following useful methods in execution order:
1. `supports()`
	* Used to determine if this advice applies to request based the combination of method (Http verb), Type and Converter type.
2. `beforeBodyRead()`
	* Called before the body has been read and converted
	* `handleEmptyBody()` (conditional execution)
		* Called second in the case where the body is empty 
		* Is also the last call as it short-circuits the after body read method since there is no body
3. `afterBodyRead()`
	* Called after the body has been read and converted into an Object but **before** is has been processed by other handlers such as a Spring `@Controller` or `@RestController`.

So the methods that are of use to us in our situation are the `supports()` and `afterBodyRead()`.  
In our `supports()` implementation we want to support Http verbs that may have payloads; `PUT`, `POST` and `PATCH`, the other verbs we'll ignore by returning false:
```
    private static final List<RequestMethod> ALLOWED_METHODS = Arrays.asList(RequestMethod.PUT, RequestMethod.POST, RequestMethod.PATCH);

    @Override
    public boolean supports(MethodParameter methodParameter, Type type,
                            Class<? extends HttpMessageConverter<?>> aClass) {

        RequestMapping requestMappings = methodParameter.getMethodAnnotation(RequestMapping.class);
        if ( requestMappings == null ) {
            return false;
        }
        return Arrays.stream(requestMappings.method())
                .anyMatch(ALLOWED_METHODS::contains);
    }
``` 

Next we'll implement our `afterBodyRead()` method so we can access the payload after it has been converted into an Object.  
It is important to remember to **return the body** in the method so that subsequent interceptors or controllers can access the payload.  
```

    @Override
    public Object afterBodyRead(Object body,
                                HttpInputMessage inputMessage,
                                MethodParameter parameter,
                                Type targetType,
                                Class<? extends HttpMessageConverter<?>> converterType) {
        LOGGER.info("{}", body);
        return body;
    }
```

## Don't forget security
Finally let's not forget that what we've achieved so far is to log the body of an incoming HttpServletRequest blindly **without** any sanitisation.    
Why might trusting this content be a bad idea?  
Well a malicious actor (I mean a hacker here not a disgruntled thespian) can manipulate a request's body to print out misleading content.  
Why would they do this?  
Let's say they've caused an error that could get flagged up in your monitoring as a by-product of doing something naughty. 
They could insert either a **C**arriage **R**eturn (`\r`) or **L**ine **F**eed (`\n`) character into the request followed by a copy of another log message, perhaps one indicating another error or cause.  
In this way they can misdirect or hide the error they've forced or they could try to hide their malicious request input.    
This [Log Forgery][Log Forgery] is one known impact of [CRLF][CRLF] Injection, follow the links for some OWASP information about this.     

Ensure you sanitise content before logging by removing Carriage Return or Line Feed characters to mitigate this.  


```
...
        LOGGER.info("{}", sanitise(body.toString()));
        return body;
    }

    private String sanitise(String input) {
        return input.replace("\n","").replace("\r","");
    }
```

## Summary
So we now have:
* Captured the body of inbound Http requests
* Logged these requests 
* Sanitised them to prevent log obvious log forgery attempts
* **Not** prevented our controllers from processing the request after logging.

Here is the sample code for our `RequestBodyLogger`: 

```
@RestControllerAdvice
public class RequestBodyLogger extends RequestBodyAdviceAdapter {

    private static final Logger LOGGER = LoggerFactory.getLogger(RequestBodyLogger.class);
    private static final List<RequestMethod> ALLOWED_METHODS = Arrays.asList(RequestMethod.PUT, RequestMethod.POST, RequestMethod.PATCH);

    @Override
    public boolean supports(MethodParameter methodParameter, Type type,
                            Class<? extends HttpMessageConverter<?>> aClass) {

        RequestMapping requestMappings = methodParameter.getMethodAnnotation(RequestMapping.class);
        if ( requestMappings == null ) {
            return false;
        }
        return Arrays.stream(requestMappings.method())
                .anyMatch(ALLOWED_METHODS::contains);
    }

    @Override
    public Object afterBodyRead(Object body,
                                HttpInputMessage inputMessage,
                                MethodParameter parameter,
                                Type targetType,
                                Class<? extends HttpMessageConverter<?>> converterType) {
        LOGGER.info("{}", sanitise(body.toString()));
        return body;
    }

    private String sanitise(String input) {
        return input.replace("\n","").replace("\r","");
    }
}
```

[Testing MDC Logging]: https://blog.alexanderhopgood.com/mdc/logging/testing/2021/07/27/testing-mdc-logging.html
[HandlerInterceptorAdapter]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/servlet/handler/HandlerInterceptorAdapter.html
[RequestBodyAdviceAdapter]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/servlet/mvc/method/annotation/RequestBodyAdviceAdapter.html
[RequestBodyAdvice]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/servlet/mvc/method/annotation/RequestBodyAdvice.html
[CRLF]: https://owasp.org/www-community/vulnerabilities/CRLF_Injection
[Jackson]: https://github.com/FasterXML/jackson
[Log Forgery]: https://owasp.org/www-community/attacks/Log_Injection
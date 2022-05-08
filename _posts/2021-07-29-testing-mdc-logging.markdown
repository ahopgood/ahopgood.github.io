---
layout: post
title:  "Testing MDC Logging"
date: 2021-07-27
categories: mdc logging testing
---

All major logging frameworks support Mapped Diagnostic Context (MDC) which allows you to add important cross cutting information to your logging messages for improved debugging and diagnostics.  
Good examples of information you might want to add are:
* HTTP request identifiers - allowing you to trace a request through your system, and even correlate across multiple systems if they **all** use MDC.
* Thread name - similar to the HTTP request identifier the thread name can help you trace particular incoming requests as they progress through your system
* User identifiers (e.g. username, email or id) - these can be used to group requests together based on the user, this is useful when troubleshooting an issue in user flows
* Server identifiers - useful for spotting / aggregated errors to a specific ailing server


## Adding to the MDC
For reference the stack I'm using consists of:
* Spring boot
* Logback
* SLF4J

MDC identifiers can be added at **any** point in a request's lifecycle through a system, I wanted a way to verify that the correct information was being added at the points I expected.  

MDC values are stored in a map, they are added via static calls on the [`MDC`][MDC] object.  
In my example I am adding to the context in two places via a [HandlerInterceptorAdapter][HandlerInterceptorAdapter]:
1. **Before** the request is processed by my application code via the `preHandle` method.
	1. If an `X-Request-Id` header is present then I store that under the `http.request_id` key. If it is not present then I generate my own UUID.
	2. I store the servlet request's HTTP verb under the key `http.method`
	3. The servlet request's URI is stored under the key `http.url`
2. **After** the request is processed by my application code via the `afterCompletion` method.
	1. The response's status code is stored under the key `http.status_code`



Here is an example of an Interceptor class:
```
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

@Component
public class LoggingInterceptor extends HandlerInterceptorAdapter {

    private static final Logger LOGGER = LoggerFactory.getLogger(LoggingInterceptor.class);
    private static final String X_REQUEST_ID_HEADER = "X-Request-Id";

	protected static final REQUEST_ID = "http.request_id";
	protected static final HTTP_METHOD = "http.method";
	protected static final HTTP_URL = "http.url";
	protected static final HTTP_STATUS_CODE = "http.status_code";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        MDC.clear();
        MDC.put(REQUEST_ID, Optional.ofNullable(request.getHeader(X_REQUEST_ID_HEADER)).orElse(UUID.randomUUID().toString()));
        MDC.put(HTTP_METHOD, request.getMethod());
        MDC.put(HTTP_URL, request.getRequestURI());
        LOGGER.info(sanitise(String.format("Request received [%s] [%s]", request.getMethod(), request.getServletPath()));
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, @Nullable Exception ex) {
        int status = response.getStatus();
        MDC.put(HTTP_STATUS_CODE, valueOf(status));
        String logMessage = String.format("Returning response status code [%s]", sanitise(valueOf(status)));
        MDC.clear();
    }
}
```
This produces the following log output respectively when using a logstash encoder with the MDC values added to the appender pattern, the MDC values can be seen at the end:
> {"@timestamp":"2021-05-04T15:34:16.546Z","@version":"1","message":"Request received [PUT] [product-type]","logger_name":"...interceptor.LoggingInterceptor","thread_name":"http-nio-8080-exec-10","level":"INFO","level_value":20000,"http.request_id":"494be0d7-2a6c-4f29-860d-9c0966342fb2","http.url":"/product-type","http.method":"PUT"}

and   

> {"@timestamp":"2021-05-04T15:34:16.571Z","@version":"1","message":"Returning response status code [200]","logger_name":"...interceptor.LoggingInterceptor","thread_name":"http-nio-8080-exec-10","level":"INFO","level_value":20000,"http.request_id":"494be0d7-2a6c-4f29-860d-9c0966342fb2","http.url":"product-type","http.status_code":"200","http.method":"PUT"}

You should note the `MDC.clear()` call at the beginning and end, this ensures the context is **clean** before the next incoming request.  


## Inspecting / Testing MDC logging events

Well the first thing we need to do is to mock up the data we pull from the HttpServletRequest and HttpServletResponse to populate our MDC.  
Here we use the [mockito][mockito] framework to mock the request and response.  
```
void setupMDCRequestAndResponse() {
    when(httpServletRequest.getHeader(X_REQUEST_ID_HEADER)).thenReturn("1234-5678");
    when(httpServletRequest.getMethod()).thenReturn(HttpMethod.GET.name());
    when(httpServletRequest.getRequestURI()).thenReturn("https://dilbert.com/");
    when(httpServletResponse.getStatus()).thenReturn(HttpStatus.OK.value());
}
```
Then we will outline three test scenarios:
1. Verifying the data we set in the `preHandle` method
2. Verifying the data we set in the `afterCompletion` method
3. Finally verifying the complete end state after we invoke **both** methods

Next we need a way of being able to inspect the logging events as they occur.  
Enter stage right Logback's [`ListAppender`][ListAppender], this is an appender we can attach to our logger that functions as an-memory list of logging events that are sent to our logger.  
We want to capture the [`ILoggingEvent`][ILoggingEvent] (another Logback interface) so we can inspect them for the contents of their MDC map.  

I wrapped the logic for initialising the appender and adding it to our logger into a helper method that returns the appender.  
```
private ListAppender<ILoggingEvent> getLoggingEventAppender() {
    ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    listAppender.start();
    Logger logger = (Logger) LoggerFactory.getLogger(LoggingInterceptor.class);
    logger.addAppender(listAppender);
    return listAppender;
}
```


The events in the ListAppender and referenced in the same way you would an element in any list; by accessing the underlying list and then select elements by their index id.  

So for our three test scenarios we know we need to reference the **first** and **second** logging events (the `preHandle` and `afterCompletion` method respectively) and then inspect their MDC contents.  
For ease of use and to reduce magic strings I introduced constant integers within the test class to reference these events:
```
private static final int FIRST_LOGGING_EVENT = 0;
private static final int SECOND_LOGGING_EVENT = 1;
```

Now our tests need to setup our mock request and response data outlined previously and then call the interceptor to ensure that the MDC and logger functionality is called.  
After this we can dive into inspecting the events via the the `loggingEvents` variable (this is a reference to the appender we created).  
We access the _internal_ list representation and pull out the MDC property map based on our event id/index id.  
Then we can assert the entries based on their map key and value.  

```
@Test
void testPreHandleMDCValues() {
    setupMDCRequestAndResponse();
    interceptor.preHandle(httpServletRequest, httpServletResponse, handler);
    Map<String, String> mdcMap = loggingEvents.list.get(FIRST_LOGGING_EVENT).getMDCPropertyMap();

    assertThat(mdcMap).containsOnly (
            Map.entry(REQUEST_ID, OUR_ID),
            Map.entry(HTTP_METHOD, HttpMethod.GET.name()),
            Map.entry(HTTP_URL, DILBERT_ADDRESS)
    );
}
```
We can do the same for the `afterCompletion` method.
```
@Test
void testAfterCompletionMDCValues() {
    setupMDCRequestAndResponse();
    interceptor.afterCompletion(httpServletRequest, httpServletResponse, handler, new RuntimeException());
    Map<String, String> mdcMap = loggingEvents.list.get(FIRST_LOGGING_EVENT).getMDCPropertyMap();

    assertThat(mdcMap).containsOnly(
            Map.entry(HTTP_STATUS_CODE, "" + HttpStatus.OK.value())
    );
}
```
I also created a test that verified the MDC state after **both** methods are called to assert that the cumulative MDC values are as I expect:
```  
@Test
void testCumulativeMDCValues() {
    setupMDCRequestAndResponse();
    interceptor.preHandle(httpServletRequest, httpServletResponse, handler);
    interceptor.afterCompletion(httpServletRequest, httpServletResponse, handler, new RuntimeException());
    Map<String, String> mdcMap = loggingEvents.list.get(SECOND_LOGGING_EVENT).getMDCPropertyMap();

    assertThat(mdcMap).containsOnly(
            Map.entry(REQUEST_ID, OUR_ID),
            Map.entry(HTTP_METHOD, HttpMethod.GET.name()),
            Map.entry(HTTP_URL, DILBERT_ADDRESS),
            Map.entry(HTTP_STATUS_CODE, "" + HttpStatus.OK.value())
    );
}
```

## Conclusion
I now have the means to inspect the logging stack for the MDC contents at a particular point in time.  
I am relying on the Logback implementation to allow for inspecting of these events, ideally it would be nice to have something in SLF4J that is agnostic from the underlying logging framework.  
It might be possible to create a ListAppender for testing purposes in Log4J by implementing the [Appender](https://logging.apache.org/log4j/2.x/log4j-core/apidocs/org/apache/logging/log4j/core/Appender.html) interface.  
In this way I wouldn't be relying on logback but then I would still be relying on a particular logging implementation, I guess that is future work should I need it.  


The finished test class will look something like this:
```
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
...
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class LoggingInterceptorTest {

    private final LoggingInterceptor interceptor = new LoggingInterceptor();

    private final HttpServletRequest httpServletRequest = mock(HttpServletRequest.class);
    private final HttpServletResponse httpServletResponse = mock(HttpServletResponse.class);
    private final Object handler = new Object();

    private static final int FIRST_LOGGING_EVENT = 0;
    private static final int SECOND_LOGGING_EVENT = 1;

    private ListAppender<ILoggingEvent> loggingEvents = getLoggingEventAppender();

    private static final String X_REQUEST_ID_HEADER = "X-Request-Id";
    private static final String DILBERT_ADDRESS = "https://dilbert.com";
    private static final String OUR_ID = "our-id";

    void setupMDCRequestAndResponse() {
        when(httpServletRequest.getHeader(X_REQUEST_ID_HEADER)).thenReturn(OUR_ID);
        when(httpServletRequest.getMethod()).thenReturn(HttpMethod.GET.name());
        when(httpServletRequest.getRequestURI()).thenReturn(DILBERT_ADDRESS);
        when(httpServletResponse.getStatus()).thenReturn(HttpStatus.OK.value());
    }

    @Test
    void testPreHandleMDCValues() {
        setupMDCRequestAndResponse();
        interceptor.preHandle(httpServletRequest, httpServletResponse, handler);
        Map<String, String> mdcMap = loggingEvents.list.get(FIRST_LOGGING_EVENT).getMDCPropertyMap();

        assertThat(mdcMap).containsOnly (
                Map.entry(REQUEST_ID, OUR_ID),
                Map.entry(HTTP_METHOD, HttpMethod.GET.name()),
                Map.entry(HTTP_URL, DILBERT_ADDRESS),
        );
    }

    @Test
    void testAfterCompletionMDCValues() {
        setupMDCRequestAndResponse();
        interceptor.afterCompletion(httpServletRequest, httpServletResponse, handler, new RuntimeException());
        Map<String, String> mdcMap = loggingEvents.list.get(FIRST_LOGGING_EVENT).getMDCPropertyMap();

        assertThat(mdcMap).containsOnly(
                Map.entry(HTTP_STATUS_CODE, "" + HttpStatus.OK.value())
        );
    }

    @Test
    void testCumulativeMDCValues() {
        setupMDCRequestAndResponse();
        interceptor.preHandle(httpServletRequest, httpServletResponse, handler);
        interceptor.afterCompletion(httpServletRequest, httpServletResponse, handler, new RuntimeException());
        Map<String, String> mdcMap = loggingEvents.list.get(SECOND_LOGGING_EVENT).getMDCPropertyMap();

        assertThat(mdcMap).containsOnly(
                Map.entry(REQUEST_ID, OUR_ID),
                Map.entry(HTTP_METHOD, HttpMethod.GET.name()),
                Map.entry(HTTP_URL, DILBERT_ADDRESS),
                Map.entry(HTTP_STATUS_CODE, "" + HttpStatus.OK.value())
        );
    }

    private ListAppender<ILoggingEvent> getLoggingEventAppender() {
        ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
        listAppender.start();

        // Sadly this relies on using the Logback Logger class
        Logger logger = (Logger) LoggerFactory.getLogger(LoggingInterceptor.class);
        logger.addAppender(listAppender);
        return listAppender;
    }
}
```


[HandlerInterceptorAdapter]: https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/servlet/handler/HandlerInterceptorAdapter.html
[mockito]: https://site.mockito.org/
[ListAppender]: http://logback.qos.ch/apidocs/ch/qos/logback/core/read/ListAppender.html
[ILoggingEvent]: http://logback.qos.ch/apidocs/ch/qos/logback/classic/spi/ILoggingEvent.html
[MDC]: https://www.slf4j.org/api/org/slf4j/MDC.html
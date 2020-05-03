---
layout: post
title:  "Testing Cross Origin Resource Sharing (CORS) with Karate"
date: 2019-02-11
categories: CORS Karate Security
---

Last year I came across the [Karate][karate] framework for testing RESTful APIs, it provides a cucumber style Domain Specific Language ([DSL][DSL]) geared towards REST operations and I thoroughly appreciated it.  

Typically we use cucumber tests for writing functional stories in cucumber's _Given_, _When_, _Then_ ([GWT][GWT]) synatx and then write step code to make the underlying functionality happen.  

This focus on functional aspects doesn't necessarily translate well to testing cross cutting concerns such as Cross Origin Resource Sharing (CORS) as firstly it is clunky to massage a user story into something so technical in nature. Secondly writing the underlying web client code to match the verbal GWT steps hides much of the specifics of our test preconditions, execution and assertions.
  
The Mozilla Developer Web Docs have an excellent explanation of [CORS here][Mozilla CORS].

Using Karate enables us to clearly see the preconditions, execution and assertions in its DSL and in the CORS example we are able to create three tests:
1. A CORS preflight request
```
Scenario: Attribute Types CORS preflight
  Given url myService + '/attribute-types'
  And header Origin = allowedDomain
  And header Content-Type = 'application/json'
  And header Access-Control-Request-Method = 'GET'
  And header Access-Control-Request-Headers = 'Content-Type'
  When method OPTIONS
  Then status 200
  And match header Access-Control-Allow-Origin == allowedDomain
  And match header Vary contains 'Origin'
```
In this request we are able to specify the **Content-Type**, **Method**, expected **Headers** and most importantly **Origin** that our actual request will use in the form of a **preflight** request.  
A successful preflight request will let a client know that the values they have submitted will be accepted by the server.   

2. A valid API request satisfying the CORS requirements returned from our first test scenario
```
Scenario: Attribute Types CORS request
  Given url myService + '/attribute-types'
  And header Origin = allowedDomain
  When method GET
  Then status 200
  And match header Access-Control-Allow-Origin == allowedDomain
  And match header Vary contains 'Origin'
  And assert response.length == 4
```
All being well thanks to our first test we can expect a `200 OK` status from the server where it has accepted our request from a different but _allowed_ Origin.  

3. An invalid API request violating the CORS requirements
```
Scenario: Attribute Types CORS invalid request
  Given url myService + '/attribute-types'
  And header Origin = restrictedDomain
  When method GET
  Then status 403
  And match responseHeaders['Vary'][0] contains 'Origin'
  And match responseHeaders['Vary'][1] contains 'Access-Control-Request-Method'
  And match responseHeaders['Vary'][2] contains 'Access-Control-Request-Headers'
```
Now despite what is technically a valid request we are receiving a `403 Forbidden` because our _Origin_ is not in the server's list of allowed origins, if we were to remove the Origin header completely we will be sending a request as if it were on the _same origin_, in other words on localhost or from the same domain.  

## Summary
The real power here is that Karate lets us specify _any_ origin we like, this in combination with variable substitution allows for this test to be structured in such as way we can run it against multiple URLs from multiple origins with various verbs. 

We can structure the tests for preflight behaviour, successful requests and forbidden requests in any way we see fit.  

I will follow up [later](/cors/karate/security/2019/04/21/karate-outline-parameters.html) on how I have chosen to make these tests more repeatable whilst maintaining rich reporting in my [cucumber reports][Cucumber Reports].  


[Karate]: https://intuit.github.io/karate/
[DSL]: https://en.wikipedia.org/wiki/Domain-specific_language
[GWT]: https://en.wikipedia.org/wiki/Given-When-Then
[Cucumber]: https://cucumber.io/
[Mozilla CORS]: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
[Cucumber Reports]: https://github.com/damianszczepanik/cucumber-reporting
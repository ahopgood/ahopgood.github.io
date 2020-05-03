---
layout: post
title:  "Karate Scenario Outline with Parameters"
date: 2019-04-21
categories: CORS Karate Security
---

One of the drawbacks of using a [`Scenario Outline`][Scenario Outline] is that the values in the `Examples` table cannot be constructed via variables. An example would be when one of your table columns contains an endpoint and you want to source the base path from a variable allowing you to change the IP address and port in a single place for all tests.  

```
* def host = localhost:8080
...
  Examples:
      | endpoint         |
	  | '#(host)/health' |

```

Currently this would not evaluate correctly within the examples block, it would simply be evaluated as text e.g. as `#(host)/health`. 

Instead you need to make use of the [Dynamic Scenario Outline][Dynamic Scenario Outline], typically this involves reading from a **static** json file. This isn't much use to us as we still cannot evaluate or construct variables.  

What we *can* do however is reference a flat json structure **within** the feature file, in this way we can still reference variables and perform string concatenation.  
```
  * def corsPreflightValues =
  """
  [
  { "verb": "GET", "endpoint": '#(host + "/attribute-types")' },
  { "verb": "GET", "endpoint": '#(host + "/attribute-types/" + attributeTypeId)' },
  { "verb": "GET", "endpoint": '#(host + "/attribute-types/" + attributeTypeId + "/attributes")' },
  { "verb": "GET", "endpoint": '#(host + "/attributes/" + attributeId)' },
  ]
  """
  Scenario Outline: CORS preflight <verb> <endpoint>
    Given url endpoint
    And header Origin = allowedDomain
    And header Content-Type = 'application/json'
    And header Access-Control-Request-Method = verb
    And header Access-Control-Request-Headers = 'Content-Type'
    When method OPTIONS
    Then status 200
    And match header Access-Control-Allow-Origin == allowedDomain
    And match header Vary contains 'Origin'

  Examples:
      | corsPreflightValues |
```
Note here that the **entire** string needs to be encapsulated in single quotes to do the variable referencing, _even_ the standard strings, which is a slightly different format to the [embedded expression][Embedded Expressions] referencing within strings you typically see.  
```

[Scenario Outline]: https://intuit.github.io/karate/#the-cucumber-way
[Dynamic Scenario Outline]: https://intuit.github.io/karate/#dynamic-scenario-outline
[Embedded Expressions]: https://intuit.github.io/karate/#embedded-expressions
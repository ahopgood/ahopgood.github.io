---
layout: post
title:  "Cucumber with null and boolean values"
date: 2025-09-13
categories: cucumber
---
* Recently I was working with Cucumber and needed to assert on some values held in a database.
* [Cucumber parameter types](https://github.com/cucumber/cucumber-expressions?tab=readme-ov-file#parameter-types) can be slightly limiting when trying to assert on parameter contents, there were two scenarios where I found the cucumber parameter types to be lacking:
  * `null` values aren't supported, for me this was a valid  case when a database value hasn't been set
  * `boolean` values, where I either wanted to assert a default or a new value had been set.
* I wanted a step definition that would allow for me to assert if a value is set and what it is set to or if it hasn't been set at all:
  * > the SAML profile database field: org_name is: ACME Industries 
  * > the SAML profile database field: secret is: null
  * > the SAML profile database field: enabled is: true
  
* This would allow me to assert if my values haven't been set in my repository/data store as well as when they **are** set, making for a unified step definition for most cases.

### Isn't this simple?
Why can't I just write three step definitions for each scenario?
* Because Cucumber identifies definitions as pattens and won't allow duplicates so each of the three scenarios above will look like this to Cucumber:
  * `the SAML profile database field: <param1> is: <param2>`
* Instead we'd have to make each description text distinct to satisfy Cucumber
* Each step would need separate but similar code to parse the field
* Nulls still wouldn't be supported

### Matching on anonymous/any values
To start with we'll use the anonymous `{}` type which matches anything. 
We can use this in a step definition like so to map to an `Object` parameter.
```
@And("the SAML profile database field: {string} is: {}")
public void checkDatabaseProfileField(String field, Object value) {
    var profile = samlProfileRepository.findByOrganisation(ORG_GUID);
    assertThat(profile).isPresent();

    assertThat(profile.get())
            .isNotNull()
            .hasFieldOrPropertyWithValue(field, value);
}
```
* This covers our first scenario
  * > the SAML profile database field: org_name is: ACME Industries
  * But fails to handle `null` or boolean values well.

### Null Values
* Next we need to add some bespoke handling for the cases where we want to assert a `null` object
```
public Object handleNull(Object nullType) {
    if (nullType instanceof String valueString) {
        if (valueString.equalsIgnoreCase("null")) {
            return null;
        }
    }
    return nullType;
}
```
* Cucumber will consider a `null` value to be an empty string which isn't useful as it could genuinely be an empty string or null, we'll not know
* Instead we can check for the string value of `"null"`
  * We will perform a type check and convert it to a string
  * We are effectively making `"null"` a reserved word in our step definition here
* We return a Java `null` type to the step definition code.
```
@And("the SAML profile database field: {string} is: {}")
public void checkDatabaseProfileField(String field, Object value) {
    value = handleNull(value);
    var profile = samlProfileRepository.findByOrganisation(ATTEST_ORG_GUID);
    assertThat(profile).isPresent();

    assertThat(profile.get())
            .isNotNull()
            .hasFieldOrPropertyWithValue(field, value);
}
```
* Now we have a chance to return a Java `null` value as the expected output
* Allowing us to assert in Java if the field is also null
* This covers our second scenario:
  * > the SAML profile database field: secret is: null

### Boolean Values
* We can also do something similar for a boolean value, by matching on the strings `"true"` and `"false"`
```
private Object handleBoolean(Object value) {
    if (value instanceof String valueString) {
        if (valueString.equalsIgnoreCase("true")
                || valueString.equalsIgnoreCase("false")
        ){
            value = Boolean.parseBoolean(valueString);
        }
    }
    return value;
}
```
* We ignore case well because just in case ;-) 
* Finally we parse the string into a boolean type
* Like with null values it will allow our later assertion to leverage the Java type system 

Now we plug this in after the null check:
```
@And("the SAML profile database field: {string} is: {}")
public void checkDatabaseProfileField(String field, Object value) {
    value = handleNull(value);
    value = handleBoolean(value);
    var profile = samlProfileRepository.findByOrganisation(ATTEST_ORG_GUID);
    assertThat(profile).isPresent();

    assertThat(profile.get())
            .isNotNull()
            .hasFieldOrPropertyWithValue(field, value);
}
```
### Conclusion
* We have a very versatile step definition 
  * Supports null values
  * Supports booleans
  * Allows us to also verify any other string or int values
  * We no longer need to write separate step definitions for each scenario 
* The trade-offs however
  * We have effectively made the string `"null"` a reserved word in our step definition
  * Also we've made `"true"` and `"false"` reserved words too

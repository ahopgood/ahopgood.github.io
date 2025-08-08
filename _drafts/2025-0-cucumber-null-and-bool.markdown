---
layout: post
title:  "Cucumber with null and boolean values"
date: 2025-0
categories: cucumber
---
* Recently I was working with Cucumber and needed to assert on some value held in a database.
* [Cucumber parameter types](https://github.com/cucumber/cucumber-expressions?tab=readme-ov-file#parameter-types) can be slightly limiting when trying to pass in parameters.
* I'd like to be able to assert values haven't been set in my repository/data store as well as when they **are** set.

There were two scenarios where I found the cucumber parameter types to be lacking: 
* `null` values, a case when a database value hasn't been set
* `boolean` values, where I either wanted to assert a default or a new value had been set.

To start with we'll use the anonymous `{}` type which matches anything. 
We can use this in a step definition like so to map to an `Object` parameter.

### Null Values
```
@And("the SAML profile database field: {string} is: {}")
public void checkDatabaseProfileField(String field, Object value) {
    value = handleBoolean(value);
    value = handleNull(value);
    var profile = samlProfileRepository.findByOrganisation(ATTEST_ORG_GUID);
    assertThat(profile).isPresent();

    assertThat(profile.get())
            .isNotNull()
            .hasFieldOrPropertyWithValue(field, value);
}
```
* Then add some bespoke handling for the cases where we want to assert a `null` object
```
/**
 * Cucumber doesn't have the concept of null values in the same way as Java
 * It will consider it a string, so we need to handle it so we can compare to null values in Java
 */
public Object handleNull(Object nullType) {
    if (nullType instanceof String valueString) {
        if (valueString.equalsIgnoreCase("null")) {
            return null;
        }
    }
    return nullType;
}
```
### Boolean Values
* We can also do the same for a boolean value
```
/**
 * Cucumber cannot handle boolean values in the same way as Java
 * It will consider it a string, so we need to handle it
 */
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

---
layout: post
title:  "The Lombok Sub-builers"
date: 2018-07-07
categories: Lombok
---

## The issue
I was working on a proof of concept I wanted to work quickly with:
* An existing JWT token object that already has the `@Builder` annotation
* I wanted to trial adding two different types of roles:
  * one based on an array of strings and
  * a more complex one based on an array of objects.
* I wanted it so that I could run a set of tests on each prototype so simply changing the class itself was unsuitable.

Typical lombok builder class declaration:
```
@Getter
@ToString
@EqualsAndHashCode
@Builder
public class JwtToken {

    @JsonProperty("sub")
    private final String subject;

    @JsonProperty("exp")
    private final Long expiry;

    @JsonInclude(Include.NON_NULL)
    @JsonProperty("iat")
    private final Long issuedAt;

    @JsonProperty("nbf")
    @JsonInclude(Include.NON_NULL)
    private final Long notBefore;

    @JsonCreator
    public JwtToken(@JsonProperty("sub") String subject,
                                  @JsonProperty("exp") Long expiry,
                                  @JsonProperty("iat") Long issuedAt,
                                  @JsonProperty("nbf") Long notBefore) {
        this.subject = subject;
        this.expiry = expiry;
        this.issuedAt = issuedAt;
        this.notBefore = notBefore;
    }
}
```
Usage to build an object:
```
JwtToken token = JwtToken.builder()
                .expiry(expiry)
                .issuedAt(issuedAt)
                .notBefore(notBefore)
                .subject(subject)
                .build();
```

## The solution for simple fields
I needed a sub-builder that would allow for me to continue to use a fluent builder **without** changing the base class whilst also supporting my **new fields**.  
I chose to _extend_ the class to introduce a new simple field and annotated the _constructor_ with a builder and also specified a _different_ name for the builder method (subbuilder in this case):
```
@Getter
@ToString
@EqualsAndHashCode
static class JwtTokenWithRoles extends JwtToken {

    @JsonInclude(Include.NON_NULL)
    @JsonProperty("roles")
    private final String[] roles;

    @Builder(builderMethodName = "subbuilder")
    @JsonCreator
    public JwtTokenWithRoles(@JsonProperty("sub") String subject,
                              @JsonProperty("exp") Long expiry,
                              @JsonProperty("iat") Long issuedAt,
                              @JsonProperty("nbf") Long notBefore,
                              @JsonProperty("roles") String[] roles) {
        super(subject, expiry, issuedAt, notBefore);
        this.roles = roles;
    }
```
My new builder can now be used via the new builder from the sub class:
```
JwtTokenWithRoles token = JwtTokenWithRoles.subbuilder()
        .expiry(expiry)
        .issuedAt(issuedAt)
        .notBefore(notBefore)
        .subject(subject)
        .roles(new String[]{"cs_ops","trader"})
        .build();
```

## The solution for objects
This time I needed to extend with a Role object, again I used a sub builder:
```
@Getter
@ToString
@EqualsAndHashCode
static class JwtTokenWithRolesObject extends JwtToken {

    @JsonInclude(Include.NON_EMPTY)
    @JsonProperty("roles")
    private final Role[] roles;

    @Builder(builderMethodName = "subbuilder")
    @JsonCreator
    public JwtTokenWithRolesObject(@JsonProperty("sub") String subject,
                                           @JsonProperty("exp") Long expiry,
                                           @JsonProperty("iat") Long issuedAt,
                                           @JsonProperty("nbf") Long notBefore,
                                           @JsonProperty("roles") Role[] roles) {
        super(subject, expiry, issuedAt, notBefore);
        this.roles = roles;
    }
}
```
For the more complex **Role** object I again used lombok's `Builder`, `Getter`, `ToString` and `EqualsAndHashCode` annotations.
```
@Getter
@ToString
@EqualsAndHashCode
@Builder
static class Role {

    @JsonProperty("role")
    private final String roleName;
    @JsonProperty("ctx")
    private final String[] contextList;

    @JsonCreator
    public Role(@JsonProperty("role") String roleName,
                @JsonProperty("ctx") String[] contextList) {
        this.roleName = roleName;
        this.contextList = contextList;
    }
}
```
This resulted in the following construction using the fluent builders:

```
JwtTokenWithRolesObject token = JwtTokenWithRolesObject.subbuilder()
        .expiry(expiry)
        .issuedAt(issuedAt)
        .notBefore(notBefore)
        .subject(subject)
        .roles(new Role[]{
                Role.builder().roleName("support").contextList(new String[]{"gb"}).build(),
                Role.builder().roleName("admin").contextList(new String[]{"gb", "fr"}).build()
        })
        .build();
```

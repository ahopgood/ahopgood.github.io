---
layout: post
title:  "Springfox Swagger"
date: 2022-02-01
categories: Spring Swagger API
---
There have been a few use cases in Springfox Swagger that I've found to be not-so-obvious to achieve and this was despite me knowing the outcome I was aiming for, so I'm popping down some notes here for future reference and to help anyone else:
* Headers - hiding a header 
* Headers - descriptions for headers
* Tags - how to group similar endpoints together


## Headers
Here is an example of a typical Spring Controller method that includes a `@RequestHeader` parameter so that the header can be processed/inspected:   
```
@PostMapping('/request')
public ResponseEntity handleRequest(@RequestHeader() String origins){
	if (!origins.contains("mydomain.com")) {
		return ResponseEntity.status(HttpStatus.UNAUTHORIZED);
	}
}
```

### Hiding a header
There may be occasions where you use a header but don't want its usage documented in Swagger, for example it might be the `Origins` header for performing CORS checks and you don't need an end user to provide this header as it should be set by the browser.  
  
A swagger header can be hidden if the `hidden = true` value is set in the ApiParam annotation:
`@ApiParam(name = "Origins", hidden = true)`  
  
### Adding Descriptions to a header
There are instances where you want to add some description to a header's documentation to provide more context.  
To add swagger descriptions to headers, in this case "Basic Auth" can be done using the `value` field:
`@ApiParam(name = "Authorization", value = "Basic Auth"` on the parameter level  
or  
`@ApiImplicitParam(name = "Authorization", value = "Basic Auth", type="header"` on the method level  


## Tags
Tags are a great way to group the endpoints in your Controllers together by their purpose.  

Tags have the following properties:
* Name - this is both the heading for the grouping and the means of referencing your tags 
* Description - a sub-heading providing more detail on your tag/grouping
* Priority (optional) - an integer to enforce ordering should you desire it

The Controller implementation is simply a _class level_ annotation: `@Api(tags = "Attributes")`  


Then in your Springfox Docket configuration you add your array of tag objects, in this example it is a conditional Bean-style configuration:
```
@Bean
@ConditionalOnProperty("swagger.enabled")
public Docket prdmgtApi(@Value("${info.app.version}") String version) {
    return new Docket(DocumentationType.SWAGGER_2)
            .tags(attributesSwaggerTag(), productSwaggerTag(), productTypeSwaggerTag(), variantsSwaggerTag(), inventorySwaggerTag())
            .select()
            .apis(RequestHandlerSelectors.withClassAnnotation(RestController.class))
            .paths(PathSelectors.any())
            .build()
            .apiInfo(new ApiInfoBuilder()
                    .title("Product Management Data API")
                    .description("An API for Product Information Management (PIM) data.")
                    .version(version)
                    .build())
            .pathMapping("/")
            .genericModelSubstitutes(ResponseEntity.class);
}
```
Here is an example of a tags method referenced in the above Docket code, it provides a Tag with name and description fields set:
```
private Tag attributesSwaggerTag() {
    return new Tag("Attributes", "Attributes describe the characteristics of products. The attribute family is made up of Attribute Types -> Attributes -> Attribute Values");
}

```
These tags then get displayed as headers for collections of endpoints (provided each Controller has the **correct** tag name in their API annotation mentioned previously).  
Here's an example of tag in action:  

![Swagger tag in action image](/assets/springfox-tags.png)


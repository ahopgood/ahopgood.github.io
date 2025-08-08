---
layout: post
title:  "Cucumber with Multipart File uploads"
date: 2025-0
categories: cucumber spring
---
Recently I had to test an API contract involving a [Multipart File form submission](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/POST#multipart_form_submission).  
The testing framework of choice in this case was [Cucumber](https://cucumber.io/docs/installation/java/).  


## Cucumber test background
* We have a context that is a ThreadLocal declared like so:
```
public static final ThreadLocal<TestContext> context = ThreadLocal.withInitial(TestContext::new);
```
* This uses the class `TestContext` to hold any test fixtures between our `@Given`, `@When` and `@Then` steps.  
* The TestContext is a lombok'd class for holding data
* To this I added the `formData` field in the form of a MultiValueMap which is keyed on string values and holds objects. 
```
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.util.MultiValueMap;
import org.testcontainers.shaded.org.checkerframework.checker.nullness.qual.Nullable;

import java.util.LinkedHashMap;

@Data
@NoArgsConstructor
public class TestContext {
  private ResponseEntity<?> response;

  public void setResponse(ResponseEntity<?> response) {
    this.response = response;
    if (this.response.getBody() != null) {
      if (this.response.getBody() instanceof LinkedHashMap<?, ?> b) {
        this.body = b;
      }
    }
  }

  @Nullable
  private LinkedHashMap<?, ?> body;

  @Nullable
  private MultiValueMap<String, Object> formData;
}
```

## Multipart Formdata
* For some background I had to refresh my memory of what a Multipart form body looks like when it is constructed:
* https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/POST#multipart_form_submission
* Each file uploaded requires:
	* `Content-Disposition` header with the following fields (see [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Disposition#as_a_header_for_a_multipart_body) for more info):
		* `formdata;`
		* `name=<parameter_name>'`
		* `filename=<filename>`
		* e.g `Content-Disposition: formdata; name=myxml; filename=myxml.xml`
	* `Content-Type` header for your file content type e.g. `application/json` or `application/xml`
	* In the form data we need the file bytes need to be set under the `<parameter_name>`

## Using Spring's MockMultipartFile
To put this together we used Spring's [MockMultipartFile](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/mock/web/MockMultipartFile.html) to hold file information.

The steps to combine this into a request are:
1. Retrieve our existing form data from our context, this represents the `body` of the form we're going to be submitting.
2. Construct the `MockMultipartFile` with our filename, parameter name, content-type and fileContent.
3. Create the headers for our file upload
   1. `Content-Disposition` based on the composition outlined prior
      1. `name` is the parameter name we're storing the file under
      2. `filename` is the original name of the file prior to upload   
   2. `Content-Type` to describe the content type of our file.
4. Finally we add everything as a Spring HttpEntity to the form data under our parameter name (same as our `name` in the content disposition header)
   1. Both our headers are added as a HttpHeaders instance
   2. The file contents are added as the `body` of the entity by retrieving the bytes from our `MockMultipartFile` 
5. We then put the form data back into our context to be used by our [RestTemplate](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/client/RestTemplate.html)

The full declared step looks as follows:
```
@And("the Multipart File: {string} with name: {string} and content: {string}")
public void setFormParameter(String parameterName, String filename, String fileContent) throws IOException {
    var formData = Optional.ofNullable(context.get().getFormData())
            .orElseGet(LinkedMultiValueMap::new);

    MockMultipartFile metadataXml = new MockMultipartFile(
            filename,
            filename, // The original filename
            "application/xml", // The content type
            fileContent.getBytes() // The content of the file
    );
    // Create entity and add to body
    var headers = new HttpHeaders();
    headers.set("Content-Disposition", String.format("form-data; name=%s; filename=%s", parameterName, metadataXml.getOriginalFilename()));
    headers.set("Content-Type", metadataXml.getContentType());

    formData.set(parameterName, new HttpEntity<>(metadataXml.getBytes(),headers));
    context.get().setFormData(formData);
}
```

## Making the request
We then have another step for submitting the data:
```
MultiValueMap<String, Object> body = Optional.ofNullable(context.get().getFormData())
        .orElseGet(LinkedMultiValueMap::new);

var httpEntity = new HttpEntity<>(body, getFileUploadHeaders());
var response = restTemplate.exchange("/saml/profile", HttpMethod.PUT, httpEntity, Object.class);
```
* `getFileUploadHeaders()` simply sets the `Content-Type` header for the whole request to `multipart/form-data`
* The [RestTemplate](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/client/RestTemplate.html) is a Spring web client we're using in our tests to fire off requests.

## Notes
It is worth noting when using the MockMultipartFile that `MockMultipartFile.getName()` is the name of the parameter **not** the name of the file, use `MockMultipartFile.getOriginalFilename()` instead.
---
layout: post
title:  "Postgres XML and Spring Boot JDBC"
date: 2025-07-23
categories: spring postgres jdbc
---

Recently I found myself wanting to leverage the `xml` datatype in postgres.  
This would delegate basic XML hygiene checks to the database simplifying my application code.  
I'm running a Spring Boot data stack with JDBC for my CRUD operations, see [https://spring.io/projects/spring-data-jdbc](https://spring.io/projects/spring-data-jdbc).  
Simplistically I made the xml field in my model a string for the xml file content and assumed that Spring would marshall this into my schema, oh boy was I wrong about that:  
```
No converter found capable of converting from type [org.postgresql.jdbc.PgSQLXML] to type [java.lang.String]
```
The above was returned when trying to insert the data. 


## Background
* I chose `xml` as the schema datatype
* `String` was used for the model

My schema:
```
ALTER TABLE organisations ADD CONSTRAINT "organisation_guid_unique" UNIQUE (guid);

CREATE TABLE organisation_saml (
   "id" uuid NOT NULL DEFAULT gen_random_uuid(),
   "login_endpoint" text NOT NULL,
   "metadata_endpoint" text DEFAULT NULL,
   "metadata_xml" xml DEFAULT NULL,
   "metadata_filename" text DEFAULT NULL,
   "organisation" uuid NOT NULL,
   "enabled" bool NOT NULL DEFAULT true,
   CONSTRAINT "organisation_saml_organisation_fkey" FOREIGN KEY ("organisation") REFERENCES organisations("guid") ON DELETE CASCADE,
   PRIMARY KEY ("id")
);

```

The model:
```
@Table(name = "some_table")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MyEntity {
    @Id
    private UUID id;

    private String metadataXml;
}
```

The Repository is a standard CRUD interface as per Spring docs [https://docs.spring.io/spring-data/relational/reference/repositories/core-concepts.html](https://docs.spring.io/spring-data/relational/reference/repositories/core-concepts.html):
```
@Repository
interface MyEntityRepository extends CrudRepository<MyEntity, UUID> {
```


## Solution 1 - Add custom converters
* Reader as per the Spring docs: [https://docs.spring.io/spring-data/relational/reference/jdbc/mapping.html#custom-converters.reader](https://docs.spring.io/spring-data/relational/reference/jdbc/mapping.html#custom-converters.reader)
```
@ReadingConverter
public class SqlXmlToStringConverter implements Converter<SQLXML, String> {
    @Override
    public XMLString convert(SQLXML source) {
        try {
            return source == null ? null : source.getString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
```
* Writer as per the Spring interface: [https://docs.spring.io/spring-data/commons/docs/current/api/org/springframework/data/convert/WritingConverter.html](https://docs.spring.io/spring-data/commons/docs/current/api/org/springframework/data/convert/WritingConverter.html)
```
@Component
@WritingConverter
public class StringToSqlXmlConverter implements Converter<String, SQLXML> {

    @Autowired
    private DataSource dataSource;


    @Override
    public SQLXML convert(String source) {
        if (source == null) return null;
        try (Connection connection = dataSource.getConnection()) {
            SQLXML sqlxml = connection.createSQLXML();
            sqlxml.setString(source);
            return sqlxml;
        } catch (Exception e) {
            throw new RuntimeException("Failed to convert String to SQLXML", e);
        }
    }
}
```
* Register my converters [https://docs.spring.io/spring-data/relational/reference/jdbc/mapping.html#jdbc.custom-converters.configuration](https://docs.spring.io/spring-data/relational/reference/jdbc/mapping.html#jdbc.custom-converters.configuration)
```
class MyJdbcConfiguration extends AbstractJdbcConfiguration {

    // …

    @Override
    protected List<?> userConverters() {
        return Arrays.asList(new SqlXmlToStringConverter(), new StringToSqlXmlConverter());
    }

}
```
So that should be it right?  
Nope!  
The issue was it started converting **every** string field into a SQLXML field, not what I wanted as this created issues for fields that are _genuinely_ strings.


## Solution 2 - The wrapper type
* I need a way to identify only the Strings I consider to hold XML data to be targeted.  
* I created a wrapper type that I can use to identify specifically the field I want to be converted to XML
```
@Data
@AllArgsConstructor
public class XMLString {
    private String xml;
}
```
* Now I updated my conversion classes to use this:
    * `public class SqlXmlToStringConverter implements Converter<SQLXML, XMLString>`
    * `public class StringToSqlXmlConverter implements Converter<XMLString, SQLXML> {`
* And made sure my model also now used `XMLString` instead of `String`

## TLDR; Use customer converters and a Wrapper type
* Spring Boot JDBC doesn't natively support conversion from string types to the `xml` type in Postgres
* You need to add custom converters `@WritingConverter` and `@ReadingConverter`
* Beware that JDBC converters are **global** so will convert every string to `xml`
* To get around this add a wrapper type such `XMLString` and update your model and converters to use this
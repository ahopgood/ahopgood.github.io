---
layout: post
title:  "Testing Golang Logging"
date: 2024-09-30
categories: golang
---

I've recently wanted to add logging to an CLI application of mine and the recent introduction of [structured logging](https://go.dev/blog/slog) in the form of the `slog` library felt like the right opportunity.

Having used an in-house variant of [logrus](https://github.com/sirupsen/logrus) in work I was not particularly familiar with Go's existing [log](https://pkg.go.dev/log) package either.

One thing that concerned me was how I'd be able to verify I've used either the [logging flags](https://pkg.go.dev/log#pkg-constants), logging levels or structured logging correctly.  

What I needed was to test the logging mechanism, coming from a Java background where this is generally a "Bad Idea"TM, I wasn't sure how sensible or wise this would be...

I needn't have worried though, using this [stackoverflow post](https://stackoverflow.com/questions/44119951/how-to-check-a-log-output-in-go-test) as inspiration I realised it was quite easy to add **any** output to the default logging mechanism!

## Testing with a buffer
* Using the `log.SetOutput(w io.Writer)` function you can set the output of the logger to write where ever you like
* In our case we'll use a byte buffer `bytes.Buffer` to capture logging output
* After submitting a message to the logger we can then read from the buffer and check the output
```
var _ = Describe("ConfigureLogger", func() {
    It("should log my message", func() {
        var buf bytes.Buffer
        log.SetOutput(&buf)
        
        slog.Info("test message")
        //2024/09/22 14:16:52 DEBUG test message

        actualLogMessage := strings.Fields(buf.String())[4:6]
        Expect(actualLogMessage).To(ContainElements("test", "message"))
    })
})
```

## Setting up for multiple tests
* Move the buffer variable declaration into a more global location for re-use
* Clear the buffer in before each test
* Set the buffer as the log output before each test


```
var _ = Describe("ConfigureLogger", func() {
    var buf bytes.Buffer
    BeforeEach(func() {
			buf.Reset()
			log.SetOutput(&buf)
    })
    It("should log my message", func() {
        var buf bytes.Buffer
        log.SetOutput(&buf)
        
        slog.Info("test message")
        //2024/09/22 14:16:52 DEBUG test message

        actualLogMessage := strings.Fields(buf.String())[4:6]
        Expect(actualLogMessage).To(ContainElements("test", "message"))
    })
})
```

## Json Handler Example
* The [JSONHandler](https://pkg.go.dev/golang.org/x/exp/slog#JSONHandler) can be used to ensure the structured logging output is written in json format
* The handler is initialised to write to our buffer `slog.NewJSONHandler(&buf, nil)`
* This handler is then used to create a new logger `slog.New(ourhandler)`
* Finally we set our logger as the default `slog.SetDefault(jsonLogger)`
* In this scenario we use a `MatchRegex` matcher from the gomega framework to ensure we have json output
  * Contained in curly braces
  * Comma separated 
  * We could go further (e.g. checking for double quotes, colons etc) but this simple pattern did the job
```
It("should log in json", func() {
	log.SetFlags(log.LstdFlags)
	jsonLogger := slog.New(slog.NewJSONHandler(&buf, nil))
	slog.SetDefault(jsonLogger)

	//{"time":"2024-09-28T12:24:21.6321533+01:00","level":"INFO","msg":"test json message"}
	slog.Info("test json message")

	fmt.Println(buf.String())

	Expect(buf.String()).To(MatchRegexp("{(.+,)*.+}"))
})
```
## Text Handler Example
* The [TextHandler](https://pkg.go.dev/golang.org/x/exp/slog#TextHandler)  can be used to output the structured logging as text
* The handler is initialised to write to our buffer `slog.NewTextHandler(&buf, nil)`
* Again the handler is then used to create a new logger `slog.New(ourhandler)`
* Just like with the other handler we set our logger as the default `slog.SetDefault(jsonLogger)`
* This time as the content is space separated I used `strings.Fields` to tokenise the output
* Then a simple `ContainElements` check to ensure the contents of our log message appeared
```
It("should log in text", func() {
	log.SetFlags(log.LstdFlags)
	textLogger := slog.New(slog.NewTextHandler(&buf, nil))
	slog.SetDefault(textLogger)

	//time=2024-09-28T12:39:58.838+01:00 level=INFO msg="test structured text message"
	slog.Info("test structured text message")

	fmt.Println(buf.String())
	actualLogMessage := strings.Fields(buf.String())[2:]
	Expect(actualLogMessage).To(ContainElements("msg=\"test", "structured", "text", "message\""))
})
```
---
layout: post
title:  "Live reloading websites with Golang"
date: 2026-08-02
categories: golang
---
I recently started a new hobby project to put my learnings around Golang web applications to practical use.  

I soon remembered one of the drawbacks of developing frontend web applications is the need to refresh the browser to see my latest changes to the web page or if I've changed my API contract.

## Live reloading the Chi Router
So how do I reload my web application server after I've made changes?

Enter `reload` [https://github.com/aarol/reload](https://github.com/aarol/reload), this is a middleware for the [Chi](https://github.com/go-chi/chi) routers I was using. 

Simply add it to your project's `go.mod` file:
```
go get github.com/aarol/reload
```
Then add it to your router middleware stack:
```
func NewRouter() *chi.Mux {
    isDevelopment := flag.Bool("dev", true, "Development mode")
    flag.Parse()
    
    router := chi.NewRouter()
    
    router.Use(middleware.Logger)
    fmt.Println("Development mode:", *isDevelopment)
    if *isDevelopment {
        // Call `New()` with a list of directories to recursively watch
        reloader := reload.New("pkg/web/static/")
        router.Use(reloader.Handle)
    }
}
```
Points of interest here are:
* `dev` a flag to enable/disable reloading as we don't want this overhead in production
* `reload.New("pkg/web/static/")` - this is the directory we want to watch for changes, in my case this is where I've stored my static web files
* After this declaration we can use our `router` to set up paths for other routes quite normally

## Testing 
My application reads a `.csv` file from the filesystem, parses it and converts it to JSON to return to the frontend.  
I wanted to test my API responses in my HTTP handler layer as an integration test.  
I loaded the `.csv` file from my local filesystem into my router's test `router_test.go` from the relative location: `web/static`.  
My file hierarchy was:
```
.
└── pkg
    ├── amd
    │   └── decoder
    │       ├── csv
    │       │   ├── csv_suite_test.go
    │       │   ├── internal
    │       │   │   ├── Processor Specifications.csv
    │       │   │   └── Sample Processors.csv
    │       │   ├── Processor.go
    │       │   └── Processor_test.go
    │       ├── database
    │       │   ├── database_suite_test.go
    │       │   ├── model.go
    │       │   ├── repository.go
    │       │   └── repository_test.go
    │       └── decoder_suite_test.go
    ├── pkg_suite_test.go
    ├── Processor Specifications.csv
    ├── router.go
    ├── router_test.go
    └── web
        ├── mapper.go
        ├── model.go
        └── static
            └── index.html
```

To ensure that my test would run without the reloading middleware getting in the way I had to set the correct flags in my test file:
```
JustBeforeEach(func() {
    os.Args = []string{"amd-decoder", "-dev=false"}
}
```

## Testing and File Resources
When I compiled and ran my code I got an error in the logs saying that my `.csv` file could not be found.  
This was because when I ran my tests the working directory was not the same as when I ran my application.  

|                      | Testing            | Production                        |
|----------------------|--------------------|-----------------------------------|
| Working Directory    | `.` (project root) | `~/<project_name>/.`              |
| Static Resource Path | `pkg/web/static`   | `~/<project_name>/pkg/web/static` | 

How could I solve this?  

Well I took a leaf out of the `dev` flag book I used for my testing to specify a different static resource location in production.  
I combined it with Go's `embed` package which is a great way to include static files into your binary instead of my project trying to source them from my current filesystem which I cannot guarantee if I distribute my binary to other systems.  

* First I added the `embed` package to my imports
* Then I declared the `embeddedFS` variable with the `//go:embed` directive to include all files in the `web/static` directory
* I made use of the `fs.Sub` function to create a sub filesystem from the embedded filesystem, this is because the `embed` package includes the full path to the files and this will strip that out
  * This is so that the resources are served under the path `/` instead of `/web/static/` which is what the `embed` package would serve them under by default

```
//go:embed web/static/*
var embeddedFS embed.FS

func GetStaticContent(isDevelopment *bool) http.HandlerFunc {
	return func(writer http.ResponseWriter, request *http.Request) {
		if *isDevelopment {
			http.StripPrefix("/", http.FileServer(http.Dir("./pkg/web/static/"))).ServeHTTP(writer, request)
		} else {
			fmt.Println("using embedded file system for static content")
			staticFS, err := fs.Sub(embeddedFS, "web/static")
			if err != nil {
				slog.Error(fmt.Sprintf("couldn't get sub filesystem: %v", err))
				writer.WriteHeader(http.StatusInternalServerError)
				return
			}
			http.StripPrefix("/", http.FileServerFS(staticFS)).ServeHTTP(writer, request)
		}
	}
}
```

Why not use embed all the time even in testing? Well the `embed` package is a compile time feature, so if I change my static files I would have to recompile my application to see the changes.  

## Conclusion
So now I can run my application in development mode with live reloading of my static files and I can also run my tests without worrying about file paths being incorrect.

| Environment                 | Development        | Production    |
|-----------------------------|--------------------|---------------|
| Static content served from: | `./pkg/web/static` | `web/static/` |
| Reloading enabled:          | Yes                | No            |


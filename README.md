## Building docker image
### Development with docker-compose
```
vagrant up
cd /vagrant
sudo docker compose up --build
```
* The blog will be available on [http://localhost:4000](http://localhost:4000)
### Docker build
```
sudo docker build -t jekyll-blog:latest .
```

### Environmental variables
Taken from the [Command line usage options - build](https://jekyllrb.com/docs/configuration/options/#build-command-options) docs:

| Environment variable | Description                                                                                                                                                                | Jekyll CLI option |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------|
| FUTURE               | to include posts with a future date                                                                                                                                        | `--future`        |
| DRAFT                | to include draft posts from the `_drafts` directory                                                                                                                        | `--draft`         | 
| WATCH                | to enable auto-regeneration of the site when files are modified                                                                                                            | `--watch`         |
| FORCE_POLLING        | to force Jekyll's watch to use polling for file changes, this is useful when running in a shared VM drive or on a network drive where inotify events may not work properly | `--force_polling` | 


## Local Jekyll Install
* `mise use ruby@3.4.1`
* `gem install jekyll -v 4.4.1`
```
bundle install 
bundle exec jekyll serve
```
### Troubleshooting
* [https://github.com/jekyll/jekyll/issues/9233](https://github.com/jekyll/jekyll/issues/9233)
```
Liquid Exception: undefined method 'tainted?' for an instance of String in /_layouts/post.html
```
* Install a newer version of Ruby?

```
Configuration file: /Users/alex.hopgood/IdeaProjects/ahopgood.github.io/_config.yml
Source: /Users/alex.hopgood/IdeaProjects/ahopgood.github.io
Destination: /Users/alex.hopgood/IdeaProjects/ahopgood.github.io/_site
 Incremental build: disabled. Enable with --incremental
                                                      Generating...
                                                      done in 2.226 seconds.
                                                      Auto-regeneration: enabled for '/Users/alex.hopgood/IdeaProjects/ahopgood.github.io'
  Server address: http://127.0.0.1:4000/
  Server running... press ctrl-c to stop.
```
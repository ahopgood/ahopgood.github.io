Local development:
```
export JEKYLL_VERSION=4.4.1
docker run --rm \
    --volume="$PWD:/srv/jekyll" \
    -it jekyll/jekyll:$JEKYLL_VERSION \
    jekyll build
```

## Puppet version
* ruby 3.4.0
```
gem install jekyll github-pages
```
* bundle exec jekyll serve
### Control script
```
#!/usr/bin/env bash

start() {
  echo "Starting Jekyll..."
  jekyll serve --host <%= @blog_host_address %> -s <%= @blog_source_directory %> -d <%= @blog_output_directory %> --watch <%= @drafts %> <%= @future %> --force_polling
}

stop() {
  echo "Stopping Jekyll..."
  echo "Found jekyll pids: "$(/bin/ps -aux | /bin/grep jekyll | /bin/grep -v grep | /usr/bin/awk '{ print $2 }' )
  /bin/ps -aux | /bin/grep jekyll | /bin/grep -v grep | /usr/bin/awk '{ print $2 }' | xargs kill
  exit 0
}

status() {
  echo "status"
  JEKYLL_IDS=$(ps -aux | grep jekyll | grep -v grep | awk '{ print $2 }')
  echo "Found jekyll pids: $JEKYLL_IDS"
}

case $1 in
  start) "$1";;
  stop|status) "$1" ;;
esac
```

## Local Install
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
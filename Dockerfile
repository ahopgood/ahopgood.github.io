# Create a Jekyll container from a Ruby Alpine image

# At a minimum, use Ruby 2.5 or later
FROM ruby:3.4.1-alpine3.21

# Add Jekyll dependencies to Alpine
RUN apk update
RUN apk add --no-cache build-base gcc cmake git

#FROM ubuntu:22.04
#RUN apt update && apt install ruby-full=3.4.1 -y
#RUN ruby -version

# Update the Ruby bundler and install Jekyll
#RUN gem update bundler && gem install bundler jekyll

RUN gem install jekyll -v 4.4.1

# Add an entrypoint script here to start Jekyll?

# ENV BLOG_HOST_ADDRESS= \
# /srv/
# ENV BLOG_SOURCE_DIR=
# ENV BLOG_OUTPUT_DIRECTORY=
# ENV DRAFTS=
# ENV FUTURE=true
#RUN jekyll serve \
#    --host <%= @blog_host_address %> \
#    -s <%= @blog_source_directory %> \
#    -d <%= @blog_output_directory %> \
#    --watch <%= @drafts %> <%= @future %>  \
#    --force_polling

COPY Gemfile .
RUN bundle install
EXPOSE 4000
RUN mkdir /srv/jekyll
COPY entrypoint.sh .
ENTRYPOINT ./entrypoint.sh
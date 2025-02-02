---
layout: post
title:  "Multi-line pillar values"
date: 2025-02-01
categories: salt
---
When working with salt `3006.5` and I'm trying to provision multi-line values from my pillar contents I get the following unhelpful error: 

```
local:
    Data failed to compile:
----------
    Rendering SLS 'base:environment' failed: could not find expected ':'; line 100

---
[...]
            password: admin
          credentials:
            ssh:
              private: -----BEGIN RSA PRIVATE KEY-----
the
quick    <======================
brown
fox
```

I've configured my pillar values like so:

```
docker:
  services:
    jenkins:
      credentials:
        ssh:
          private: |
            -----BEGIN RSA PRIVATE KEY-----
            the
            quick
            brown
            fox
```
This value is then referenced in a yaml file serializer:
```
/usr/local/etc/.env-template.yaml:
  file.serialize:
    - dataset:
        jenkins:
          credentials:
            ssh:
              private: {{ pillar[ 'docker' ][ 'services' ][ 'jenkins' ][ 'credentials' ][ 'ssh' ][ 'private' ] }}
```

It turns out for multi-line values you need to wrap the reference inside double quotes like so:
```
private: "{{ pillar[ 'docker' ][ 'services' ][ 'jenkins' ][ 'credentials' ][ 'ssh' ][ 'private' ] }}"
```
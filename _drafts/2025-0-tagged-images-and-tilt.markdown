---
layout: post
title:  "Using tagged images with Tilt, Kustomize and Kubernetes"
date: 2025-0
categories: k8s tilt kustomize
---

## Preface
* Already use the [git extension](https://github.com/tilt-dev/tilt-extensions/tree/master/git_resource) for Tilt to check out tagged/branches of a repository
* Our staff engineer was adamant that we should be using tagged images pulled from ECR (Elastic Cloud Registry) in our local development environment

## Existing code
```
docker_build("blah.dkr.ecr.eu-west-1.amazonaws.com/my-svc", ".", ignore=['docs', 'config', 'model', 'respondent', 'surveys', 'utils', 'main.go', 'router.go'])
k8s_yaml(kustomize('.infra/k8s/overlays/local'))
```

## How to achieve this?
* Break down our kustomize and k8s block into two-step process; 
  * Assign our `kustomizeOuput = kustomize('.infra/k8s/overlays/local')` output to a variable 
  * and then apply this to Kubernetes `k8s_yaml(kustomizeOuput)`
* If we're **not** using a tag then this is the same as before, except we have the two-step process mentioned to apply the manifests
* If we **are** using a tag then we need to modify the `kustomizeOutput` before applying it to Kubernetes

## The solution
* Using the Tilt doc on [How to Make Small Patches in a Tiltfile](https://docs.tilt.dev/templating.html#how-to-make-small-patches-in-a-tiltfile) we apply the following:
  * Utilising the `str()` method we convert the kustomize blob output to a string
  * We convert this kustomize yaml string output with [`decode_yaml_stream`](https://docs.tilt.dev/api.html#api.decode_yaml_stream) to a list of Skylark objects
  * Loop through the list of objects checking each `kind` for the `Deployment` type
  * Then we check the `spec.template.spec.containers` list for the container we want to modify
  * We update the `image` field to use our tagged image
  * Finally we then use [`encode_yaml_stream`](https://docs.tilt.dev/api.html#api.encode_yaml_stream) to convert our modified list of objects back to a yaml string
* Now we're back at the same place we'd be with our original kustomize output so we can apply this to Kubernetes with `k8s_yaml()`
```
tag = os.environ.get('MY_SVC_TAG')
kustomize = kustomize('.infra/k8s/overlays/local')

if tag == None:
  docker_build("blah.dkr.ecr.eu-west-1.amazonaws.com/my-svc", ".", ignore=['docs', 'config', 'model', 'respondent', 'surveys', 'utils', 'main.go', 'router.go'])
  k8s_yaml(kustomize)
else:
    # If we have a tag, we need to modify the kustomize yaml to use the right image tag
    print("Using image tag: " + str(tag))
    objects = decode_yaml_stream(str(kustomize))
    for o in objects:
        if 'kind' in o and o['kind'] == 'Deployment':
            for i in o['spec']['template']['spec']['containers']:
                if i['name'] == 'purespectrum-panel-svc':
                    i['image'] = "blah.dkr.ecr.eu-west-1.amazonaws.com/my-svc:" + tag

    k8s_yaml(encode_yaml_stream(objects))
```

## How does this get used?
* Set an environmental variable for the tag you want to use and bring up tilt
  * `MY_SVC_TAG=v1.2.3 tilt up`
* If the tag isn't present then we continue to build and apply the docker image to our kubernetes context
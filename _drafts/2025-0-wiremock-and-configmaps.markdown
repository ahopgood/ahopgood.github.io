---
layout: post
title:  "Wiremock and the Kubernetes ConfigMaps"
date: 2025-0
categories: wiremock k8s
---

## Preface
I have configured a simple enough `ConfigMap` for wiremock running in kubernetes (K8s).  
It exposes one file under the `data` block:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: wiremock-mappings-a3
data:
    workos.json: |-
      {
        "request": {
          "url": "/a3/workos/sso/token",
          "method": "POST"
        },
        "response": {
          "status": 200,
          "body": "{\"profile\": {\"id\":\"test-sso-id\"}}",
          "headers": {
            "Content-Type": "application/json"
          }
        }
      }
```
This `ConfigMap` is used directly by wiremock to populate a sub-directory used by wiremock for mappings:
```
spec:
  template:
    spec:
      containers:
        - name: wiremock
        args:
          - "--port=9021"
          - "--max-request-journal=1000"
          - "--local-response-templating"
          - "--root-dir=/home/wiremock/storage"
          - "--verbose"
        volumeMounts:
          - mountPath: /home/wiremock/storage/mappings/a3
            name: mappings-data-a3
        volumes:
        - name: mappings-data-a3
          configMap:
            name: wiremock-mappings-a3
            optional: true
```
## Symptom
* My ConfigMap contained a single mapping.
* When calling `GET http:<someaddress>/__admin/mappings/` I received **three instances** of the same mapping:
```
{
  "mappings": [
    {
      "id": "fe464f99-e049-4e3d-b11d-d7b1617a0160",
      "request": {
        "url": "/a3/workos/sso/token",
        "method": "POST"
      },
      "response": {
        "status": 200,
        "body": "{\"profile\": {\"id\":\"test-sso-id\"}}",
        "headers": {
          "Content-Type": "application/json"
        }
      },
      "uuid": "fe464f99-e049-4e3d-b11d-d7b1617a0160"
    },
    {
      "id": "f5dd8a2f-1e22-4383-884a-9e283f50e823",
      "request": {
        "url": "/a3/workos/sso/token",
        "method": "POST"
      },
      "response": {
        "status": 200,
        "body": "{\"profile\": {\"id\":\"test-sso-id\"}}",
        "headers": {
          "Content-Type": "application/json"
        }
      },
      "uuid": "f5dd8a2f-1e22-4383-884a-9e283f50e823"
    },
    {
      "id": "07279fd6-01ad-48da-abfc-5b05b6d213a5",
      "request": {
        "url": "/a3/workos/sso/token",
        "method": "POST"
      },
      "response": {
        "status": 200,
        "body": "{\"profile\": {\"id\":\"test-sso-id\"}}",
        "headers": {
          "Content-Type": "application/json"
        }
      },
      "uuid": "07279fd6-01ad-48da-abfc-5b05b6d213a5"
    }
  ],
  "meta": {
    "total": 3
  }
}
```
This really puzzled me as I couldn't figure out if this was an issue with my configuration or perhaps the data was being loaded multiple times when the container gets restarted, who knows?

## Investigation
I added an `initContainers` block to list the directory structure to get better insight into what was going on from the container's perspective, what could it see and access?
```
volumeMounts:
  - mountPath: /home/wiremock/storage/mappings/a3
    name: mappings-data-a3
initContainers:
- name: view-mappings
image: "bash:5"
imagePullPolicy: "Always"
command: ["bash", "-c", "ls -lR /home/wiremock/storage/mappings/a3/"]
volumeMounts:
  - mountPath: /home/wiremock/storage/mappings/a3
    name: mappings-data-a3
volumes:
- name: mappings-data-a3
configMap:
  name: wiremock-mappings-a3
  optional: true
```
My first learning was that the directory _appeared_ empty, that's right empty, well I know that isn't true as I have my mapping, albeit three times as many as I was expecting.  
Next step was to change the ls command to `ls -lRa` to list any archive files and lo and behold:
```
[view-mappings] /home/wiremock/storage/mappings/a3/:
[view-mappings] total 12
[view-mappings] drwxrwxrwx    3 root     root          4096 Jun 11 12:48 .
[view-mappings] drwxr-xr-x    3 root     root          4096 Jun 11 12:48 ..
[view-mappings] drwxr-xr-x    2 root     root          4096 Jun 11 12:48 ..2025_06_11_12_48_29.1142742111
[view-mappings] lrwxrwxrwx    1 root     root            32 Jun 11 12:48 ..data -> ..2025_06_11_12_48_29.1142742111
[view-mappings] lrwxrwxrwx    1 root     root            18 Jun 11 12:48 workos.json -> ..data/workos.json
[view-mappings]
[view-mappings] /home/wiremock/storage/mappings/a3/..2025_06_11_12_48_29.1142742111:
[view-mappings] total 12
[view-mappings] drwxr-xr-x    2 root     root          4096 Jun 11 12:48 .
[view-mappings] drwxrwxrwx    3 root     root          4096 Jun 11 12:48 ..
[view-mappings] -rw-r--r--    1 root     root           237 Jun 11 12:48 workos.json
```
Essentially what we're seeing here is the `data` directory that a `ConfigMap` exposes is a symbolic link to a timestamped directory.  
Presumably this is so that when new data is added the link just needs to be updated and any volumes or services relying on the map will be able to access the most upto date data.

## Solution
* Turns out this is related to a known issue [https://github.com/holomekc/wiremock/issues/269](https://github.com/holomekc/wiremock/issues/269)
* One solution is to use an identifier for the mapping and prevent a duplicate being added.
* Except Wiremock now performs checks that prevent multiple stubbings with the same id [https://github.com/wiremock/wiremock/issues/2734](https://github.com/wiremock/wiremock/issues/2734) but it causes failures.
* There is an open issue for making this check optional [https://github.com/wiremock/wiremock/issues/2778](https://github.com/wiremock/wiremock/issues/2778)
* I'm not sure this fix will solve our particular issue as we want to prevent the addition of duplicate mappings but not to fail on the addition of the mappings
* One solution is to use an `initContainers` block to copy only the files in the ConfigMap to the wiremock container `find /home/wiremock/configmap-mappings/ -type f -exec cp '{}' /home/wiremock/mappings/ \;`.  

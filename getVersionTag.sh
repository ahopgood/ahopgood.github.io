#! /usr/bin/env bash

SHORT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date "+%Y-%m-%d")
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
BRANCH_NAME=$(echo $BRANCH_NAME | sed s/\\//-/)

printf "%s-%s-%s\n" "${BRANCH_NAME}" "${TIMESTAMP}" "${SHORT_SHA}"
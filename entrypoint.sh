#! /bin/sh

set -ex

FUTURE_FLAG=""
if [ -n "${FUTURE}"  ] && [ "${FUTURE}" == "true" ]; then
  echo "Future env var found, setting flag --future"
  FUTURE_FLAG="--future"
fi

DRAFT_FLAG=""
if [ -n "${DRAFT}" ] && [ "${DRAFT}" == "true" ]; then
  echo "Draft env var found, setting flag --draft"
  DRAFT_FLAG="--draft"
fi

bundle exec jekyll serve -s /srv/jekyll --host 0.0.0.0 ${FUTURE_FLAG} ${DRAFT_FLAG}
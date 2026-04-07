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

WATCH_FLAG=""
if [ -n "${WATCH}" ] && [ "${WATCH}" == "true" ]; then
  echo "Watch env var found, setting flag --watch"
  WATCH_FLAG="--watch"
fi

FORCE_POLLING_FLAG=""
if [ -n "${FORCE_POLLING}" ] && [ "${FORCE_POLLING}" == "true" ]; then
  echo "Force polling env var found, setting flag --force-polling"
  FORCE_POLLING_FLAG="--force-polling"
fi

bundle exec jekyll serve -s /srv/jekyll --host 0.0.0.0 ${FUTURE_FLAG} ${DRAFT_FLAG} ${WATCH_FLAG} ${FORCE_POLLING_FLAG}
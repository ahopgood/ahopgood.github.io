#! /bin/sh

set -ex

FUTURE_FLAG=""
if [ -n "${FUTURE}"  ] && [ "${FUTURE}" == "true" ] ; then
  echo "Future env var found, setting flag --future"
  FUTURE_FLAG="--future"
fi

bundle exec jekyll serve -s /srv/jekyll --host 0.0.0.0 ${FUTURE_FLAG}
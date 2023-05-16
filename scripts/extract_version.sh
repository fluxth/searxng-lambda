#!/bin/bash -e

CWD="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

RUNTIME_TAG=$(grep lambda/python $CWD/../Dockerfile | head -n1 | sed 's/@.*$//' | sed 's/^.*://')
SEARXNG_TAG=$(grep DOCKER_TAG $CWD/../searxng/searx/version_frozen.py | sed 's/^.*= "//' | sed 's/"$//')

echo "$SEARXNG_TAG-$RUNTIME_TAG"

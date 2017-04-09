#!/usr/bin/env bash

set -eu

export REPO=fiunchinho/wimpy
export TAG=`if [ -z "${TRAVIS_TAG}" ]; then echo "latest"; else echo "${TRAVIS_TAG}" ; fi`

docker login -e "${DOCKER_EMAIL}" -u "${DOCKER_USER}" -p "${DOCKER_PASS}"
docker build -t ${REPO}:latest .
docker tag $REPO:latest $REPO:$TAG
docker push $REPO

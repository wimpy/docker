#!/usr/bin/env bash

set -euv

export TAG=`if [ -z "${TRAVIS_TAG}" ]; then echo "latest"; else echo "${TRAVIS_TAG}" ; fi`

docker login -e "${DOCKER_EMAIL}" -u "${DOCKER_USER}" -p "${DOCKER_PASS}"
docker build \
          --build-arg vcs_branch=`git rev-parse --abbrev-ref HEAD` \
          --build-arg vcs_ref=`git rev-parse HEAD` \
          --build-arg build_date=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
          -t ${REPO}:latest .

docker tag ${REPO}:latest ${REPO}:${TAG}

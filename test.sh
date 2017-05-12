#!/usr/bin/env bash

set -euv

function deploy_first_canary() {
    git clone https://github.com/wimpy/canary.git
    cd canary
    docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/app" \
        -e AWS_ACCESS_KEY_ID \
        -e AWS_SECRET_ACCESS_KEY \
        fiunchinho/wimpy /app/deploy.yml  \
          --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=production" -vv

    curl --fail canary.armesto.net/health
    cd ..
}

function deploy_second_canary() {
    git clone https://github.com/wimpy/canary.git canary2
    cd canary2
    git checkout blue_green && docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/app" \
        -e AWS_ACCESS_KEY_ID \
        -e AWS_SECRET_ACCESS_KEY \
        fiunchinho/wimpy /app/deploy.yml  \
          --extra-vars "wimpy_release_version=`git rev-parse HEAD^1` wimpy_deployment_environment=production" -vv

    curl --fail canary2.armesto.net/healthz
    cd ..
}

function deploy_third_canary() {
    cd canary2
    docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/app" \
        -e AWS_ACCESS_KEY_ID \
        -e AWS_SECRET_ACCESS_KEY \
        fiunchinho/wimpy /app/deploy.yml  \
          --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=production" -vv

    curl --fail canary2.armesto.net/healthz
    cd ..
}

deploy_first_canary
deploy_second_canary
deploy_third_canary

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

function clean_base() {
    aws s3 rm s3://StorageBucket --recursive
    aws s3 rm s3://LogBucket --recursive
    aws cloudformation delete-stack --stack-name base
    aws cloudformation stack-delete-complete --stack-name base
}

function clean_environments() {
    aws cloudformation delete-stack --stack-name staging
    aws cloudformation stack-delete-complete --stack-name staging
    aws cloudformation delete-stack --stack-name production
    aws cloudformation stack-delete-complete --stack-name production
}

function clean_application() {
    aws ecr delete-repository --force --repository-name canary
    aws ecr delete-repository --force --repository-name canary2
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --stack-status-filter UPDATE_COMPLETE
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --stack-status-filter UPDATE_COMPLETE | jq '.StackSummaries[] | select(.StackName | contains ("canary")).StackName' -r
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --stack-status-filter UPDATE_COMPLETE | jq '.StackSummaries[] | select(.StackName | contains ("canary")).StackName' -r | xargs -t -n1 aws cloudformation delete-stack --stack-name
    aws cloudformation stack-delete-complete --stack-name canary-resources
}

function clean() {
    clean_application
    clean_environments
    clean_base
}

function docker_build() {
    docker login -e "${DOCKER_EMAIL}" -u "${DOCKER_USER}" -p "${DOCKER_PASS}"
    docker build -t ${REPO}:latest .
    docker tag ${REPO}:latest ${REPO}:${TAG}
}

export REPO=fiunchinho/wimpy
export TAG=`if [ -z "${TRAVIS_TAG}" ]; then echo "latest"; else echo "${TRAVIS_TAG}" ; fi`

docker_build

deploy_first_canary
deploy_second_canary
deploy_third_canary

clean

docker push ${REPO}

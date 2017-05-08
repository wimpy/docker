#!/usr/bin/env bash

function deploy_first_canary() {
    git clone git@github.com:wimpy/canary.git
    cd canary

    docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/app" \
        -e AWS_ACCESS_KEY_ID \
        -e AWS_SECRET_ACCESS_KEY \
        fiunchinho/wimpy /app/deploy.yml  \
          --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=production" -vv

    curl --fail canary.armesto.net
    cd ..
}

function deploy_second_canary() {
    git clone git@github.com:wimpy/canary2.git
    cd canary2
    git checkout blue_green

    docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/app" \
        -e AWS_ACCESS_KEY_ID \
        -e AWS_SECRET_ACCESS_KEY \
        fiunchinho/wimpy /app/deploy.yml  \
          --extra-vars "wimpy_release_version=`git rev-parse HEAD^1` wimpy_deployment_environment=production" -vv

    curl --fail canary2.armesto.net
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

    curl --fail canary2.armesto.net
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
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE | jq '.StackSummaries[] | select(.StackName | contains ("canary"))' -r | xargs -n1 aws cloudformation delete-stack --stack-name
    aws cloudformation stack-delete-complete --stack-name canary-resources
}

function clean() {
    clean_application
    clean_environments
    clean_base
}

export AWS_DEFAULT_REGION="eu-west-1"

deploy_first_canary
deploy_second_canary
deploy_third_canary

clean

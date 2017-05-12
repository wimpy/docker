#!/usr/bin/env bash

set -euv

function clean_base() {
    aws s3api list-buckets --query 'Buckets[]' | jq '.[] | select(.Name | contains ("storage-bucket")).Name' | xargs -t -n1 -I{} aws s3 rm s3://{} --recursive
    aws s3api list-buckets --query 'Buckets[]' | jq '.[] | select(.Name | contains ("log-bucket")).Name' | xargs -t -n1 -I{} aws s3 rm s3://{} --recursive
    aws cloudformation delete-stack --stack-name base
    aws cloudformation wait stack-delete-complete --stack-name base
}

function clean_environments() {
    aws cloudformation delete-stack --stack-name staging
    aws cloudformation delete-stack --stack-name production
    aws cloudformation wait stack-delete-complete --stack-name staging
    aws cloudformation wait stack-delete-complete --stack-name production
}

function clean_application() {
    aws ecr delete-repository --force --repository-name canary
    aws ecr delete-repository --force --repository-name canary2
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE | jq '.StackSummaries[] | select(.StackName | contains ("canary")).StackName' -r | xargs -t -n1 aws cloudformation delete-stack --stack-name
    aws cloudformation wait stack-delete-complete --stack-name canary-resources
}

clean_application
clean_environments
clean_base

#!/usr/bin/env bash

set -euv

export DEPLOY_CMD='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/app" -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY fiunchinho/wimpy /app/deploy.yml --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=production" -vv'
mkdir workspace
cd workspace

git clone https://github.com/wimpy/canary.git --branch master master
git clone https://github.com/wimpy/canary.git --branch blue_green blue_green

ls -d ./* | parallel -j2 --halt soon,fail=1 --gnu --keep-order "cd {} && $DEPLOY_CMD"

curl --fail canary.armesto.net/healthz
curl --fail canary2.armesto.net/healthz

# Re Deploy
cd blue_green
git checkout HEAD^1
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/app" -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY fiunchinho/wimpy /app/deploy.yml --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=production" -vv
curl --fail canary2.armesto.net/healthz

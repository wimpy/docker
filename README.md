# Docker Wimpy Deploy  [![Build Status](https://travis-ci.org/wimpy/docker.svg?branch=master)](https://travis-ci.org/wimpy/docker)
This is a Docker image that contains everything you need to deploy using Wimpy.
It installs all Wimpy roles and their dependencies.

## Usage
You can use it like

```bash
$ docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/app" \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  fiunchinho/wimpy /app/deploy/deploy.yml \
    --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=develop" -vv
```

## Volumes 
The Wimpy Docker image has the following volumes
- `/app` Folder where the application folder needs to be mounted
- `/var/run/docker.sock` Docker socket to be able to execute docker commands. Only needed when using `wimpy.build`

If you need to decrypt variables using Ansible Vault, you will need to mount the file containing the password like

```bash
$ docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/app" \
  -v /tmp/.vault_pass:/tmp/.vault_pass \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  fiunchinho/wimpy /app/deploy/deploy.yml --vault-password-file /tmp/.vault_pass \
    --extra-vars "wimpy_release_version=`git rev-parse HEAD` wimpy_deployment_environment=develop" -vv
```

## AWS Authentication
Wimpy needs to authenticate the requests to the AWS API. You can pass the usual AWS environment variables
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Or you can even mount a configuration `.aws` folder file inside the container path `/root/.aws`.

# docker-terraform [![CI](https://github.com/d3b-center/docker-terraform/workflows/CI/badge.svg?branch=master)](https://github.com/d3b-center/docker-terraform/actions?query=workflow%3ACI)

This repository contains a collection of Nix flakes that produce container images designed to run deployments using the AWS CLI and Terraform.

## Usage

Via Docker Compose, which includes volumes for basic functionality:

```yml
services:
  terraform:
    image: ghcr.io/d3b-center/terraform:1.1.9
    volumes:
      - ./:/usr/local/src
      - $HOME/.aws:/root/.aws:ro
    environment:
      - AWS_PROFILE
    working_dir: /usr/local/src
    entrypoint: bash
```

```console
$ docker-compose run --rm terraform
bash-5.1# terraform -version
Terraform v1.1.9
on linux_amd64
```

### Build Variables

- `TERRAFORM_VERSION` - Terraform version (there must be a corrresponding flake).

### Testing

An example of how to use `cibuild` to build and test an image:

```console
$ CI=1 TERRAFORM_VERSION=1.1.9 ./scripts/cibuild
```

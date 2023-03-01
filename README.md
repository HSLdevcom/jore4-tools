# jore4-tools

Tools which are commonly used by other JORE4 projects

<!-- regenerate with: "./development.sh toc" -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Tools for Docker](#tools-for-docker)
  - [read-secrets.sh](#read-secretssh)
- [Github Actions](#github-actions)
  - [extract-metadata](#extract-metadata)
  - [healthcheck](#healthcheck)
  - [setup-e2e-environment](#setup-e2e-environment)
- [Github scripts](#github-scripts)
  - [add_secrets.py](#add_secretspy)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Tools for Docker

### read-secrets.sh

Reads docker secrets into environment variables. Secrets' filenames are
transformed into environment variable names with \_ characters replacing
non-alphanumeric characters.

Parameters:

Reads secrets' bash path from `SECRET_STORE_BASE_PATH` env variable

Example setup:

```
$ cat secrets/foo1
bar1
$ cat secrets/foo2-blabla
bar2
$ cat secrets/foo3.lol
bar3.lolo
```

Usage:

```
$ SECRET_STORE_BASE_PATH=secrets source read-secrets.sh
$ printenv
[...]
FOO1=bar1
FOO2_BLABLA=bar2
FOO3_LOL=bar3.lolo
```

Usage within Dockerfile:

```
# download script for reading docker secrets
RUN curl -o /tmp/read-secrets.sh "https://raw.githubusercontent.com/HSLdevcom/jore4-tools/main/docker/read-secrets.sh"

# read docker secrets into environment variables and run application
CMD /bin/bash -c "source /tmp/read-secrets.sh && java -jar /.../xxx.jar"
```

## Github Actions

### extract-metadata

Extracts Github repository metadata in Docker Hub friendly format.

Example usage:

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/extract-metadata@extract-metadata-v1
```

After calling this action defines following environment variables that are available in later steps:
`BRANCH_NAME`: branch name, e.g. `main`. Should work also in pull requests unlike `GITHUB_HEAD_REF` that Github automatically provides.
`IMAGE_NAME`: repository name in lowercase format, including organization. E.g. `hsldevcom/jore4-tools`. Can be used as docker image name.
`COMMIT_ID`: commit details in format `<branch name>--<git commit hash>`. Can be used when tagging docker images.

### healthcheck

Runs a user-defined script to check whether a service is up and running

Parameters:

- retries: How many times to retry the healthcheck script before it fails
  (default: 20)
- wait_between: How many seconds to wait in between retries (default: 5)
- command: User-defined command for checking health of a service (required)

Example usage:

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/healthcheck@healthcheck-v1
  with:
    command: "curl --fail http://localhost:3200/actuator/health --output /dev/null --silent"
```

### setup-e2e-environment

Retrieves a given version of the docker-compose bundle from the releases and runs it. Optionally
can set given services' docker image versions.

To see how docker-compose bundle is created and used, refer to [wiki](https://github.com/HSLdevcom/jore4/wiki/Infra#docker-compose-bundle)

Parameters:
- bundle_version: Version of the docker-compose bundle to use (= github release version)
- custom_docker_compose: Path for an additional docker-compose file to be used when starting up the environment.
- ui_version, hasura_version, ... (*_version): Specific the docker image tag of the microservice to be used. For all options, see `/github-actions/setup-e2e-environment/action.yml`

Example usage:

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/extract-metadata@extract-metadata-v1

- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v1
  with:
    ui_version: '${{ env.IMAGE_NAME }}:${{ env.COMMIT_ID }}'
```

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v1
  with:
    custom_docker_compose: ./docker/docker-compose.custom.yml
```

## Github scripts

### add_secrets.py

Adds robot users hsl-id e-mail and password to jore4 repositories which have
`jore4` added as
[topic](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics#about-topics).

Uses file named `test_users.json` as input for user details. This file should be created by changing placeholder values in `tests_users_template.json` to correct passwords and e-mails, these can be found from the hsl-jore4-common key-vault as secrets.
After the script is run the secrets can be found by going to repositorys `Settings` page in github and then selecting `Secrets` tab. There should be now secrets named `ROBOT_HSLID_EMAIL` and `ROBOT_HSLID_PASSWORD` and they should show that they have been updated when you ran the script.

Example usage:
`python3 add_secrets.py`
Running the script requires that you have python and GitHub CLI installed and access to HSLdevcom organization in GitHub. Instructions for installing GitHub CLI can be found here: https://github.com/cli/cli#installation

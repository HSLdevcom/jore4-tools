# jore4-tools

Tools which are commonly used by other JORE4 projects

<!-- regenerate with: "./development.sh toc" -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Tools for Docker](#tools-for-docker)
  - [read-secrets.sh](#read-secretssh)
  - [download-docker-bundle.sh](#download-docker-bundlesh)
- [Github Actions](#github-actions)
  - [extract-metadata](#extract-metadata)
  - [healthcheck](#healthcheck)
  - [setup-e2e-environment](#setup-e2e-environment)
  - [run-cypress-tests](#run-cypress-tests)
- [Github scripts](#github-scripts)
  - [add_secrets.py](#add_secretspy)
- [Renovatebot preset](#renovatebot-preset)
  - [jore4-default-preset.json5](#jore4-default-presetjson5)

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

### download-docker-bundle.sh

Downloads and extract the latest version of the docker bundle. It uses the `gh` github command line tool to retrieve the bundle from the releases.

To see how docker-compose bundle is created and used, refer to [wiki](https://github.com/HSLdevcom/jore4/wiki/Infra#docker-compose-bundle)

Parameters:
- with the `DOCKER_BUNDLE_PATH` environment variable you can set the destination folder to where the bundle is downloaded. Default "./docker"

Usage:
```sh
curl https://raw.githubusercontent.com/HSLdevcom/jore4-tools/main/docker/download-docker-bundle.sh | DOCKER_BUNDLE_PATH=./docker bash

# or just simply:
curl https://raw.githubusercontent.com/HSLdevcom/jore4-tools/main/docker/download-docker-bundle.sh | bash
```

Usage in context of starting up a local development environment:

```sh
#!/bin/bash

set -euo pipefail

# download latest docker bundle
curl https://raw.githubusercontent.com/HSLdevcom/jore4-tools/main/docker/download-docker-bundle.sh | bash

# start up some dependency services (and build on-demand) in the background
docker-compose -f ./docker/docker-compose.yml up -d jore4-testdb jore4-hasura jore4-auth

# start up some dependency services with some overrides (e.g. pinned docker image versions) in a docker-compose.custom.yml file and build on demand (if using own repo's Dockerfile too)
docker-compose -f ./docker/docker-compose.yml -f ./docker/docker-compose.custom.yml up --build jore4-testdb jore4-hasura jore4-auth

# more info on docker-compose up command: https://docs.docker.com/engine/reference/commandline/compose_up/
```

To overwrite some values in the generic docker-compose config, you could use
[docker-compose overrides](https://docs.docker.com/compose/extends/#multiple-compose-files)

To use your local repository version of the docker image instead of the e2e version, you could use
[docker-compose local build](https://docs.docker.com/compose/compose-file/compose-file-v3/#build)

To run your service locally e.g. in Maven and then point services within the docker-compose network
to use this natively running service, you could use
[host.docker.internal](https://docs.docker.com/desktop/windows/networking/#per-container-ip-addressing-is-not-possible).
For this, the `extra_hosts` parameter is already set for every service within the docker-compose
package.

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
- bundle_repo: The repository from whose releases the docker-compose bundle is to be downloaded
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

### run-cypress-tests

Runs cypress e2e tests. It assumes that a container with the name `cypress` is already running and
is parameterized to access all the tested containers. Best combine with the `setup-e2e-environment`
action as the docker bundle already contains the latest version of the cypress tests.

To see how docker-compose bundle is created and used, refer to [wiki](https://github.com/HSLdevcom/jore4/wiki/Infra#docker-compose-bundle)

Parameters:
- test-tags: Specify which e2e tests to run. `""` to run all, `"@smoke @routes"` to run with given tags. Default: `"@smoke"`

Example usage:

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v1
- uses: HSLdevcom/jore4-tools/github-actions/run-cypress-tests@run-cypress-tests-v1
```

```
steps:
- uses: HSLdevcom/jore4-tools/github-actions/extract-metadata@extract-metadata-v1

- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v1
  with:
    ui_version: '${{ env.IMAGE_NAME }}:${{ env.COMMIT_ID }}'

- uses: HSLdevcom/jore4-tools/github-actions/run-cypress-tests@run-cypress-tests-v1
  with:
    test-tags: ""
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

## Renovatebot preset

### jore4-default-preset.json5

Contains a sharable config preset with suggested renovatebot configurations for all jore4 repositories.
More info: https://docs.renovatebot.com/config-presets/

Example usage:
```json
{
  "extends": ["github>HSLdevcom/jore4-tools//renovatebot/jore4-default-preset.json5"]
}
```

Should also add the [renovate config validator](https://github.com/marketplace/actions/validate-renovate-configuration-with-renovate-config-validator)
github action to make sure that the new changes to the `renovate.json` file are valid after the
onboarding flow ends.

Example:
```
- name: Validate
  uses: suzuki-shunsuke/github-action-renovate-config-validator@v0.1.3
  with:
    config_file_path: .github/renovate.json5
```

To see a bit more in detail how the renovatebot rules work, check the comments within the
`jore4-default-preset.json5` file

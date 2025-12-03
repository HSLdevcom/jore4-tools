# jore4-tools

Tools which are commonly used by other JORE4 projects

<!-- regenerate with: "./development.sh toc" -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Tools for Docker](#tools-for-docker)
  - [read-secrets.sh](#read-secretssh)
  - [download-docker-bundle.sh](#download-docker-bundlesh)
- [Reusable GitHub Workflows](#reusable-github-workflows)
  - [shared-build-and-publish-docker-image](#shared-build-and-publish-docker-image)
  - [shared-run-e2e](#shared-run-e2e)
- [Github Actions](#github-actions)
  - [healthcheck](#healthcheck)
  - [setup-e2e-environment](#setup-e2e-environment)
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

If the SKIP_SET_VARIABLE_SECRET_OVERRIDE environment variable is set, pre-exisiting values will not be overriden by secrets.

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
docker compose -f ./docker/docker-compose.yml up -d jore4-testdb jore4-hasura jore4-auth

# start up some dependency services with some overrides (e.g. pinned docker image versions) in a docker-compose.custom.yml file and build on demand (if using own repo's Dockerfile too)
docker compose -f ./docker/docker-compose.yml -f ./docker/docker-compose.custom.yml up --build jore4-testdb jore4-hasura jore4-auth

# more info on docker compose up command: https://docs.docker.com/reference/cli/docker/compose/up/
```

To overwrite some values in the generic docker-compose config, you could use
[docker compose overrides](https://docs.docker.com/compose/extends/#multiple-compose-files)

To use your local repository version of the docker image instead of the e2e version, you could use
[docker compose local build](https://docs.docker.com/compose/compose-file/compose-file-v3/#build)

To run your service locally e.g. in Maven and then point services within the docker-compose network
to use this natively running service, you could use
[host.docker.internal](https://docs.docker.com/desktop/windows/networking/#per-container-ip-addressing-is-not-possible).
For this, the `extra_hosts` parameter is already set for every service within the docker-compose
package.

## Reusable GitHub Workflows

### shared-build-and-publish-docker-image

Builds and publishes Docker image to ACR (Azure Container Registry).

The workflow uses workload identity federation (see https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation),
i.e. there needs to be an user managed identity with federated credentials allowing the GitHub Actions workflow to federate its
identity.

The workflow updates *latest* and *cache* image if the workflow has been triggered by ref update to *main* branch.

Arguments:

- `acr_name` (optional): Name of the ACR registry to use. By default crjore4prod001
- `docker_image_name` (required): Name of the Docker image in ACR
- `build_arm64_image` (optional): Set to `true` if ARM64 image should be build in addition to amd64 image
- `file` (optional): Path to Dockerfile (`Dockerfile` by default)
- `context` (optional): Set the build context which must be a Git context, i.e. reference to a Git repository as the
  workflow does not checkout the repository. For supported format see https://docs.docker.com/build/concepts/context/#url-fragments
  The parameter is passed to docker/build-push-action's context argument which by default uses format
  `<github_server_url>/<organization>/<repository>.git/#<ref>` (see https://github.com/docker/actions-toolkit/blob/v0.56.0/src/context.ts#L58)
- `build_args` (optional): List of build time arguments for Docker build

The workflow uses the following credentials:

- `azure_tenant_id`: Azure tentant ID
- `azure_subscription_id`: Azure subscription containing the user managed identity
- `azure_client_id`: Client ID of the user managed identity in Azure to which the workflow has federated credentials

Example usage:

```yaml
docker-image:
name: Publish Docker image to ACR
permissions:
  id-token: write
  contents: read
uses: HSLdevcom/jore4-tools/.github/workflows/shared-build-and-publish-docker-image.yml@build-and-publish-docker-image-v1
with:
  docker_image_name: my-docker-image-name
secrets:
  azure_client_id: ${{ secrets.AZURE_CLIENT_ID }}
  azure_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
  azure_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### shared-run-e2e

Runs E2E tests.

It assumes that a container with the name `cypress` is already running and
is parameterised to access all the tested containers. Best combine with the `setup-e2e-environment`
action as the docker bundle already contains the latest version of the cypress tests.

To see how docker-compose bundle is created and used, refer to [wiki](https://github.com/HSLdevcom/jore4/wiki/Infra#docker-compose-bundle)

Arguments:
- `docker_compose_bundle_gha_artifact` (optional): The name of GitHub Actions artifact containing Docker Compose bundle.
  If not set, the bundle from main branch of jore4-docker-compose-bundle repository is used.
- `ui_version`: UI Docker image
- `hasura_version`: Hasura Docker image
- `auth_version`: Auth Docker image
- `mbtiles_version`: MB Tiles Docker image
- `jore3importer_version`: Jore3 Importer Docker image
- `testdb_version`: Docker Test DB image
- `mssqltestdb_version`: MSSQL Docker image
- `mapmatching_version`: Map Matching Docker image
- `mapmatchingdb_version`: Map Matching DB Docker image
- `cypress_version`: Cypress Docker image
- `hastus_version`: Hastus Docker image
- `timetablesapi_version`: Timetables API Docker image
- `tiamat_version`: Tiamat Docker image
- `custom_docker_compose`: Path to additional docker compose file used when starting E2E environment
- `start_jore3_importer`: (optional) Is Jore3 importer be started
- `test-tags`: (optional) String of tags for tests to be run in format '@smoke'
- `video`: (optional) Enable/disable video. `false` by default
- `update_e2e_test_durations`: (optional) Record E2E test durations into jore4-ci-data repository. If set to `true`
  a SSH deploy key having write permissions to the repository must be provided with `jore4-ci-data-repo-ssh-key` parameter

Secrets:

- `jore4_ci_data_repo_ssh_key`: (optional) SSH deploy key for write access to jore4-ci-data repository. Only needed
  when `update_e2e_test_durations` argument is set to `true`.

Example usage:

```yaml
run-e2e-tests:
  name: Run E2E tests
  uses: HSLdevcom/jore4-tools/.github/workflows/shared-run-e2e.yml@main
  with:
    test-tags: ""
```

## Github Actions

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
- custom_docker_compose: Path for an additional docker-compose file to be used when starting up the environment.
- ui_version, hasura_version, ... (*_version): Specific the docker image tag of the microservice to be used. For all options, see `/github-actions/setup-e2e-environment/action.yml`

Example usage:

```yaml
- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v10
  with:
    ui_version: 'docker.registry.example.org/jore4-ui:latest'
```

```yaml
steps:
- uses: HSLdevcom/jore4-tools/github-actions/setup-e2e-environment@setup-e2e-environment-v10
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
jobs:
  validate:
    uses: HSLdevcom/jore4-tools/.github/workflows/shared-check-renovatebot-config.yml@shared-check-renovatebot-config-v1
    with:
      config_file_path: renovatebot/jore4-default-preset.json5
```

To see a bit more in detail how the renovatebot rules work, check the comments within the
`jore4-default-preset.json5` file

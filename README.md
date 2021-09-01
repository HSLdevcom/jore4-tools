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

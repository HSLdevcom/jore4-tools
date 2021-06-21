# jore4-tools

Tools which are commonly used by other JORE4 projects

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

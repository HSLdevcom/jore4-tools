#!/bin/sh

set -eu

# Reads docker secrets into environment variables.
# Secrets' filenames are transformed into environment variable names with _ characters replacing non-alphanumeric characters.
#
# parameters:
# reads secrets' bash path from SECRET_STORE_BASE_PATH env variable
#
# example setup:
# $ cat secrets/foo1
# bar1
# $ cat secrets/foo2-blabla
# bar2
# $ cat secrets/foo3.lol
# bar3.lolo
#
# usage:
# $ SECRET_STORE_BASE_PATH=secrets source read-secrets.sh
# $ printenv
# [...]
# FOO1=bar1
# FOO2_BLABLA=bar2
# FOO3_LOL=bar3.lolo

# read docker secrets into environment variables
SECRET_STORE_BASE_PATH="${SECRET_STORE_BASE_PATH:-/run/secrets}"
for SECRET_FILENAME in $(ls "$SECRET_STORE_BASE_PATH");
do
    # replace non-alphanumeric characters with _ and convert to uppercase
    VAR_NAME=$(echo $SECRET_FILENAME | sed -E 's/[^a-zA-Z0-9]+/_/g' | tr a-z A-Z)
    VAR_VALUE=$(cat "$SECRET_STORE_BASE_PATH/$SECRET_FILENAME")
    export "$VAR_NAME"="$VAR_VALUE"
    echo "Found secret '$SECRET_FILENAME', exported it as '$VAR_NAME' environment variable."
done

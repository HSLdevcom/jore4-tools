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
#
# If the $SKIP_SET_VARIABLE_SECRET_OVERRIDE environment variable is set, pre-exisiting values will not be overriden by secrets.

# read docker secrets into environment variables
SECRET_STORE_BASE_PATH="${SECRET_STORE_BASE_PATH:-/run/secrets}"
for SECRET_FILENAME in $(ls "$SECRET_STORE_BASE_PATH");
do
    # replace non-alphanumeric characters with _ and convert to uppercase
    VAR_NAME=$(echo $SECRET_FILENAME | sed -E 's/[^a-zA-Z0-9]+/_/g' | tr a-z A-Z)
    if [ ! -z "${SKIP_SET_VARIABLE_SECRET_OVERRIDE-}" ] && [ ! -z "$(printenv $VAR_NAME)" ]; then
        echo "Secret environment value override disabled. Used existing value for '$VAR_NAME' environment variable."
    else
        VAR_VALUE=$(cat "$SECRET_STORE_BASE_PATH/$SECRET_FILENAME")
        export "$VAR_NAME"="$VAR_VALUE"
        echo "Found secret '$SECRET_FILENAME', exported it as '$VAR_NAME' environment variable."
    fi
done

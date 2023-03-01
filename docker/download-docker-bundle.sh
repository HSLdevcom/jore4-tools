#!/bin/bash

set -euo pipefail

# set docker bundle destination folder (default: "./docker")
export DOCKER_BUNDLE_PATH="${DOCKER_BUNDLE_PATH:-./docker}"
BUNDLE_PACKAGE_FILENAME="e2e-docker-compose.tar.gz"

echo "DOCKER_BUNDLE_PATH: $DOCKER_BUNDLE_PATH"

# check gh client availability
if ! command -v gh; then
  echo "Please install the github gh tool on your machine."
  exit 1
fi

# initialize package folder
mkdir -p "$DOCKER_BUNDLE_PATH"

echo "Downloading latest version of E2E docker-compose package..."
gh auth status || gh auth login

# make sure docker bundle directory exists and download the release package
mkdir -p "$DOCKER_BUNDLE_PATH"
gh release download e2e-docker-compose --clobber --repo HSLdevcom/jore4-tools --dir "$DOCKER_BUNDLE_PATH"

# copy and extract bundle to final directory
tar -xzf "$DOCKER_BUNDLE_PATH/$BUNDLE_PACKAGE_FILENAME" -C "$DOCKER_BUNDLE_PATH/"

# cleanup
rm "$DOCKER_BUNDLE_PATH/$BUNDLE_PACKAGE_FILENAME"

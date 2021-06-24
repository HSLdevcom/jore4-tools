#!/bin/bash

set -eu

function toc {
  echo "Refreshing Table of Contents"

  npx doctoc README.md
}

function usage {
  echo "
  Usage $0 <command>

  toc
    Refreshes the Table of Contents in the README.

  help
    Show this usage information
  "
}

case $1 in
toc)
  toc
  ;;

help)
  usage
  ;;

*)
  usage
  ;;
esac

#!/bin/bash 

RUN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${RUN_DIR}/terraform.py "$@" --root "${RUN_DIR}/.."

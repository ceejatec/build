#!/bin/bash

# Fetches a project by project name, path and Git ref
# This script is normally used in conjunction with allcommits.py:
# ./allcommits.py <change-id>|xargs -n 3 ./fetchproject.sh

set -x

set -e

PROJECT=$1
PROJECT_PATH=$2
REFSPEC=$3

if [ -z "$GERRIT_HOST" ]; then
    echo "Error: Required environment variable 'GERRIT_HOST' not set."
    exit 1
fi
if [ -z "$GERRIT_PORT" ]; then
    echo "Error: Required environment variable 'GERRIT_PORT' not set."
    exit 2
fi
if [ -z "$GERRIT_SCHEME" ]; then
    echo "Error: Required environment variable 'GERRIT_SCHEME' not set."
    exit 3
fi
if [ -z "$PROJECT" ]; then
    echo "Error: Required argument 'PROJECT' not set."
    exit 4
fi
if [ -z "$PROJECT_PATH" ]; then
    echo "Error: Required argument 'PROJECT_PATH' not set."
    exit 5
fi
if [ -z "$REFSPEC" ]; then
    echo "Error: Required argument 'REFSPEC' not set."
    exit 6
fi

if [ ! -d "$PROJECT_PATH" ];  then
    echo "$PROJECT_PATH doesn't exist, skipping..."
    exit 0
fi

pushd $PROJECT_PATH > /dev/null
git reset --hard HEAD
git fetch $GERRIT_SCHEME://$GERRIT_HOST:$GERRIT_PORT/$PROJECT $REFSPEC
git clean -d --force -x
git checkout FETCH_HEAD
popd > /dev/null

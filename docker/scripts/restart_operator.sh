#!/bin/bash

# This runs on mega3
./restart_jenkinsdocker.py --mount-docker couchbasebuild/ubuntu-1604-operator-build:20181221 operator-build 2997 server.jenkins.couchbase.com


#!/bin/sh

cd `dirname $0`

# Unit testing containers (currently hosted on mega3)
./restart_jenkinsdocker.py ceejatec/centos-70-couchbase-build:20170522 slave-centos7-unit-simple 7000 cv.jenkins.couchbase.com
./restart_jenkinsdocker.py ceejatec/ubuntu-1404-couchbase-build:20171130 slave-ubuntu14-unit-simple 7001 cv.jenkins.couchbase.com

wait
echo "All done!"

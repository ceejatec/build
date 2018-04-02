#!/bin/bash

echo "docker stop mobile-sgw-centos6"
docker stop mobile-sgw-centos6
echo "docker rm mobile-sgw-centos6"
docker rm mobile-sgw-centos6
docker run --name="mobile-sgw-centos6" -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2320:22 -d ceejatec/centos-65-sgw-build:20170627


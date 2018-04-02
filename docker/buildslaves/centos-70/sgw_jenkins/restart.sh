#!/bin/bash

container_name="mobile-sgw-centos70"
container=$(docker ps | grep $container_name | awk -F\" '{ print $1 }')
echo "container: $container"
if [[ $container ]]
then
    echo "docker rm -f $container_name"
    docker rm -f $container_name
fi

docker run --name=$container_name -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2322:22 -d ceejatec/centos-70-sgw-build:20180214

#!/bin/bash

# These platforms correspond to the available Docker buildslave images.
PLATFORMS="centos-65 centos-70 debian-8 debian-9 suse-11 suse-12 ubuntu-1404 ubuntu-1604"

usage() {
  echo "Usage: $0 <platform>"
  echo "  where <platform> is one of: ${PLATFORMS}"
  exit 1
}

# Check input argument
if [ $# -eq 0 ]
then
  usage
fi
PLATFORM=$1

sup=`echo ${PLATFORMS} | egrep "\b${PLATFORM}\b"`
if [ -z "${sup}" ]
then
  echo "Unknown platform $1"
  usage
fi

# Ensure docker
docker version > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "Docker is required to be installed!"
  exit 5
fi

heading() {
  echo
  echo ::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo $*
  echo ::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo
}

ROOT=`pwd`

# Load Docker buildslave image for desired platform
cd docker_images
IMAGE=ceejatec/$( basename -s .tar.gz $( ls ${PLATFORM}* ) )
if [[ -z "`docker images -q ${IMAGE}`" ]]
then
  heading "Loading Docker image ${IMAGE}..."
  gzip -dc ${PLATFORM}* | docker load
fi

# Run Docker buildslave
SLAVENAME="${PLATFORM}-buildslave"
cd ${ROOT}
docker inspect ${SLAVENAME} > /dev/null 2>&1
if [ $? -ne 0 ]
then
  heading "Starting Docker buildslave container..."
  docker run -d --name ${SLAVENAME} --network=none \
    -v `pwd`:/escrow \
    ${IMAGE}
fi

# Load local copy of escrowed source code into container
heading "Copying escrowed sources and dependencies into container"
docker exec -it ${SLAVENAME} rm -rf /home/couchbase/escrow
docker exec -it ${SLAVENAME} mkdir -p /home/couchbase/escrow
docker exec -it ${SLAVENAME} cp -a /escrow/in-container-build.sh \
  /escrow/deps /escrow/golang /escrow/src /home/couchbase/escrow
docker exec -it ${SLAVENAME} chown -R couchbase:couchbase /home/couchbase

# Convert Docker platform to Build platform (sorry they're different)
if [ "${PLATFORM}" = "centos-69" ]
then
  PLAT=centos6
elif [ "${PLATFORM}" = "centos-74" ]
then
  PLAT=centos7
elif [ "${PLATFORM}" = "debian-7" ]
then
  PLAT=debian7
elif [ "${PLATFORM}" = "debian-8" ]
then
  PLAT=debian8
elif [ "${PLATFORM}" = "suse-11" ]
then
  PLAT=suse11
elif [ "${PLATFORM}" = "suse-12" ]
then
  PLAT=suse12
elif [ "${PLATFORM}" = "ubuntu-1404" ]
then
  PLAT=ubuntu14.04
elif [ "${PLATFORM}" = "ubuntu-1604" ]
then
  PLAT=ubuntu16.04
fi

# Launch build process
heading "Running full Couchbase Server build in container..."
docker exec -it -u couchbase ${SLAVENAME} bash \
  /home/couchbase/escrow/in-container-build.sh ${PLAT} 5.1.0

# And copy the installation packages out of the container.
heading "Copying installer binaries"
for file in `docker exec ${SLAVENAME} bash -c \
  "ls /home/couchbase/escrow/src/*${PLAT}*"`
do
  docker cp ${SLAVENAME}:${file} .
  localfile=`basename ${file}`
  mv ${localfile} ${localfile/-9999/}
done


#!/bin/bash -e

# Error-check. This directory should exist due to the "docker run" mount.
if [ ! -e /escrow ]
then
  echo "This script is intended to be run inside a specifically-configured "
  echo "Docker container. See build-couchbase-server-from-escrow.sh."
  exit 100
fi

PLATFORM=$1
VERSION=$2
heading() {
  echo
  echo ::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo $*
  echo ::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo
}

# Set HOME - not always set via "docker exec"
export HOME=/home/couchbase

# Global directories
ROOT=/home/couchbase/escrow
CACHE=/home/couchbase/.cbdepscache

# Create all cbdeps. Start with the cache directory.
mkdir -p ${CACHE}

# Tweak the cbdeps build scripts to "download" the source from our local
# escrowed copy.
sed -i.bak \
  -e 's/\(git\|https\):\/\/github.com\/[^/]*\/\([^ ]*\)/\/home\/couchbase\/escrow\/deps\/\2/g' \
  -e 's/\.git//g' \
  ${ROOT}/src/tlm/deps/packages/CMakeLists.txt \
  ${ROOT}/src/tlm/deps/packages/*/CMakeLists.txt

# Unfortunate hack to make the jemalloc and V8 packages match the version
# expected by the Couchbase build.
sed -i.bak \
  -e 's/\(_ADD_DEP_PACKAGE(v8.*\)2/\11/' \
  -e 's/\(_ADD_DEP_PACKAGE(jemalloc\).*/\1 4.5.0.1 stable-4 1)/' \
  ${ROOT}/src/tlm/deps/packages/CMakeLists.txt

build_cbdep() {
  dep=$1
  if [ -e ${CACHE}/${dep}*.tgz ]
  then
    echo "Dependency ${dep} already built..."
    return
  fi
  heading "Building dependency ${dep}...."
  rm -rf ${ROOT}/src/tlm/deps/packages/build
  ( cd ${ROOT}/src/tlm && PACKAGE=${dep} deps/scripts/build-one-cbdep )
  echo
  echo "Copying dependency ${dep} to local cbdeps cache..."
  tarball=$( ls ${ROOT}/src/tlm/deps/packages/build/deps/${dep}/*/*.tgz )
  cp ${tarball} ${CACHE}
  cp ${tarball/tgz/md5} ${CACHE}/$( basename ${tarball} ).md5
  rm -rf ${ROOT}/src/tlm/deps/packages/build
}

# Build all dependencies.
for dep in $( cat ${ROOT}/deps/dep_list.txt )
do
  build_cbdep ${dep}
done

# Copy in all Go versions.
heading "Copying Golang versions..."
cp -a ${ROOT}/golang/* ${CACHE}

# Finally, build the Couchbase Server package.
heading "Building Couchbase Server ${VERSION} Enterprise Edition..."
${ROOT}/src/cbbuild/scripts/jenkins/couchbase_server/server-linux-build.sh \
  ${PLATFORM} ${VERSION} enterprise 9999

# Remove any "oel6" binaries to avoid confusion
rm -f ${ROOT}/src/couchbase*oel6*rpm


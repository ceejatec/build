#!/bin/sh

set -e
set -x

curdir=`dirname $0`

# CCACHE is good - use it if available.
export PATH=/usr/lib/ccache:$PATH


cat <<EOF
============================================
===              environment             ===
============================================
EOF
ulimit -a
env | grep -iv password | grep -iv passwd | sort

cat <<EOF
============================================
===                 clean                ===
============================================
EOF
sudo killall -9 beam.smp epmd memcached python >/dev/null || true
make clean-xfd-hard

cat <<EOF
============================================
===       update all projects with       ===
===          the same Change-Id          ===
============================================
EOF
${curdir}/../checkout_dependencies.py $GERRIT_PATCHSET_REVISION $GERRIT_CHANGE_ID $GERRIT_PROJECT $GERRIT_REFSPEC

cat <<EOF
============================================
===                 build                ===
============================================
EOF
make -j4

cat <<EOF
============================================
===             run dialyzer             ===
============================================
EOF
# Copy geocouch.plt from /tmp to ${WORKSPACE}/build/geocouch to gain build time
if [ -f /tmp/geocouch.plt ]
then
    cp /tmp/geocouch.plt ${WORKSPACE}/build/geocouch/
fi

cd build
make geocouch-dialyzer
cd ..

# Copy geocouch.plt from ${WORKSPACE}/build/geocouch back to /tmp so it
# can be restored
if [ -f ${WORKSPACE}/build/geocouch/geocouch.plt ]
then
    cp ${WORKSPACE}/build/geocouch/geocouch.plt /tmp/
fi

cat <<EOF
============================================
===        run geocouch unit tests       ===
============================================
EOF
make geocouch-build-for-testing -j4
cd build/geocouch-for-tests
make test
cd ../../

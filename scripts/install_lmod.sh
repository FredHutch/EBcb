#!/bin/bash

set -x
set -e

# variables used: LMOD_VER, DEPLOY_PREFIX
echo "LMOD_VER is ${LMOD_VER}"
echo "DEPLOY_PREFIX is ${DEPLOY_PREFIX}"

# try to preserve group write here
umask 002

# Get Lmod
cd /tmp
echo "Downloading Lmod..."
curl -L -o Lmod-${LMOD_VER}.tar.gz https://github.com/TACC/Lmod/archive/${LMOD_VER}.tar.gz

echo "Extracting Lmod..."
tar -xzf Lmod-${LMOD_VER}.tar.gz

echo "Building Lmod..."
cd Lmod-${LMOD_VER}
./configure --prefix=${DEPLOY_PREFIX} --with-tcl=no ${LMOD_CONFIGURE}
make install

mkdir ${DEPLOY_PREFIX}/lmod/cache \
&& chown $LS2_UID.$LS2_GID ${DEPLOY_PREFIX}/lmod/cache \
&& chmod g+ws ${DEPLOY_PREFIX}/lmod/cache
export LMOD_CACHE_DIR=${DEPLOY_PREFIX}/lmod/cache

# Clean up
cd ..
rm -r Lmod-${LMOD_VER}
rm Lmod-${LMOD_VER}.tar.gz

#!/bin/bash

set -x
set -e

# variables used: LMOD_VER, PREFIX
echo "LMOD_VER is ${LMOD_VER}"
echo "PREFIX is ${PREFIX}"

# Create module and cache directories
mkdir -p ${PREFIX}/modules/all
mkdir -p ${PREFIX}/lmod/cache
chmod g+ws ${PREFIX}/lmod/cache
export LMOD_CACHE_DIR=${PREFIX}/lmod/cache

# try to preserve group write here
umask 002

# Get Lmod
cd $PREFIX
echo "Downloading Lmod..."
curl -L -o Lmod-${LMOD_VER}.tar.gz https://github.com/TACC/Lmod/archive/${LMOD_VER}.tar.gz

echo "Extracting Lmod..."
tar -xzf Lmod-${LMOD_VER}.tar.gz

echo "Building Lmod version ${LMOD_VER}..."
cd Lmod-${LMOD_VER}
./configure --prefix=${PREFIX}\
 --with-tcl=no \
 --with-module-root-path=${PREFIX}/modules/all\
 --with-ModulePathInit=/app/modules/all \
 --with-spiderCacheDir=${PREFIX}/lmod/cache \
 --with-updateSystemFn=${PREFIX}/lmod/cache/last_updat

# install
make install

# Clean up
cd ${PREFIX}
rm -r Lmod-${LMOD_VER}
rm Lmod-${LMOD_VER}.tar.gz

#!/bin/bash

set -x
set -e

# argument is install prefix
PREFIX=/eb
echo "PREFIX is ${PREFIX}"

# variables used: LMOD_VER
echo "LMOD_VER is ${LMOD_VER}"

# try to preserve group write here
umask 002

# Get Lmod
cd $PREFIX 
echo "Downloading Lmod..."
curl -L -o Lmod-${LMOD_VER}.tar.gz https://github.com/TACC/Lmod/archive/${LMOD_VER}.tar.gz

echo "Extracting Lmod..."
tar -xzf Lmod-${LMOD_VER}.tar.gz

echo "Building Lmod..."
cd Lmod-${LMOD_VER}
./configure --prefix=${PREFIX} --with-tcl=no ${LMOD_CONFIGURE}
make install

mkdir ${PREFIX}/lmod/cache \
&& chown $LS2_UID.$LS2_GID ${PREFIX}/lmod/cache \
&& chmod g+ws ${PREFIX}/lmod/cache
export LMOD_CACHE_DIR=${PREFIX}/lmod/cache

# Clean up
cd ..
rm -r Lmod-${LMOD_VER}
rm Lmod-${LMOD_VER}.tar.gz

#!/bin/bash

set -x
set -e

# reuired arguments LMOD_VER CB_PREFIX
if [[ -z ${LMOD_VER} ]]; then
    echo "== environment variable LMOD_VER must be set. example export LMOD_VER=8.7.60"
    exit 1
else
    echo "== LMOD_VER is ${LMOD_VER}"
fi
if [[ -z ${CB_PREFIX} ]]; then
    echo "== environment variable CB_PREFIX must be set. '/eb | /app'"
    exit 1
else
    echo "CB_PREFIX is ${CB_PREFIX}"
fi

# Create module and cache directories
mkdir -p ${CB_PREFIX}/modules/all
mkdir -p ${CB_PREFIX}/lmod/cache
mkdir -p ${CB_PREFIX}/lmod/etc
chmod g+ws ${CB_PREFIX}/lmod/cache ${CB_PREFIX}/lmod/etc
export LMOD_CACHE_DIR=${CB_PREFIX}/lmod/cache

# try to preserve group write here
umask 002

# Get Lmod
cd ${CB_PREFIX}/lmod
if [[ ! -f "${LMOD_VER}.tar.gz" ]]; then
    echo "== Downloading Lmod..."
    curl -L -o Lmod-${LMOD_VER}.tar.gz https://github.com/TACC/Lmod/archive/${LMOD_VER}.tar.gz
else
    echo '== found source file; skipping download'
fi

echo "== Extracting Lmod..."
tar -xzf Lmod-${LMOD_VER}.tar.gz

echo "== Building Lmod version ${LMOD_VER}..."
cd Lmod-${LMOD_VER}
./configure --prefix=${CB_PREFIX}\
 --with-lmodConfigDir=${CB_PREFIX}/lmod/etc\
 --with-siteName="hutch"\
 --with-colorize=yes\
 --with-tcl=no \
 --with-disableNameAutoSwap=yes\
 --with-module-root-path=${CB_PREFIX}/modules/all\
 --with-ModulePathInit=/app/modules/all \
 --with-spiderCacheDir=${CB_PREFIX}/lmod/cache \
 --with-updateSystemFn=${CB_PREFIX}/lmod/cache/last_update

# install
make install

# configure local SitePackage.lua  ${BUILD_DIR}
echo Is BUILD_DIR set? ${BUILD_DIR}
cp /build/scripts/SitePackage.lua ${CB_PREFIX}/lmod/${LMOD_VER}/libexec/SitePackage.lua
cp /build/scripts/lmod_config.lua ${CB_PREFIX}/lmod/etc

# Clean up
rm -r ${CB_PREFIX}/lmod/Lmod-${LMOD_VER}
rm ${CB_PREFIX}/lmod/Lmod-${LMOD_VER}.tar.gz

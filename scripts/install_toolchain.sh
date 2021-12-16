#!/bin/bash

# install Toolchain with EasyBuild 

export PREFIX=$1
export BUILD_DIR=$2
export TOOLCHAIN=$3

# try to preserve group write here
umask 002

# load modules
source ${PREFIX}/lmod/lmod/init/profile
module use ${PREFIX}/modules/all

# load Easybuild
module load EasyBuild

echo EASYBUILD_SOURCEPATH: ${EASYBUILD_SOURCEPATH}

# build the easyconfig file
eb -l ${TOOLCHAIN}.eb --robot

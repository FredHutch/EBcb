#!/bin/bash

# install Toolchain with EasyBuild 

export EB_VER=$1
export TOOLCHAIN=$2
export PREFIX=$3
export BUILD_DIR=$4

# try to preserve group write here
umask 002

# load modules
source ${PREFIX}/lmod/lmod/init/profile
module use ${PREFIX}/modules/all

# load Easybuild
module load EasyBuild

echo EASYBUILD_SOURCEPATH: ${EASYBUILD_SOURCEPATH}
eb -l ${TOOLCHAIN}.eb --robot

# Toolchain and EasyBuild are installed to /eb
# After installing Toolchain reconfigure EasyBuild install dir to /app
if [[ -f "${PREFIX}/modules/all/EasyBuild/${EB_VER}.orig" ]]
then
    cp ${PREFIX}/modules/all/EasyBuild/${EB_VER}.orig ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
    cat ${BUILD_DIR}/scripts/app_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
else
    echo Could not find EB.orig LMOD!
    touch ${PREFIX}/modules/all/EasyBuild/${EB_VER}.orig
fi

#!/bin/bash

set -x
set -e

# variables used: TOOLCHAIN, DEPLOY_PREFIX

# try to preserve group write here
umask 002

# load modules
source ${PREFIX}/lmod/lmod/init/bash
module use ${PREFIX}/modules/all

# load Easybuild
module load EasyBuild

echo EASYBUILD_SOURCEPATH: ${EASYBUILD_SOURCEPATH}

# build the easyconfig file
eb -l ${TOOLCHAIN}.eb --robot

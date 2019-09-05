#!/bin/bash

set -x
set -e

# variables used: TOOLCHAIN, DEPLOY_PREFIX

# try to preserve group write here
umask 002

# load modules
source ${DEPLOY_PREFIX}/lmod/lmod/init/bash
module use ${DEPLOY_PREFIX}/modules/all

# load Easybuild
module load EasyBuild

# sometimes needed to provide source that has become unavailable
export EASYBUILD_SOURCEPATH=${EASYBUILD_SOURCEPATH}:/ls2/sources

# build the easyconfig file
eb -l ${TOOLCHAIN}.eb --robot


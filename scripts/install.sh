#!/bin/bash

set -x
set -e

# variables used: EB_NAME, DEPLOY_PREFIX

# try to preserve group write here
umask 002

# load modules
export MODULEPATH=/app/modules/all
source ${DEPLOY_PREFIX}/lmod/lmod/init/bash
module use ${DEPLOY_PREFIX}/modules/all

# load Easybuild
module load EasyBuild

# build the easyconfig file
eb -l ${EB_NAME}.eb --robot

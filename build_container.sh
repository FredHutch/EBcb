#!/bin/bash

# build the EasyBuild container
# source set_env.sh first to setup environment

if [[ -z "${EBUSER_UID}" || -z "${EBUSER_GID}" ]]; then echo EBUSER_UID EBUSER_GID must be set 
    echo source ./set_env.sh # Configure EasyBuild container
    exit 1
fi 

if [[ -a ${EB_VER} ]]; then echo EB_VER must be set
    exit 1
fi 
if [[ -z ${TOOLCHAIN} ]]; then echo TOOLCHAIN must be set
   exit 1
fi

tag=fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN}
echo Creating Container ${tag}
export LMOD_VER='8.3.10'
# docker build . --no-cache --tag ${tag} \ 
docker build .             --tag ${tag} \
  --build-arg EBUSER_UID=${EBUSER_UID} \
  --build-arg EBUSER_GID=${EBUSER_GID} \
  --build-arg DEPLOY_PREFIX=/eb \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TOOLCHAIN=${TOOLCHAIN}

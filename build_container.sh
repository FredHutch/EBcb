#!/bin/bash

# build the EasyBuild container
# source set_env.sh first to setup environment

# Customize the file permissions to your local site.
# Set the environment variables EBUSER_UID and EBUSER_GID to the UID:GID of your local repository owner
# Configure your sites UID:GID in the script set_uid.sh

if [[ -z "${EBUSER_UID}" || -z "${EBUSER_GID}" ]]; then
    if [[ -f scripts/set_uid.sh ]]; then
        source set_uid.sh
    else
        echo EBUSER_UID EBUSER_GID must be set 
        echo Set the environment variables EBUSER_UID and EBUSER_GID to the UID:GID of your local repository owner.
        echo Create a bash script set_uid.sh to set your UID GID of your repository owner
        echo export EBUSER_UID=
        echo export EBUSER_GID=
        exit 1
    fi
fi 
echo Repo Owner UID: $EBUSER_UID

export LMOD_VER='8.3.10'
export EB_VER='4.3.1'
export TOOLCHAIN='foss-2020b'

tag=fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN}
echo Creating Container ${tag}
#docker build . --no-cache --tag ${tag}
docker build .             --tag ${tag}\
  --build-arg EBUSER_UID=${EBUSER_UID} \
  --build-arg EBUSER_GID=${EBUSER_GID} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TOOLCHAIN=${TOOLCHAIN} \
  --build-arg TZ='America/Los_Angeles'

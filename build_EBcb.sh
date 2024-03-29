#!/bin/bash

# build the EasyBuild container
# source set_env.sh first to setup environment

# Customize the file permissions to your local site.
# Set the environment variables EBUSER_UID and EBUSER_GID to the UID:GID of your local repository owner
# Configure your sites UID:GID in the script set_uid.sh

if [[ $# -eq 0 ]]; then
    echo "Dockerfile name required as argument"
    exit 1
fi

eb_vars='EBUSER_UID
EBUSER_GID
LMOD_VER
EB_VER
TOOLCHAIN'

for eb_var in ${eb_vars}; do
    read -p "Enter $eb_var [${!eb_var}]: " value
    if [[ ! -z "${value}" ]]; then
         eval $eb_var=${value}
    fi
    if [[ -z "${!eb_var}" ]]; then
        echo ${eb_var} must be set 
        exit 1
    fi
    echo ${eb_var}=${!eb_var}
done

tag=fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN}
echo Creating Container ${tag} from Dockerfile: $1
#docker build . --file $1 --no-cache --tag ${tag}\
docker build . --file $1            --tag ${tag}\
  --build-arg EBUSER_UID=${EBUSER_UID} \
  --build-arg EBUSER_GID=${EBUSER_GID} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TOOLCHAIN=${TOOLCHAIN} \
  --build-arg TZ='America/Los_Angeles' \
  --build-arg LANG='en_US.UTF-8'

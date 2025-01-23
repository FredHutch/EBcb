#!/bin/bash

# build the EasyBuild container
# usage: build_ebcb.sh [Dockerfile] 

# Set these environment variables to control how the container is built. 
#  BUILD_HOSTS - list of machines with Docker installed that can be used as build hosts
#  EBUSER_UID and EBUSER_GID to the UID:GID of your local repository owner
#  LMOD_VER
#  EB_VER=${EB_VER} \
#
# Local customization of these variables is done with scripts/set_env.sh 

if [[ $# -eq 0 ]]; then
    echo "Dockerfile name required as argument"
    exit 1
fi

if [[ ! -z "${BUILD_HOSTS}" ]]; then
    echo environment BUILD_HOSTS must be defined as a list of build machines.
    exit 1
fi

host=`uname -n`
if  [[ ! $BUILD_HOSTS =~ $host  ]]; then
    echo Not an EBcb host. This script must be run from : $BUILD_HOSTS
    exit 1
fi
eb_cfg_file=${host}.cfg
echo Using Config file: $eb_cfg_file

os_version=`grep VERSION_ID /etc/os-release`
[[ $os_version == *"18.04"* ]] && OS=bionic
[[ $os_version == *"24.04"* ]] && OS=noble

grep -q GenuineIntel /proc/cpuinfo
if [[ $? == 0 ]]; then
    flags=`grep ^flags /proc/cpuinfo | sort -u | sed 's/^.*: //'`
    for feature in $flags; do 
        [[ $feature == 'avx2' ]] && AVX2=TRUE
        [[ $feature == "avx512"* ]] && AVX512=TRUE
    done
    if [[ $AVX512 == "TRUE" ]]; then
        ARCH=skylake
    elif [[ $AVX2 == "TRUE" ]]; then
        ARCH=haswell
    fi
fi

grep -q EPYC /proc/cpuinfo
[[ $? == 0 ]] && ARCH=zen4


eb_vars='EBUSER_UID
EBUSER_GID
LMOD_VER
EB_VER'

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

[[ ! -z "${TAG}" ]] && echo Warning: TAG is set: $TAG

tag=fredhutch/ls2:${OS}-${ARCH}-eb.${EB_VER}${TAG}
echo Creating Container ${tag} from Dockerfile: $1
# docker build . --file $1            --tag ${tag}\
docker build . --file $1 --no-cache --tag ${tag}\
  --build-arg EB_CFG=${eb_cfg_file} \
  --build-arg EBUSER_UID=${EBUSER_UID} \
  --build-arg EBUSER_GID=${EBUSER_GID} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TZ='America/Los_Angeles' \
  --build-arg LANG='en_US.UTF-8' \
  --build-arg LANGUAGE='en_US.UTF-8'

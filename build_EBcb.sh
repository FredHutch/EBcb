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
# docker build . --file $1 --no-cache --tag ${tag}\
docker build . --file $1            --tag ${tag}\
  --build-arg EBUSER_UID=${EBUSER_UID} \
  --build-arg EBUSER_GID=${EBUSER_GID} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TZ='America/Los_Angeles' \
  --build-arg LANG='en_US.UTF-8' \
  --build-arg LANGUAGE='en_US.UTF-8'

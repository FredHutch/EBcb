#!/bin/bash

# Start EasyBuild container EBcb

if [ "$#" -ne 1 ]; then
    echo "Usage: run_deply container_name"
    exit 1
fi

env_vars='TOOLCHAIN EB_VER BUILD_DIR SOURCE_DIR'
for var in $env_vars; do
    if [[ -z "${!var}" ]]; then 
         echo $var not set ; exit
    else
         echo Using $var: ${!var}
    fi
done

containerName=${TOOLCHAIN:5}-${EB_VER}-$1

echo Starting: fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} as ${containerName}

docker run --gpus all --rm -ti --name ${containerName} --hostname $1 \
 --security-opt="seccomp=unconfined" \
 --env EASYCONFIG=foo \
 -v /app:/app \
 -v ${SOURCE_DIR}:/sources \
 -v ${BUILD_DIR}:/build \
 fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} bash 

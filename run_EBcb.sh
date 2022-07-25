#!/bin/bash

# Start EasyBuild container EBcb

if [ "$#" -ne 1 ]; then
    echo "Usage: run_deply container_name"
    exit 1
fi

[[ -z "${TOOLCHAIN}" ]] && { echo 'TOOLCHAIN env not set' ; exit; }
[[ -z "${EB_VER}" ]] && { echo 'EB_VER env not set' ; exit; }

containerName=${TOOLCHAIN:5}-${EB_VER}-$1

echo Starting: fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} as ${containerName}

docker run --gpus all --rm -ti --name ${containerName} --hostname $1 \
 --security-opt="seccomp=unconfined" \
 --env EASYCONFIG=foo \
 -v /app:/app \
 -v /fh/scratch/delete10/_ADM/SciComp/eb_build:/build \
 fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} bash 

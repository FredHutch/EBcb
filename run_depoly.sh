#!/bin/bash

[[ -z "${TOOLCHAIN}" ]] && { echo 'TOOLCHAIN not set' ; exit; }
[[ -z "${EB_VER}" ]] && { echo 'EB_VER not set' ; exit; }

if [[ $# -eq 1 ]]; then
    containerName=${TOOLCHAIN:5}-${EB_VER}-$1
else
    containerName=${TOOLCHAIN:5}-${EB_VER}
fi

echo Starting: fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} as ${containerName}

docker run --gpus all --rm -ti --name ${containerName} \
 --security-opt="seccomp=unconfined" \
 -v /app:/app \
 fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} bash 

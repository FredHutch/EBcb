#!/bin/bash

[[ -z "${TOOLCHAIN}" ]] && { echo 'TOOLCHAIN not set' ; exit; }
[[ -z "${EB_VER}" ]] && { echo 'EB_VER not set' ; exit; }

docker run --rm -ti --name ${TOOLCHAIN:5}-${EB_VER} \
 --security-opt="seccomp=unconfined" \
 -v /app:/app \
 fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} bash 

#!/bin/bash


docker run --rm -ti --name ${TOOLCHAIN#"foss-"} \
 --security-opt="seccomp:unconfined" \
 -v /app:/app \
 fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} bash 

#!/bin/bash

# Develop run as the scicomp user 6514

docker run -ti --name 2018b \
 -d \
 --security-opt seccomp:unconfined \
 -e OUT_UID=6514 \
 -e OUT_GID=6514 \
 -e DEPLOY_PREFIX=/app \
 -e outside_user=6514 \
 -e outside_group=6514 \
 -v /app:/app,readonly \
 fredhutch/ls2:eb-3.9.3-foss-2018b bash 


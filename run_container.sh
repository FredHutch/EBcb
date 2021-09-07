#!/bin/bash

# Run the container in test mode mode. Write software to local /app
docker run --rm -ti --name 2020b \
 --detach \
 --security-opt seccomp=unconfined \
 fredhutch/ls2:eb-4.4.1-foss-2020b

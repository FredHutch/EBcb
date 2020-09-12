#!/bin/bash

# Run the container in test mode mode. Write software to local /app
docker run --rm -ti --name 2019b \
 --detach \
 --security-opt seccomp=unconfined \
 fredhutch/ls2:eb-4.2.2-foss-2019b

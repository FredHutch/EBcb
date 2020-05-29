#!/bin/bash


docker run --rm -ti --name 2019b \
 --security-opt="seccomp:unconfined" \
 -v /app:/app \
 fredhutch/ls2:eb-4.2.1-foss-2019b bash 

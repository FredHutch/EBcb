#!/bin/bash

# Start EasyBuild container EBcb

if [ "$#" -ne 1 ]; then
    echo "Usage: run_deply container_name"
    exit 1
fi
name=$1

prefix="fredhutch/ls2"
list=`docker images | grep ls2 | sort | awk '{print $2}'`

n=1
for image in $list; do
   echo "$n ) $image"
   n=$(( $n + 1 ))
done
echo
echo -n "Select Container: "
read number

set -- $list
containerName=${prefix}:${!number}
echo Starting: ${containerName}  as ${containerName}-$name

docker run --gpus all --rm -ti --name "${!number}-$name" --hostname $name \
 --security-opt="seccomp=unconfined" \
 --env EASYCONFIG=foo \
 -v /app:/app \
 -v ${SOURCE_DIR}:/sources \
 -v ${BUILD_DIR}:/build \
 ${containerName} bash 

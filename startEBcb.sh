#!/bin/bash

# Start EBcb container 

if [ "$#" -ne 1 ]; then
    echo "Usage: " `basename "$0"` " container_name"
    exit 1
fi
name=$1

env_vars='BUILD_DIR SOURCE_DIR'
for var in $env_vars; do
    if [[ -z "${!var}" ]]; then
         echo $var not set ; exit
    else
         echo Using $var: ${!var}
    fi
done

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
echo Starting: ${containerName}  as $name

docker run --gpus all --rm -ti --name $name --hostname $name \
 --security-opt="seccomp=unconfined" \
 --env EASYCONFIG=foo \
 -v /app:/app \
 -v ${SOURCE_DIR}:/sources \
 -v ${BUILD_DIR}:/build \
 ${containerName} bash 

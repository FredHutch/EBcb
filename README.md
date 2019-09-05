# EBcb - EasyBuild Container Build

### Overview
EBcb project aims to normalize and automate the building of
Life Sciences Software software packages. The Hutch
uses this method along with EasyBuild to manage our scientific software install
archive.

EasyBuild provides a framework for building scientific software which can be
documented and reproduced. EBcb creates a container with EasyBuild which can be
used to test and build EasyConfigs. Building all software with a container provides
a consistent, reproducible method of for building software. In practice
a new container instance is run for each package to ensure reproducibility of
software. The same container is used for testing and deploying software defined by
EasyConfigs. To deploy an EasyBuild config into production run the
container with a mapped volume to your sites software repository. In testing the
results are written withing the container without producing side effects.

### Building the Container
The Dockerfile uses environment variables to specify all the parameters of the
the build. Edit the values in the script ```set_env.sh``` to configure your
environment. In use the script should be sourced.
```
source set_env.sh
```
The UID/GID of the container users are also
passed to the Docker file as environment variables. The UID/GID should be set
to a non-root user that owns your software repository. The destination location
for software builds is defined with ```DEPLOY_PREFIX``` this defaults to
```/app```, which should be changed base on your sites software repository.
The base OS can also be customized to your local site. Example of how to build
the container.

```
docker build . --no-cache --tag fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} \
  --build-arg LS2_UID=${UID}\
  --build-arg LS2_GID=${GID}\
  --build-arg DEPLOY_PREFIX=${DEPLOY_PREFIX} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TOOLCHAIN=${TOOLCHAIN}
```

### Deploy new software package to /app (our NFS software archive)
We keep our deployed software package on an NFS volume that we mount at /app. In order to use your recently
build EBcb software package container to deploy the same package into our /app NFS volume, use these steps:

1. Complete above steps to produce a successful container with your software package
1. Run that container with our package deploy location mapped in to /app like this: `docker run -ti --rm --user root -v /app:/app -e OUT_UID=${UID} -e OUT_GID=<outside GID=158372> fredhutch/ls2_<eb_pkg_name>:<eb_pkg_ver> /bin/bash /ls2/deploy.sh`

The steps above will use the container you just built, but will re-build the easyconfig and all dependencies into the "real" /app, using Lmod, EasyBuild, and dependent packages from the "real" /app.

Note that this overrides the Lmod in the container, so if version parity is important to you, you'll always want to keep your /app Lmod in sync with the LS2 Lmod. You can deploy Lmod to /app using the [LS2 Lmod repo](https://github.com/FredHutch/ls2_lmod).

Details: take a look into the scritps, but this procedure re-runs the build step from the Dockerfile as root in order to install/uninstall OS packages, and adjusts the uid/gid to match your deployment outside the container.

Assumptions: /app exists, and you have already deployed the EasyBuild package into /app.

### Example R Build
Build the EBcb container with the following setup, the UID and DEPLOY are not
important for the demo build of R.
```
export cUID=6514 # (scicomp)
export cGID=6514 # (g_scicomp)
export EB_VER='3.9.4'
export LMOD_VER='7.8'
export TOOLCHAIN='foss-2018b'
docker build . --no-cache --tag fredhutch/ls2:eb-${EB_VER}-${TOOLCHAIN} \
  --build-arg LMOD_VER=${LMOD_VER} \
  --build-arg EB_VER=${EB_VER} \
  --build-arg TOOLCHAIN=${TOOLCHAIN}
# the build could take a few hours
```
Start the container and connect to it. (your container name may differ)
```
docker run -ti --name 2018b  -d --security-opt seccomp:unconfined  \
    fredhutch/ls2:eb-3.9.4-foss-2018b bash

docker exec -ti 2018b bash
cd /ls2
./install_R.sh
```
After a few hours the run will fail because it cannot file
**jdk-8u212-linux-x64.tar.gz**.  Download the Java JDK from Oracle
and use Docker cp to it to the container. From inside the container
rerun the install_R.sh to continue.  The build will resume where from where
it failed. A few hours later you will a working R install with over 600
packages.



# EBcb
EasyBuild Container Build 

### Overview
EBcb creates a container with Lmod and Easybuild which can be used to test and build Easyconfigs. The container build allows control of the OS, lua,
Lmod, EasyBuild and Toolchain versions.

### Using the Container


### Deploy new software package to /app (our NFS software archive)
We keep our deployed software package on an NFS volume that we mount at /app. In order to use your recently
build EBcb software package container to deploy the same package into our /app NFS volume, use these steps:

1. Complete above steps to produce a successful container with your software package
1. Run that container with our package deploy location mapped in to /app like this: `docker run -ti --rm --user root -v /app:/app -e OUT_UID=${UID} -e OUT_GID=<outside GID=158372> fredhutch/ls2_<eb_pkg_name>:<eb_pkg_ver> /bin/bash /ls2/deploy.sh`

The steps above will use the container you just built, but will re-build the easyconfig and all dependencies into the "real" /app, using Lmod, EasyBuild, and dependent packages from the "real" /app.

Note that this overrides the Lmod in the container, so if version parity is important to you, you'll always want to keep your /app Lmod in sync with the LS2 Lmod. You can deploy Lmod to /app using the [LS2 Lmod repo](https://github.com/FredHutch/ls2_lmod).

Details: take a look into the scritps, but this procedure re-runs the build step from the Dockerfile as root in order to install/uninstall OS packages, and adjusts the uid/gid to match your deployment outside the container.

Assumptions: /app exists, and you have already deployed the EasyBuild package into /app.

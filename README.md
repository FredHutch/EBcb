# EBcb - EasyBuild Container Build

### Overview
EBcb project aims to normalize and automate the building of
Life Sciences Software packages with Docker containers. Fred Hutch
uses this method along with EasyBuild to manage our scientific software library.

EasyBuild provides a framework for building scientific software which can be
documented and reproduced. EBcb is a containerized build platform which uses EasyBuild for
testing and building EasyConfigs. Building software in a container provides
a clean room for building software;
a consistent, reproducible build environment. In practice
a new container instance is run for each package to ensure reproducibility of
software. The same container is used for testing and deploying software defined by
EasyConfigs. To deploy an EasyBuild config into production run the
container with a mapped volume to your site software repository. In testing, the
results are written within the container without producing side effects.

### Container Design
EasyBuild, LMOD and a complete toolchain are install into the directory ```/eb```. The build environment inside the container is owned by the account eb_user. The eb_user UID/GID is to be mapped to your site softwware repository owner. EasyBuild does not run as root. After buiding the container, it can be used to
run EasyBuild. Start the container and become the eb_user. The user account
environment is configured and ready to use EasyBuild.

```
source set_env.sh
./run_container.sh
docker exec -ti eb-4.2.1-foss-2019b bash
sudo su - eb_user
```

LMOD is configured to search /eb/modules/all:/app/modules/all for modules. Easybuild is configured to write new packages into ```/app```.

In test mode EasyBuild writes to the local container file sysetm to ```/app```. In depoly mode, map /app in the container to your site software repository.

### Building the Container
The Dockerfile uses environment variables to specify all the parameters of the
the build. Edit the values in the script ```set_env.sh``` to configure your
environment. In use the script should be sourced. Create your own set_env.sh from set_env.demo. The following variables need to be definded before building a container. The UID/GID should be set to a non-root user that owns your software repository. The TOOLCHAIN should be set to the EasyBuild toolchain you have decided to use.

```
export EBUSER_UID=65535
export EBUSER_GID=65535
export TZ='America/Los_Angeles'
export EB_VER='4.2.1'
export TOOLCHAIN='foss-2019b'
```

To build the container;
```
source set_env.sh
build_container.sh
```

#### Sources available at build time and run time.
In some cases, you may need to “seed in” manually downloaded source files into the container
build environment, because the sources can not be downloaded automatically. 
Source files from the ```sources``` directory will be seeded int the the build environment.
All files in ```sources``` directory are copied into the container build environment at location
```/ls2/sources```.  The ```/ls2/sources``` path is added to *EASYBUILD_SOURCEPATH* making
 the sources available to EasyBuild during container build time.

During run time of the container, sources are searched in ```/app/sources```. If sources
are not available at run time, they can be copied into the container with ```Docker cp``` command. 

### Deploy new software package to /app (our site software archive)
We keep our deployed software repository on an NFS volume that we mount at /app. 
In order to use your recently build EBcb software package container to deploy
the same package into our /app NFS volume, user ```run_deploy.sh```.

The steps above will use the container you just built, but will re-build the easyconfig and all dependencies into the "real" /app, using Lmod, EasyBuild, and dependent packages from the "real" /app.

Note that the container has it own version of Lmod. Version parity is important so you will always want to keep your /app Lmod in sync with the EBcb Lmod. Edit the ```build_container.sh``` to change the LMOD version in EBcb.

### Example R Build
Build the EBcb container with the following setup, the UID and DEPLOY are not
important for this demo build of R.

Start the container and connect to it. (your container name may differ)
```
docker run -ti --name 2019b  -d --security-opt seccomp:unconfined  \
    fredhutch/ls2:eb-4.2.1-foss-2019b bash

docker exec -ti 2019b bash
cd /ls2
./install_R.sh
```

After a few hours the run will fail because it cannot find file
**jdk-8u212-linux-x64.tar.gz**.  Download the Java JDK from Oracle
and use Docker copy command to put the source tarball in the container.
```docker cp jdk-8u212-linux-x64.tar.gz 2019b:/ls2``` From inside the container
rerun the install_R.sh to continue.  The build will resume where from where
it failed. A few hours later you will have a working R install with hundreds of
packages.

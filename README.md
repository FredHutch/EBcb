# EBcb - EasyBuild Container Build


# Overview
EBcb aims to normalize the building of scientific software by containerizing EasyBuild.

EBcb is a containerized build platform that uses EasyBuild for
testing and building EasyConfigs.
EBcb controls the build environment, and EasyBuild easyconfigs control the
build requirements of the scientific software.

EasyBuild uses toolchains which is a collection of build tools and system libraries.
EBcb containers have EasyBuild software installed with a ToolChain. EBcb instance
can build Easyconfigs without using any native OS build tools.

### Cleanroom
Running EasyBuild in a container provides many benefits.
Building software in a container is a cleanroom approach for building software.
The process of building software can contaminate the build environment by pulling
in additional packages and leaving artifacts in the OS environment. Building each
EasyConfig from a fresh container eliminates from previous builds.

The same container is used for testing and deploying easyconfigs.
For production deployment of easyconfig map EBcb:/app volume to your production /app.

### Container Design
EasyBuild, LMOD and a complete toolchain are install into the directory ```/eb```. 
The build environment inside the container is owned by the account eb_user. 
The eb_user UID/GID needs to be mapped to your sites softwware repository owner.
EasyBuild does not run as root. The eb_user's environment is
configured to use EasyBuild.

EBcb is created with a multistage build. A full development environment is required to build EasyBuild 
and a ToolChain. But the OS build tools are not desierable to have present when using EasyBuild
to build software.

#### First Stage
  - OS packages
  - Install build-utilites (chicken and egg) Toolchain can't be built without Build-Utils
  - Install Ubuntu Python3 and pip, make Python3 the default at the OS level

  With one single Run command create /eb volume which contains EasyBuild and toolchain
    - install EasyBuild and configure to build all modules in /eb
    - configure EasyBuild with /etc/easybuild.d/config.c
    - install LMOD in /eb/modules
    - install and build toolchain in /eb/software
    - re-configure EasyBuild to build all modules in /app
    - configure EasyBuild with /app/easybuild/config.c

#### Second Stage
  - Create EasyBuild user and group.  eb_user is mapped to local /app owner
  - Install OS packages (sans Build-Utils)
  - Install Python3 and make default
  - Copy /eb from first stage
  - Finished container has no artificats from building with Build-Utils
  - Will use tools found in /eb to create new modules in /app


```
source scripts/set_uid.sh
./run_container.sh
docker exec -ti eb-4.2.1-foss-2019b bash
# Become the Easybuild user from the root account in the container.
su - eb_user
```

LMOD is configured to search /eb/modules/all:/app/modules/all for modules. Easybuild is configured to write new packages into ```/app```.

In test mode EasyBuild writes to the local container file sysetm to ```/app```. In depoly mode, map /app in the container to your site software repository.

### Building the Container
The Dockerfile uses environment variables to specify all the parameters of the
the build. Edit the values in the script ```scripts/set_uid.sh``` to configure your
environment. In use the script should be sourced. Create your own scripts/set_uid.sh from ```scripts/set_uid.demo```. The following variables need to be definded before building a container. The UID/GID should be set to a non-root user that owns your software repository. The TOOLCHAIN should be set to the EasyBuild toolchain you have decided to use.

```
export EBUSER_UID=65535
export EBUSER_GID=65535
export TZ='America/Los_Angeles'
export EB_VER='4.5.1'
export TOOLCHAIN='foss-2021b'
```

To build the container;
```
source scripts/set_uid.sh
build_container.sh
```

#### Sources available at build time and run time.
In some cases, you may need to “seed” manually downloaded source files into the container
build environment, because the sources can not be downloaded automatically. 
Source files from the ```sources``` directory will be seeded into the the build environment.
All files in ```sources``` directory are copied into the container build environment at location
${BUILD_DIR} which is defined as `/build`. The ```/build/sources``` path is added to *EASYBUILD_SOURCEPATH* making
 the sources available to EasyBuild during container build time.

During run time of the container, sources are searched in ```/app/sources```. If sources
are not available at run time, they can be copied into the container with ```Docker cp``` command. 

### Deploy new software package to /app (our site software archive)
We keep our deployed software repository on an NFS mounted at /app. 
In order to use your recently built EBcb software package container to deploy
the same package into our /app NFS volume, user ```run_deploy.sh```.

The steps above will use the container you just built, but will re-build the easyconfig and all dependencies into the "real" /app, using Lmod, EasyBuild, and dependent packages from the "real" /app.

Note that the container has it own version of Lmod. Version parity is important so you will always want to keep your /app Lmod in sync with the EBcb Lmod. Edit the ```build_container.sh``` to change the LMOD version in EBcb.

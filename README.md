### Overview
EBcb aims to normalize the building of scientific software by containerizing EasyBuild.

EBcb is a containerized build platform that uses EasyBuild for
testing and building EasyConfigs.
EBcb controls the build environment, and EasyBuild easyconfigs control the
build requirements of the scientific software.

EasyBuild uses toolchains which is a collection of build tools and libraries.
EBcb containers have EasyBuild software installed with a ToolChain. EBcb instance can build Easyconfigs without using any native OS build tools.

#### Cleanroom Methology
EBcb provides a cleanroom approach for installing software.
The process of building software can contaminate the build environment by pulling
in additional packages and leaving artifacts in the OS environment. EBcb at the Fred Hutch has provided a consistent, repeatable environment for building EasyConfigs by combining an EasyConfige with a tagged container.
```
fredhutch/ls2:eb-4.0.3-foss-2019b   cfdd57f673ef
fredhutch/ls2:eb-4.5.4-foss-2020b   d49b971f15bb
fredhutch/ls2:eb-4.6.0-foss-2021b   51fa37926564
```
### Building the Container
Use the script `build_EBcb.sh` to create an EBcb Docker container. The environment variables, TOOLCHAIN, EB_VER, EBUSER_UID, EBUSER_GID are used to customize EBcb and tagging the container. EBcb runtime environment uses the account `eb_user` to run EasyBuild. Map your site's software repository owner to the account `eb_user` with the environment variables: EBUSER_UID, EBUSER_GID. 

### Starting EBcb instance
Use the script `run_EBcb.sh "container name"` to start an instance of EBcb. Environment variables are by `run_EBcb to select and run an EBcb container. TOOLCHAIN, EB_VER, BUILD_DIR, SOURCE_DIR. `run_EBcb.sh` appends `"container name"` to the image name to a unique image name. EBcb runtime environment for EasyBuild has four primary volume locations: /app, /eb, /build and /sources.  `/app` should be mapped to your target application directory, which contains the subdirectories software and modules. `/eb` is local to the container and should not be mapped.   Map the volume`/sources` to your software source repository. Map the build volume to any suitable scratch area.

### Usage
When the EBcb instance starts, you will be at a root prompt. Become the easybuild user with `su - eb_user` and change the directory to `cd /build.`  Two EasyBuild modules are available in /eb/modules. EasyBuild and EasyBuild_test. EasyBuild_test is used for testing an EasyConfig. EasyBuild_test sets `installpath-software` to `/eb/software` and will not write to the production /app volume. When your EasyConfig is ready to deploy load the module EasyBuild. 

#### Sources available at build time and run time.
Sometimes, you may need to manually seed source files for the docker build stage one. Source files from the ```sources``` directory within the EBcb repo are `COPIED` to `/build/sources`, making the sources available to EasyBuild during container build time.

Note that the container has Lmod installed in /eb/lmod. Version parity is essential, so you will always want to keep your /app Lmod in sync with the EBcb Lmod. LMOD_VER environment variable controls the version of LMOD at Docker Build time.

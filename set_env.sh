#!/bin/sh

# Create the environment for EBcb
# Configure the UID/GID to be used to own software tools
# Config the APP_ROOT location

export cUID=65534
export cGID=65534
export APP_ROOT='/app'

# Select the versions of EasyBuild and the Toolchain
export EB_VER='3.9.4'
export LMOD_VER='7.8'
export TOOLCHAIN='foss-2018b'

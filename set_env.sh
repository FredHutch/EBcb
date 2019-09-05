#!/bin/sh

# Create the environment for EBcb
# Configure the UID/GID to be used to own software tools
# Config the APP_ROOT location

export LS2_UID=650
export LS2_GID=500
export DEPOLY_PREFIX='/app'
export TZ='America/Los_Angeles'

# Select the versions of EasyBuild and the Toolchain
export EB_VER='3.9.4'
export LMOD_VER='7.8'
export TOOLCHAIN='foss-2018b'

#!/bin/sh

# Create the environment for EBcb
# Set the UID/GID of the easbuild user to your sites owner of your EasyBuild software
# repository. Customize your time zone for the build container

export EBUSER_UID=6514  # scicomp
export EBUSER_GID=6514  # g_scicomp
export TZ='America/Los_Angeles'
export EB_VER='4.2.1'
export TOOLCHAIN='foss-2019b'

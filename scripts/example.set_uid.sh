#!/bin/sh

# Create the environment for EBcb container
# Configure the UID/GID to be used to own software tools
# source this file before building a container

export EBUSER_UID=600
export EBUSER_GID=600
export TZ='America/Los_Angeles'

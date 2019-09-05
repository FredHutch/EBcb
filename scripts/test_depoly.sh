#!/bin/bash

# setup EB to build locally without touching production
EBdir=/ls2/software
EASYBUILD_BUILDPATH=${EBdir}/build
EASYBUILD_INSTALLPATH_SOFTWARE=${EBdir}/software
EASYBUILD_INSTALLPATH_MODULES=${EBdir}/modules
EASYBUILD_SOURCEPATH=${EBdir}/sources
EASYBUILD_REPOSITORYPATH=${EBdir}/ebfiles_repo

module use /app/modules/all:${EBdir}/modules/all

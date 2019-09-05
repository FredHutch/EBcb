FROM ubuntu:18.04 AS EBcb_os

# These have reasonable defaults - only change if you really need to
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
ARG LS2_USERNAME=scicomp
ENV LS2_USERNAME=${LS2_USERNAME}
ARG LS2_GROUPNAME=scicomp
ENV LS2_GROUPNAME=${LS2_GROUPNAME}
ARG LS2_UID=500
ENV LS2_UID=${LS2_UID}
ARG LS2_GID=500
ENV LS2_GID=${LS2_GID}
ARG LMOD_VER
ENV LMOD_VER=${LMOD_VER}
ARG EB_VER
ENV EB_VER=${EB_VER}
ARG TOOLCHAIN
ENV TOOLCHAIN=${TOOLCHAIN}
ARG DEPLOY_PREFIX=/app
ENV DEPLOY_PREFIX=${DEPLOY_PREFIX}

# OS Level 
# OS Packages, EasyBuild needs Python and Lmod, Lmod needs lua
# Base OS packages, user account, set TZ, directory for /ls2 and LS2_USER
# Create install directory ${DEPLOY_PREFIX}
RUN \
    groupadd -g ${LS2_GID} ${LS2_GROUPNAME} && \
    useradd -u ${LS2_UID} -g ${LS2_GROUPNAME} -ms /bin/bash ${LS2_USERNAME} && \
    mkdir /ls2 && chown ${LS2_USERNAME}.${LS2_GROUPNAME} /ls2 && \
    mkdir ${DEPLOY_PREFIX} && chown ${LS2_UID}.${LS2_GID} ${DEPLOY_PREFIX} && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y \
    bash \
    curl \
    cpio \
    git \
    sudo \
    ssl-cert \
    libssl-dev \
    liblua5.3-0 \
    lua-filesystem \
    lua-posix \
    lua-json \
    lua-term \
    lua5.3 \
    python \
    python-setuptools \
    python-pip && \
    pip install --upgrade pip && \
    /usr/local/bin/pip install python-graph-core python-graph-dot pycodestyle pep8 GitPython
RUN dpkg -l > /ls2/installed_pkgs.18.04-OS
    

# Fix issues with lua5.3 5.3.3-1 on Ubuntu 18.04
# lua-posix changed its main module name from posix_c to posix which causes 
# Lmod install fails with lua-posix not found.
# This should be fixed with lua-posix 33.4.0-3 binary 
RUN ln -s /usr/bin/lua5.3 /usr/bin/lua && \
    ln -s /usr/bin/luac5.3 /usr/bin/luac && \
    cd /usr/lib/x86_64-linux-gnu/lua/5.3 && \
    ln -s ../../liblua5.3-posix.so.1.0.0 posix.so
FROM EBcb_os AS EBcb_eb

# copy helper scripts for building lmod, easybuild and
# setup the environment for the the LS2_USER
COPY easyconfigs/ \
     sources/ \
     install_lmod.sh \
     install_easybuild.sh \
     eb_module_footer \
     install_toolchain.sh \
     install.sh \
     deploy.sh \
     build_env.sh \
     install_R.sh /ls2/
COPY modules.sh /etc/profile.d/
RUN  chown -R ${LS2_USERNAME}.${LS2_GROUPNAME} /ls2

# lmod EasyBuild layer
# Base Ubuntu containers have no deve tools. In order to build Easybuild and the foss toolchain
# build-essentials are required. But we do not want build-essentials to be part of the
# EasyBuild continaer. 
#
# Use build-essentials in a single layer; install and uninstall build-essential in one step.

RUN apt-get install -y build-essential \
    && su -c "/bin/bash /ls2/install_lmod.sh" ${LS2_USERNAME} \
    && su -c "/bin/bash /ls2/install_easybuild.sh" ${LS2_USERNAME} \
    && AUTO_ADDED_PKGS=$(apt-mark showauto) apt-get remove -y --purge build-essential ${AUTO_ADDED_PKGS} \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
FROM EBcb_eb AS EBcb_foss


# gather pkg info
RUN dpkg -l > /ls2/installed_pkgs.easybuild

# libibverbs required for foss toolchains
ENV INSTALL_OS_PKGS "awscli libibverbs-dev libc6-dev bzip2 make unzip xz-utils"
ENV UNINSTALL_OS_PKGS ""

# Toolchain Layer
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y build-essential ${INSTALL_OS_PKGS} \
    && su -c "/bin/bash /ls2/install_toolchain.sh" ${LS2_USERNAME} \
    && AUTO_ADDED_PKGS=$(apt-mark showauto) apt-get remove -y --purge build-essential ${UNINSTALL_OS_PKGS} ${AUTO_ADDED_PKGS} \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# gather installed pkgs list
RUN dpkg -l > /ls2/installed_pkgs.${TOOLCHAIN}

# switch to LS2 user for future actions
#USER ${LS2_USERNAME}
WORKDIR /home/${LS2_USERNAME}
SHELL ["/bin/bash", "-c"]

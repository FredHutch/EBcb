FROM ubuntu:18.04 AS build 

# updated to support EasyBuild 4.x  summer 2019
# Create Easybuild container with docker multi-stage.
# EasyBuild requires build-essentials, but the final EasyBuild container
# should have no OS native build tools.
# stage <build>; use build-essentials to build EasyBuild and toolchain.
# Write all EB tools to /eb directory
# Final <easybuild> container COPIES /eb without bring any build-essentials
# into the final container.

# These have reasonable defaults - only change if you really need to
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

ENV EBUSER=eb_user
ENV EBGROUP=eb_group
ARG EBUSER_UID=EBUSER_UID
ENV EBUSER_UID=${EBUSER_UID}
ARG EBUSER_GID=EBUSER_GID
ENV EBUSER_GID=${EBUSER_GID}
ARG LMOD_VER
ENV LMOD_VER=${LMOD_VER}
ARG EB_VER
ENV EB_VER=${EB_VER}
ARG TOOLCHAIN
ENV TOOLCHAIN=${TOOLCHAIN}
ARG PREFIX=/eb
ARG BUILD_DIR=/build

# OS Level
# OS Packages, EasyBuild needs Python and Lmod, Lmod needs lua
# Base OS packages, user account, set TZ, user account EBUSER
# Create install directory ${BUILD_DIR} 
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    /usr/sbin/locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 

RUN \
    groupadd -g ${EBUSER_GID} ${EBGROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBUSER_GID} -ms /bin/bash ${EBUSER} && \
    mkdir ${BUILD_DIR} && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    awscli libibverbs-dev libc6-dev bzip2 make unzip xz-utils \
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
    # Manpages is required for Perl to install
    groff groff-base  manpages manpages-dev \
    python-setuptools && \
    # python-pip  && \
    # pip install --upgrade pip && \
    # /usr/local/bin/pip install python-graph-core python-graph-dot pycodestyle pep8 GitPython && \
    echo "${EBUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Fix issues with lua5.3 5.3.3-1 on Ubuntu 18.04
# lua-posix changed its main module name from posix_c to posix which causes
# Lmod install fails with lua-posix not found.
# This should be fixed with lua-posix 33.4.0-3 binary
RUN ln -s /usr/bin/lua5.3 /usr/bin/lua && \
    ln -s /usr/bin/luac5.3 /usr/bin/luac && \
    cd /usr/lib/x86_64-linux-gnu/lua/5.3 && \
    ln -s ../../liblua5.3-posix.so.1.0.0 posix.so

# copy helper scripts for building lmod, easybuild and
# setup the environment for the the EBUSER_
ADD scripts  ${BUILD_DIR}/scripts
ADD easyconfigs ${BUILD_DIR}/easyconfigs
ADD sources ${BUILD_DIR}/sources

RUN  chown -R ${EBUSER_UID}:${EBUSER_GID} ${BUILD_DIR}
 

# lmod EasyBuild layer
# Base Ubuntu containers have no develop tools. In order to build Easybuild and the foss toolchain
# build-essentials are required. But we do not want build-essentials to be part of the
# EasyBuild continaer. EasyBuild and toolchain are built in 'build' stage and not copied
# into the easybuild stage.
 
# Install EasyBuild and the Toolchain into /eb

#-- Build the /eb volume in a single command -
#   Install LMOD, EB and build a toolchain too /eb 
#   configure EB build target to build software in directory /eb
#   EasyBuild is used to build toolchain in /eb directory
#   save original EasyBuild.lua so it can be re-configured to build target /app
RUN \
    mkdir /eb && chown ${EBUSER_UID}:${EBUSER_GID} /eb && \
#--- Install LMod local 
    su -c "/bin/bash ${BUILD_DIR}/scripts/install_lmod.sh" && \
#--- Install EB
    su -c "/bin/bash ${BUILD_DIR}/scripts/install_easybuild.sh" ${EBUSER} && \
#--- Toolchain Layer
    su -c "/bin/bash ${BUILD_DIR}/scripts/install_toolchain.sh" ${EBUSER} && \
#--- reconfigure EB to install software to /app
    su -c "cat ${BUILD_DIR}/scripts/app_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER}
#
# Finished with build container


# ============================================
# Create the EB container from "build" container
#
FROM ubuntu:18.04 as easybuild 

ENV TZ=America/Los_Angeles
ARG EBUSER=eb_user
ARG EBGROUP=eb_group
ARG EBUSER_UID=EBUSER_UID
ARG EBUSER_GID=EBUSER_GID
ARG PREFIX=/eb
ARG BUILD_DIR=/build

WORKDIR /
COPY --from=build /eb /eb 
COPY scripts/modules.sh /etc/profile.d/

RUN \ 
    groupadd -g ${EBUSER_GID} ${EBGROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBGROUP} -ms /bin/bash ${EBUSER} && \
    mkdir /app && chown ${EBUSER}:${EBGROUP} /app && \
    chmod 775 /etc/profile.d/modules.sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    /usr/sbin/locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8


RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    awscli bzip2 make unzip xz-utils \
    libibverbs-dev libc6-dev libnspr4-dev libv8-dev \
    curl wget \
    cpio \
    git \
    sudo \
    ssl-cert \
    libssl-dev \
    openssl \
    liblua5.3-0 \
    lua-filesystem \
    lua-posix \
    lua-json \
    lua-term \
    lua5.3 \
    python

# Fix issues with lua5.3 5.3.3-1 on Ubuntu 18.04
# lua-posix changed its main module name from posix_c to posix which causes
# Lmod install fails with lua-posix not found.
# This should be fixed with lua-posix 33.4.0-3 binary
RUN ln -s /usr/bin/lua5.3 /usr/bin/lua && \
    ln -s /usr/bin/luac5.3 /usr/bin/luac && \
    cd /usr/lib/x86_64-linux-gnu/lua/5.3 && \
    ln -s ../../liblua5.3-posix.so.1.0.0 posix.so

# switch to EBUSER user for future actions
# USER ${EBUSER}
WORKDIR ${BUILD_DIR} 
SHELL ["/bin/bash", "-c"]

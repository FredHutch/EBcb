FROM ubuntu:18.04 AS build

# Oct 2022 - Use Python3.8 for EasyBuild
# Aug 2021 - Use Python3 for Easybuild. Remove Python2. Install EasyBuild to
# /tmp with pip and re-install EasyBuild with EasyBuild as a module.

# updated to support EasyBuild 4.x  summer 2019
# Create Easybuild container with docker multi-stage.
# EasyBuild requires build-essentials, but the final EasyBuild container
# should have no OS native build tools.
# stage <build>; use build-essentials to build EasyBuild and toolchain.
# Write all EB tools to /eb directory
# Final <easybuild> container COPIES /eb without bring any build-essentials
# into the final container.

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
ARG TZ
ENV TZ=${TZ}
ARG LANG=LANG
ENV LANG=${LANG}

ENV EBUSER=eb_user
ENV EBGROUP=eb_group
ENV PREFIX=/eb
ENV BUILD_DIR=/build
ENV EB_TMPDIR=/tmp/eb
ENV DEBIAN_FRONTEND=noninteractive

# OS Level
# OS Packages, EasyBuild needs Python and Lmod, Lmod needs lua
# Base OS packages, user account, set TZ, user account EBUSER
# Create install directory ${BUILD_DIR}
RUN echo "LANG=${LANG}" > /etc/default/locale && \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    /usr/sbin/locale-gen en_US.UTF-8 && \
    update-locale LANG=$LANG

RUN \
    groupadd -g ${EBUSER_GID} ${EBGROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBUSER_GID} -ms /bin/bash ${EBUSER} && \
    mkdir ${BUILD_DIR} && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    awscli libibverbs-dev libc6-dev bzip2 make unzip xz-utils \
    autopoint \
    bash \
    curl \
    cpio \
    git \
    sudo \
    ssl-cert \
    libssl-dev \
    libcrypto++6 \
    openssl \
    bc \
    lua5.3 \
    liblua5.3-0 \
    liblua5.3-dev \
    lua-filesystem \
    lua-posix \
    lua-json \
    lua-term \
    python3.8 \
    python3.8-dev \
    python3-distutils \
    python3-certifi \
    libpython3.8-dev \
    libpython3.8-stdlib \ 
    python3-pip \
    groff groff-base  manpages manpages-dev && \
# Make Python3 the default
    update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
    python -m pip install --upgrade pip && \
    update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip 1 && \
# setup sudo for eb_user
    echo "${EBUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
# Fix issues with lua5.3 5.3.3-1 on Ubuntu 18.04
    ln -s /usr/bin/lua5.3 /usr/bin/lua && \
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
#   Install LMOD, EB and build a toolchain in /eb
#   configure EB build target to build software in directory /eb
#   EasyBuild is used to build toolchain in /eb directory
#   save original EasyBuild.lua so it can be re-configured to build target /app
RUN \
    mkdir -p ${PREFIX}/modules && \
    mkdir -p ${PREFIX}/lmod/ && \
#--- Install LMod local
    /bin/bash ${BUILD_DIR}/scripts/install_lmod.sh $LMOD_VER && \
    chown -R $EBUSER_UID:$EBUSER_GID ${PREFIX} && \
#--- Install tmp EB
    mkdir $EB_TMPDIR && \
    mkdir /etc/easybuild.d && \
    chmod 775 /etc/easybuild.d && \
    cp  ${BUILD_DIR}/scripts/config.cfg /etc/easybuild.d && \
    python -m pip install --ignore-installed --prefix $EB_TMPDIR easybuild==${EB_VER} && \
#-- Install EasyBuild as a Module
    chown -R ${EBUSER_UID}:${EBUSER_GID} ${PREFIX} && \
    su -c "/bin/bash ${BUILD_DIR}/scripts/install_easybuild.sh $EB_VER $PREFIX $EB_TMPDIR $BUILD_DIR" ${EBUSER} && \
#--- Toolchain Layer
    su -c "/bin/bash ${BUILD_DIR}/scripts/install_toolchain.sh $EB_VER $PREFIX $BUILD_DIR $TOOLCHAIN" ${EBUSER} && \
#--- reconfigure EB to install software to /app
    su -c "cp ${PREFIX}/modules/all/EasyBuild/${EB_VER}.orig ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER} && \
    su -c "cat ${BUILD_DIR}/scripts/app_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER}

# Finished with build container
# ============================================
# Create the EB container from "build" container
#
FROM ubuntu:18.04 as easybuild

ARG EBUSER_UID=EBUSER_UID
ARG EBUSER_GID=EBUSER_GID
ARG EASYCONFIG=EASYCONFIG
ENV EASYCONFIG=${EASYCONFIG}
ARG TZ=TZ
ENV TZ=${TZ}
ARG LANG=LANG
ENV LANG=${LANG}

ENV EBUSER=eb_user
ENV EBGROUP=eb_group
ENV PREFIX=/eb
ENV BUILD_DIR=/build

WORKDIR /
COPY --from=build /eb /eb
COPY scripts/modules.sh /etc/profile.d/


RUN mkdir /etc/easybuild.d && \
    mkdir -p /etc/OpenCL/vendors && \
    chmod 775 /etc/easybuild.d
COPY scripts/config.cfg /etc/easybuild.d/config.cfg
COPY etc/nvidia.icd /etc/OpenCL/vendors/nvidia.icd
RUN chmod 644 /etc/easybuild.d/config.cfg && \
    chmod 644 /etc/OpenCL/vendors/nvidia.icd

RUN groupadd -g ${EBUSER_GID} ${EBGROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBGROUP} -ms /bin/bash ${EBUSER} && \
    mkdir /app && chown ${EBUSER}:${EBGROUP} /app && \
    mkdir ${BUILD_DIR} && chown ${EBUSER}:${EBGROUP} ${BUILD_DIR} && \
    chmod 775 /etc/profile.d/modules.sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# set Languange
RUN echo "LANG=${LANG}" > /etc/default/locale && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils locales && \
    /usr/sbin/locale-gen en_US.UTF-8 && \
    update-locale LANG=${LANG}

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    ca-certificates awscli bzip2 make unzip xz-utils \
    libibverbs-dev libc6-dev libnspr4-dev libv8-dev libnpth0 \
    autopoint \
    curl wget \
    cpio \
    git \
    sudo \
    ssl-cert \
    libssl-dev \
    libcrypto++6 \
    openssl \
    lua5.3 \
    lua-filesystem \
    lua-posix \
    lua-json \
    lua-term \
    liblua5.3-0 \
    python3.8 \
    python3.8-dev \
    python3-distutils \
    python3-certifi \
    python3.8-venv \
    libpython3.8-stdlib \
    lsb-release \
    && \
# Make Python3 the default
    update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
# Update CA
    update-ca-certificates --fresh

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
WORKDIR ${PREFIX}
SHELL ["/bin/bash", "-c"]

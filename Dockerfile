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

ENV EBUSER_NAME=eb_user
ENV EBUSER_GROUP=eb_group
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
ARG DEPLOY_PREFIX=/eb
ENV DEPLOY_PREFIX=${DEPLOY_PREFIX}
# ---- easybuild env variables
ENV EASYBUILD_PREFIX=${DEPLOY_PREFIX}
ENV EASYBUILD_MODULES_TOOL=Lmod
ENV EASYBUILD_MODULE_SYNTAX=Lua


# OS Level
# OS Packages, EasyBuild needs Python and Lmod, Lmod needs lua
# Base OS packages, user account, set TZ, directory for /ls2 and EBUSER
# Create install directory ${DEPLOY_PREFIX}
RUN \
    groupadd -g ${EBUSER_GID} ${EBUSER_GROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBUSER_GROUP} -ms /bin/bash ${EBUSER_NAME} && \
    mkdir ${DEPLOY_PREFIX} && chown ${EBUSER_UID}.${EBUSER_GID} ${DEPLOY_PREFIX} && \
    mkdir /ls2 && mkdir /ls2/sources && chown -R ${EBUSER_UID}.${EBUSER_GID} /ls2 && \
    apt-get update && \
    apt-get install -y \
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
    echo "${EBUSER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


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
COPY scripts/ \
     eb_module_footer \
     app_module_footer \
     sources/ \
     easyconfigs/ /ls2/
RUN  chown -R ${EBUSER_NAME}.${EBGROUP_NAME} /ls2

# lmod EasyBuild layer
# Base Ubuntu containers have no develop tools. In order to build Easybuild and the foss toolchain
# build-essentials are required. But we do not want build-essentials to be part of the
# EasyBuild continaer. EasyBuild and toolchain are built in 'build' stage and not copied
# into the easybuild stage.
 
# Install EasyBuild and the Toolchain into /eb

#--- Install LMod

RUN su -c "/bin/bash /ls2/install_lmod.sh" ${EBUSER_NAME}

#-- Install EasyBuild
#   configure EB build target to build software in directory /eb
#   EasyBuild is used to build toolchain in /eb directory
#   save original EasyBuild.lua so it can be re-configured to build target /app
RUN \
    su -c "cd /ls2 && \
           source ${DEPLOY_PREFIX}/lmod/lmod/init/profile && \
           curl -L -O https://github.com/easybuilders/easybuild-framework/raw/easybuild-framework-v${EB_VER}/easybuild/scripts/bootstrap_eb.py && \
           python /ls2/bootstrap_eb.py ${EASYBUILD_PREFIX}" ${EBUSER_NAME} && \
    su -c "cp ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua \
              ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.orig" ${EBUSER_NAME} && \
    su -c "cat /ls2/eb_module_footer >> ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER_NAME}

#--- Toolchain Layer
RUN su -c "/bin/bash /ls2/install_toolchain.sh" ${EBUSER_NAME}

#-- reconfigure EB to install software to /app
RUN \
    cd /ls2 && \
    su -c "mv ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.orig \
              ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER_NAME} && \
    su -c "cat /ls2/app_module_footer >> ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER_NAME}

# Finished

# ============================================
# Create the EB container from "build" container
#
FROM ubuntu:18.04 as easybuild 
COPY --from=build /eb /eb
COPY --from=build /ls2 /ls2
COPY modules.sh /etc/profile.d/

ENV TZ=America/Los_Angeles
ENV EBUSER_NAME=eb_user
ENV EBUSER_GROUP=eb_group
ARG EBUSER_UID=EBUSER_UID
ENV EBUSER_UID=${EBUSER_UID}
ARG EBUSER_GID=EBUSER_GID
ENV EBUSER_GID=${EBUSER_GID}

RUN \ 
    groupadd -g ${EBUSER_GID} ${EBUSER_GROUP} && \
    useradd -u ${EBUSER_UID} -g ${EBUSER_GROUP} -ms /bin/bash ${EBUSER_NAME} && \
    chown -R ${EBUSER_UID}.${EBUSER_GID} /eb && \
    mkdir /app && chown ${EBUSER_NAME}.${EBUSER_GROUP} /app && \
    chmod 775 /etc/profile.d/modules.sh && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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
# USER ${EBUSER_NAME}
WORKDIR /ls2
SHELL ["/bin/bash", "-c"]

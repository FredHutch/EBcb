#!/bin/bash

# required env vars: OUT_UID, OUT_GID, DEPLOY_PREFIX

set -x
set -e

groupadd -g $OUT_GID outside_group
useradd --shell /bin/bash -u $OUT_UID -m -g outside_group outside_user 

apt-get update -y
apt-get install -y build-essential

su  -c "HOME=/home/outside_user; /ls2/install.sh" outside_user

su -c "source ${DEPLOY_PREFIX}/lmod/lmod/init/bash \
       && ${DEPLOY_PREFIX}/lmod/lmod/libexec/update_lmod_system_cache_files ${DEPLOY_PREFIX}/modules/all" outside_user

AUTO_ADDED_PKGS=$(apt-mark showauto) apt-get remove -y --purge build-essential ${AUTO_ADDED_PKGS}
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

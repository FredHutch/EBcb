#!/bin/bash

# EBcb EasyBuild container build
# Install EasyBuild in a Docker Container
# Create the Easybuild software on volume /eb
# Minimize the size of container by putting build artifacts into /build
 
set -x
set -e

echo "Installing EasyBuild $EB_VER into /eb..."

PREFIX=/eb
BUILD_DIR=/build

echo "Setting EasyBuild env vars..."
export EASYBUILD_MODULES_TOOL=Lmod
export EASYBUILD_MODULE_SYNTAX=Lua
export EASYBUILD_SOURCEPATH=/build/sources
export EASYBUILD_BUILDPATH=/build/build
export EASYBUILD_INSTALLPATH_SOFTWARE=/eb/software
export EASYBUILD_INSTALLPATH_MODULES=/eb/modules
export EASYBUILD_REPOSITORYPATH=/build/ebfiles_repo
export EASYBUILD_LOGFILE_FORMAT="logs,easybuild-%(name)s-%(version)s-%(date)s.%(time)s.log"

export EASYBUILD_GROUP_WRITABLE_INSTALLDIR=1
export EASYBUILD_UMASK=002
export EASYBUILD_MODULE_SYNTAX=Lua
export EASYBUILD_MODULES_TOOL=Lmod

echo "Getting bootstrap_eb.py..."
curl -L -o /tmp/bootstrap_eb.py https://github.com/easybuilders/easybuild-framework/raw/easybuild-framework-v${EB_VER}/easybuild/scripts/bootstrap_eb.py

echo "Loading Lmod..."
source ${PREFIX}/lmod/lmod/init/bash

echo "Bootstrapping EasyBuild ${EB_VER} into $PREFIX}..."
export EASYBUILD_BOOTSTRAP_FORCE_VERSION=${EB_VER}
python /tmp/bootstrap_eb.py /eb 

echo "Customizing EasyBuild modulefile..."
if [ -w "/${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ]
then
  cat ${BUILD_DIR}/scripts/eb_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
  echo EasyBuild install success
else
  error_exit "/${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua not writable, modulefile not updated"
fi

#=================
#    su -c "cp ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua \
#              ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.orig" ${EBUSER} && \
#    su -c "cat /ls2/eb_module_footer >> ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER} && \
#
#============== 

#!/bin/bash

set -x
set -e

echo "Installing EasyBuild $EB_VER into $DEPLOY_PREFIX..."

echo "Setting EasyBuild env vars..."
export EASYBUILD_PREFIX=${DEPLOY_PREFIX}
export EASYBUILD_MODULES_TOOL=Lmod
export EASYBUILD_MODULE_SYNTAX=Lua

echo "Getting bootstrap_eb.py..."
curl -L -o /tmp/bootstrap_eb.py https://github.com/easybuilders/easybuild-framework/raw/easybuild-framework-v${EB_VER}/easybuild/scripts/bootstrap_eb.py && \

echo "Loading Lmod..."
source ${DEPLOY_PREFIX}/lmod/lmod/init/bash

echo "Bootstrapping EasyBuild ${EB_VER} into ${DEPLOY_PREFIX}..."
export EASYBUILD_BOOTSTRAP_FORCE_VERSION=${EB_VER}
python /tmp/bootstrap_eb.py ${EASYBUILD_PREFIX}

echo "Customizing EasyBuild modulefile..."
if [ -w "/${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ]
then
  cat /ls2/eb_module_footer >> ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
else
  error_exit "/${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua not writable, modulefile not updated"
fi

#!/bin/bash

# EBcb EasyBuild container build
# this script runs as the easybuild user eb_user
 
echo "Installing EasyBuild into /eb..."

export EB_VER=$1
export PREFIX=$2
export EB_TMPDIR=$3
export BUILD_DIR=$4

# update environment to use this temporary EasyBuild installation
export PATH=$EB_TMPDIR/bin:$PATH
export PYTHONPATH=$(/bin/ls -rtd -1 $EB_TMPDIR/lib*/python*/site-packages | tail -1):$PYTHONPATH

echo "Loading Lmod..."
source ${PREFIX}/lmod/lmod/init/profile
module use ${PREFIX}/modules/all
eb --install-latest-eb-release --prefix ${PREFIX} --installpath-modules=${PREFIX}/modules

echo "Customizing EasyBuild modulefile..."
if [ -f "${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ]
then
  cat ${BUILD_DIR}/scripts/eb_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
  echo EasyBuild install success
else
  echo "${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua not writable, modulefile not updated"
  exit 1
fi

#=================
#    su -c "cp ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua \
#              ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.orig" ${EBUSER} && \
#    su -c "cat /ls2/eb_module_footer >> ${DEPLOY_PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ${EBUSER} && \
#
#============== 

#!/bin/bash

# EBcb EasyBuild container build
# this script runs as the easybuild user eb_user

# 2022.02.08 keep extra copy of Easybuild lua file as ${EB_VER}.orig
#            add Easybuild config to the /eb volume via /etc/easybuild.d/config.cfg
#            Set Compute Capablity in config.cfg 
# EB-4.5.0 Use two set process to install EasyBuild. This method replaces the "bootstrap"
#          metho of install.
#          Step one - pip install EasyBuild followed by creating an  $EB_TEMPDIR
#          Step Two - Use EasyBuild to reinstall EasyBuild and create a lua module. $PREFIX
#          Start using Python 3 to install and run EasyBuild
#          Set default Python too Python3, this is done in the Dockerfile
 
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
eb --install-latest-eb-release --accept-eula-for=Intel-oneAPI --prefix ${PREFIX} --installpath-modules=${PREFIX}/modules

echo Copy EasyBuild module in /eb

echo "Customizing EasyBuild modulefile..."
if [ -f "${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua" ]
then
  cp ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua ${PREFIX}/modules/all/EasyBuild/${EB_VER}.orig
  cat ${BUILD_DIR}/scripts/eb_module_footer >> ${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua
  echo EasyBuild install success
else
  echo "${PREFIX}/modules/all/EasyBuild/${EB_VER}.lua not writable, modulefile not updated"
  exit 1
fi


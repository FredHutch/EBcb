#/bin/bash

# Build R from scratch!

# Perl will not build on Ubuntu due to missing packages that
# we do not want to install. This script installs the OS packages
# builds perl then removes them
apt-get update
apt-get install -y groff groff-base  manpages manpages-dev
sudo -H -u scicomp bash <<"EOF"
cd /ls2
source /etc/profile.d/modules.sh
module load EasyBuild
eb Perl-5.28.0-GCCcore-7.3.0.eb --robot
EOF
apt-get remove -y --purge groff groff-base  manpages manpages-dev
apt-get autoremove -y

#  Build R
sudo -H -u scicomp bash <<"EOF"
cd /ls2
source /eb/lmod/lmod/init/profile
module use /eb/modules/all
module load EasyBuild
eb R-3.5.1-foss-2018b.eb --robot
EOF

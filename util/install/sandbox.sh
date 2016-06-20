#!/bin/sh
##
## Installs the pre-requisites for running edX on a single Ubuntu 12.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

OPENEDX_RELEASE="named-release/dogwood.3"

##
## Sanity check
##
if [[ ! "$(lsb_release -d | cut -f2)" =~ $'Ubuntu 12.04' ]]; then
   echo "This script is only known to work on Ubuntu 12.04, exiting...";
   exit;
fi

##
## Set ppa repository source for gcc/g++ 4.8 in order to install insights properly
##
sudo apt-get install -y python-software-properties
sudo add-apt-repository ppa:ubuntu-toolchain-r/test

##
## Update and Upgrade apt packages
##
echo -ne "\r-------------------------------  Update and Upgrade apt packages  -------------------------------"
sudo apt-get update -y
sudo apt-get upgrade -y
echo -ne "==============================="

##
## Install system pre-requisites
##
echo -ne "\r---------------  Install system pre-requisites  -----------------"
sudo apt-get install -y build-essential software-properties-common python-software-properties curl git-core libxml2-dev libxslt1-dev python-pip python-apt python-dev libxmlsec1-dev libfreetype6-dev swig gcc-4.8 g++-4.8
sudo pip install --upgrade pip==7.1.2
sudo pip install --upgrade setuptools==18.3.2
sudo -H pip install --upgrade virtualenv==13.1.2
echo -ne "==============================="

##
## Update alternatives so that gcc/g++ 4.8 is the default compiler
##
echo -ne "\r--------------- Update alternatives so that gcc/g++ 4.8 is the default compiler -----------------"
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
echo -ne "==================================================================================================="

## Did we specify an openedx release?
if [ -n "$OPENEDX_RELEASE" ]; then
  EXTRA_VARS="-e edx_platform_version=$OPENEDX_RELEASE \
    -e certs_version=$OPENEDX_RELEASE \
    -e forum_version=$OPENEDX_RELEASE \
    -e xqueue_version=$OPENEDX_RELEASE \
    -e configuration_version=$OPENEDX_RELEASE \
    -e NOTIFIER_VERSION=$OPENEDX_RELEASE \
    -e INSIGHTS_VERSION=$OPENEDX_RELEASE \
    -e ANALYTICS_API_VERSION=$OPENEDX_RELEASE \
  "
  CONFIG_VER=$OPENEDX_RELEASE
else
  CONFIG_VER="master"
fi


##
## Clone the configuration repository and run Ansible
##
echo -ne "\r------------------------------  Clone the configuration repository and run Ansible  ------------------------------"
cd /var/tmp
git clone https://github.com/edx/configuration
cd configuration
echo "Version: $CONFIG_VER"
#git checkout $CONFIG_VER
git checkout $CONFIG_VER
echo -ne "==============================="

##
## Install the ansible requirements
##
echo -ne "\r------------------------------  Install the ansible requirements  ------------------------------"
cd /var/tmp/configuration
sudo pip install -r requirements.txt
echo -ne "==============================="

##
## Get configuration
##
echo -ne "\r------------------------------  Get configuration  ------------------------------"
cd /var/tmp/
wget -O server-vars.yml https://raw.githubusercontent.com/edxhneu/edx-hneu-config/$CONFIG_VER/util/install/server-vars.yml
echo -ne "==============================="

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
echo -ne "\r------------------------------  Run the edx_sandbox.yml playbook in the configuration/playbooks directory  ------------------------------"
cd /var/tmp/configuration/playbooks && sudo ansible-playbook -c local ./edx_sandbox.yml -i "localhost," -e@/var/tmp/server-vars.yml
echo -ne "==============================="

##
## Copy server-vars.yml 
##
cp /var/tmp/server-vars.yml /edx/app/edx_ansible/server-vars.yml

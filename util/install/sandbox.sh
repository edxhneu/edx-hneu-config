#!/bin/sh
##
## Installs the pre-requisites for running edX on a single Ubuntu 12.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

##
## Sanity check
##
if [[ ! "$(lsb_release -d | cut -f2)" =~ $'Ubuntu 12.04' ]]; then
   echo "This script is only known to work on Ubuntu 12.04, exiting...";
   exit;
fi

##
## Update and Upgrade apt packages
##
echo -e "\nUpdate and Upgrade apt packages"
echo -e "-------------------------------"
sudo apt-get update -y
sudo apt-get upgrade -y
echo "==============================="

##
## Install system pre-requisites
##
echo -e "\nInstall system pre-requisites"
echo -e "-------------------------------"
#sudo apt-get install -y build-essential software-properties-common python-software-properties curl git-core libxml2-dev libxslt1-dev python-pip python-apt python-dev
#sudo pip install --upgrade pip
#sudo pip install --upgrade virtualenv

sudo apt-get install -y build-essential software-properties-common curl git-core libxml2-dev libxslt1-dev python-pip libmysqlclient-dev python-apt python-dev libxmlsec1-dev libfreetype6-dev swig gcc-4.8 g++-4.8
sudo pip install --upgrade pip==7.1.2
sudo pip install --upgrade setuptools==18.3.2
sudo -H pip install --upgrade virtualenv==13.1.2
echo -e "==============================="

## Did we specify an openedx release?
#if [ -n "$OPENEDX_RELEASE" ]; then
#  EXTRA_VARS="-e edx_platform_version=$OPENEDX_RELEASE \
#    -e certs_version=$OPENEDX_RELEASE \
#    -e forum_version=$OPENEDX_RELEASE \
#    -e xqueue_version=$OPENEDX_RELEASE \
#  "
#  CONFIG_VER=$OPENEDX_RELEASE
#else
#  CONFIG_VER="release"
#fi

##
## Clone the configuration repository and run Ansible
##
echo -e "\nClone the configuration repository and run Ansible"
echo -e "------------------------------"
cd /var/tmp
git clone https://github.com/edx/configuration
cd configuration
echo "Version: $CONFIG_VER"
#git checkout $CONFIG_VER
git checkout named-release/cypress
echo -e "==============================="

##
## Install the ansible requirements
##
echo -e "\nInstall the ansible requirements"
echo -e "------------------------------"
cd /var/tmp/configuration
sudo pip install -r requirements.txt
echo -e "==============================="

##
## Get configuration
##
echo -e "\nGet configuration"
echo -e "------------------------------"
cd /var/tmp/
wget -O server-vars.yml https://raw.githubusercontent.com/edxhneu/edx-hneu-config/named-release/cypress/util/install/server-vars.yml
echo -e "==============================="

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
echo -e "\nRun the edx_sandbox.yml playbook in the configuration/playbooks directory"
echo -e "------------------------------"
cd /var/tmp/configuration/playbooks && sudo ansible-playbook -c local ./edx_sandbox.yml -i "localhost," -e@/var/tmp/server-vars.yml
echo -e "==============================="

# fix 
touch /edx/app/edx_notes_api/edx_notes_api/requirements/optional.txt

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
echo -e "\nRun the edx_sandbox.yml playbook in the configuration/playbooks directory"
echo -e "------------------------------"
cd /var/tmp/configuration/playbooks && sudo ansible-playbook -c local ./edx_sandbox.yml -i "localhost," -e@/var/tmp/server-vars.yml
echo -e "==============================="

##
## Copy server-vars.yml 
##
cp /var/tmp/server-vars.yml /edx/app/edx_ansible/server-vars.yml

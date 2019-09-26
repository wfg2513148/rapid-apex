#!/bin/bash

##############################################################################################################
# This script is to rapid install Oracle database, APEX and ORDS automatically.
# Created by: Kenny Wang
# Email: wfgdlut@gmail.com
##############################################################################################################
repo_name="rapid-apex"

echo ""
echo "--------- Step 0: Environment Check ---------"
echo ""

quick_install=${1:-"N"}


if [ "$quick_install" = "N" ]; then
  docker_network=${2:-'oracle_network'}
  db_file_name=${3:-'oracle-database-xe-18c-1.0-1.x86_64.rpm'}
  db_version=${4:-'18c'}
  db_sys_pwd=${5:-'oracle'}
  db_port=${6:-31521}
  em_port=${7:-35500}
  apex_file_name=${8:-'apex_19.1.zip'}
  apex_version=${9:-'19.1'}
  apex_admin_username=${10:-'ADMIN'}
  apex_admin_pwd=${11:-'Welc0me@1'}
  apex_admin_email=${12:-'wfgdlut@gmail.com'}
  ords_file_name=${13:-'ords-19.2.0.199.1647.zip'}
  ords_version=${14:-'19.2.0'}
  ords_port=${15:-32513}
  echo ">>> you choose custom install mode..."
else
  echo ">>> you choose quick install mode..."
fi;

work_path=`pwd`
echo ">>> current work path is $work_path"

# verify if required component is installed
function isinstalled {
  if yum list installed "$@" >/dev/null 2>&1; then
    true
  else
    false
  fi
}




# verify docker
package="docker"
if [ -x "$(command -v $package)" ]; then
  echo ">>> docker is installed, continue..."
else
  echo ">>> $package is not installed, script will install $package for you..."
  
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io
  systemctl start docker
  systemctl enable docker
fi

docker network create -d bridge oracle_network



# verify curl
package="curl"
if ! isinstalled $package; then 
  echo ">>> $package is not installed, script will install $package for you..."
  yum install -y $package
fi;



# verify uzip
package="unzip"
if ! isinstalled $package; then 
  echo ">>> $package is not installed, script will install $package for you..."
  yum install -y $package
fi;


if [ ! -d "$work_path/$repo_name" ]; then
  curl -o $repo_name.zip https://codeload.github.com/wfg2513148/$repo_name/zip/master && \
  unzip -oq $repo_name.zip && \
  rm -Rf $repo_name.zip && \
  mv $repo_name-master $repo_name
fi;


##############################################################################################################

# execute install.sh
cd $repo_name/
chmod +x install.sh

./install.sh $quick_install $docker_network $db_file_name $db_version $db_sys_pwd $db_port $em_port $apex_file_name $apex_version $apex_admin_username $apex_admin_pwd $apex_admin_email $ords_file_name $ords_version $ords_port


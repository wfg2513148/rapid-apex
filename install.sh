#!/bin/bash


##############################################################################################################

#source env.properties

quick_install=Y # $1
use_exist_media=N # $2
docker_network=oracle_network # $3
db_file_name=oracle-database-xe-18c-1.0-1.x86_64.rpm # $4
db_version=18c # $5
db_sys_pwd=oracle # $6
db_port=31521 # $7
db_pdb_name=XEPDB1 # $8
em_port=35500 # $9
apex_file_name=apex_19.1.zip # $10
apex_version=19.1 # $11
apex_admin_username=ADMIN # $12
apex_admin_pwd='Welc0me@1' # $13
apex_admin_email='wfgdlut@gmail.com' # $14
apex_public_user_pass=oracle # $15
apex_listener_pass=oracle # $16
apex_rest_pass=oracle # $17
ords_pass=oracle # $18
ords_port=32513 # $19
ords_file_name=ords-19.2.0.199.1647.zip # $20
ords_version=19.2.0 # $21


quick_install=$1

if [ "$quick_install" = "N" ]; then
  use_exist_media=$2
  docker_network=$3
  db_file_name=$4
  db_version=$5
  db_sys_pwd=$6
  db_port=$7
  db_pdb_name=$8
  em_port=$9
  apex_file_name=$10
  apex_version=$11
  apex_admin_username=$12
  apex_admin_pwd=$13
  apex_admin_email=$14
  apex_public_user_pass=$15
  apex_listener_pass=$16
  apex_rest_pass=$17
  ords_pass=$18
  ords_port=$19
  ords_file_name=$20
  ords_version=$21
  echo ">>> you choose custom install mode..."
else
  echo ">>> you choose quick install mode..."
fi;



##############################################################################################################

echo ""
echo "--------- Step 1: Download installation media ---------"
echo ""


work_path=`pwd`

echo ">>> current work path is $work_path"

cd $work_path/docker-xe/

if [ $use_exist_media='Y' ]; then
  if [ ! -f files/$apex_file_name ]; then
    curl -o files/$apex_file_name https://cn-oracle-apex.oss-cn-shanghai-internal.aliyuncs.com/$apex_file_name
    #curl -o files/$apex_file_name https://cn-oracle-apex.oss-cn-shanghai.aliyuncs.com/$apex_file_name
  fi;
else
  if [ ! -f files/$apex_file_name ]; then
    echo ">>> cannot find $apex_file_name in $work_path/docker-xe/files/"
    pre_check="N"
  fi;
fi;



if [ $use_exist_media='Y' ]; then
  if [ ! -f files/$ords_file_name ]; then
    curl -o ../../docker-ords/files/$ords_file_name https://cn-oracle-apex.oss-cn-shanghai-internal.aliyuncs.com/$ords_file_name
    #curl -o files/$ords_file_name https://cn-oracle-apex.oss-cn-shanghai.aliyuncs.com/$ords_file_name
  fi;
else
  if [ ! -f ../../docker-ords/files/$ords_file_name ]; then
    echo ">>> cannot find $ords_file_name in $work_path/docker-ords/files/"
    pre_check="N"
  fi;
fi;


#if [ $use_exist_media='Y' ]; then
#  if [ ! -f files/$db_file_name ]; then
#    curl -o files/$db_file_name https://cn-oracle-apex.oss-cn-shanghai.aliyuncs.com/$db_file_name
#  fi;
#else
#  if [ ! -f files/$db_file_name ]; then
#    echo ">>> cannot find $db_file_name in $work_path/docker-xe/files/"
#    pre_check="N"
#  fi;
#fi;


if [ "$pre_check" = "N" ]; then
  echo "Installation media files cannot be found..."
  exit;
fi;

exit;

##############################################################################################################

if [ ! -d ../apex ]; then
  echo ">>> unzip apex installation media ..."
  mkdir ../apex
  cp scripts/apex-install*  ../apex/
  unzip -oq files/$apex_file_name -d ../ &
fi;

echo ""
echo "--------- Step 2: compile oracle xe docker image ---------"
echo ""

if [[ ! "$(docker images -q oracle-xe:$db_version 2> /dev/null)" == "" ]]; then
  docker build -t oracle-xe:$db_version --build-arg DB_SYS_PWD=$db_sys_pwd .
fi


echo ""
echo "--------- Step 3: startup oracle xe docker image ---------"
echo ""
docker run -d \
  -p $db_port:1521 \
  -p $em_port:5500 \
  --name=oracle-xe \
  --volume $work_path/oradata:/opt/oracle/oradata \
  --volume $work_path/apex:/tmp/apex \
  --network=$docker_network \
  oracle-xe:$db_version


# wait until database configuration is done
rm -f xe_installation.log
docker logs oracle-xe >& xe_installation.log
while : ; do
    [[ `grep "Completed: ALTER PLUGGABLE DATABASE" xe_installation.log` ]] && break
    docker logs oracle-xe >& xe_installation.log
    echo "wait until oracle-xe configuration is done..."
    sleep 30
done

##############################################################################################################

echo ""
echo "--------- Step 4: install apex on xe docker image ---------"
echo ""

docker exec -it oracle-xe bash -c "source /home/oracle/.bashrc && cd /tmp/apex && chmod +x apex-install.sh && . apex-install.sh $db_sys_pwd $apex_admin_pwd $db_pdb_name $apex_admin_email"


##############################################################################################################

echo ""
echo "--------- Step 5: compile oracle ords docker image ---------"
echo ""
cd ../docker-ords/

if [[ ! "$(docker images -q oracle-ords:$ords_version 2> /dev/null)" == "" ]]; then
  docker build -t oracle-ords:$ords_version .
fi;

##############################################################################################################

echo ""
echo "--------- Step 6: startup oracle ords docker image ---------"
echo ""
docker run -d -it --network=$docker_network \
  -e TZ=Asia/Shanghai \
  -e DB_HOSTNAME=oracle-xe \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=$db_pdb_name \
  -e APEX_PUBLIC_USER_PASS=$apex_public_user_pass \
  -e APEX_LISTENER_PASS=$apex_listener_pass \
  -e APEX_REST_PASS=$apex_rest_pass \
  -e ORDS_PASS=$ords_pass \
  -e SYS_PASS=$db_sys_pwd \
  --volume $work_path/oracle-ords/$ords_version/config:/opt/ords \
  --volume $work_path/apex/images:/ords/apex-images \
  -p $ords_port:8080 \
  oracle-ords:$ords_version

cd $work_path

echo ""
echo "--------- All installations are done, enjoy it! ---------"
echo "--------- http:// ---------"
##############################################################################################################

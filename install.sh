#!/bin/bash


##############################################################################################################

#source env.properties

quick_install=${1:-"N"}
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
url_check=""
oss_url='https://oracle-apex-bucket.s3.ap-northeast-1.amazonaws.com/'
oss_url1='https://cn-oracle-apex.oss-cn-shanghai-internal.aliyuncs.com/'
oss_url2='https://cn-oracle-apex.oss-cn-shanghai.aliyuncs.com/'

echo ">>> print all of input parameters..."
echo $*
echo ">>> end of print all of input parameters..."

##############################################################################################################

echo ""
echo "--------- Step 1: Download installation media ---------"
echo ""


work_path=`pwd`

echo ">>> current work path is $work_path"



# check if url is valid
function httpRequest()
{
    unset url_check

    #curl request
    info=`curl -s -m 10 --connect-timeout 10 -I $1`

    #get return code
    code=`echo $info|grep "HTTP"|awk '{print $2}'`
    #check return code
    if [ "$code" != "200" ];then
      echo ">>> $1 cannot be touched..."
      url_check="N"
    fi
}

# try to download media from different storages
function downloadFiles()
{
  # 1. try to download apex installation zip file
  cd $work_path/docker-xe/files
  if [ ! -f $apex_file_name ]; then
    httpRequest "$oss_url$apex_file_name"
    if [ "$url_check" = "N" ]; then
      httpRequest "$oss_url2$apex_file_name"
      if [ "$url_check" = "N" ]; then
        exit;
      else
        curl -o $apex_file_name $oss_url2$apex_file_name
      fi
    else
      curl -o $apex_file_name $oss_url$apex_file_name
    fi
  fi

  # 2. try to download ords installation zip file
  cd $work_path/docker-ords/files
  if [ ! -f $ords_file_name ]; then
    httpRequest "$oss_url$ords_file_name"
    if [ "$url_check" = "N" ]; then
      httpRequest "$oss_url2$ords_file_name"
      if [ "$url_check" = "N" ]; then
        exit;
      else
        curl -o $ords_file_name $oss_url2$ords_file_name
        #curl -o $tomcat_file_name http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-9/v9.0.24/bin/apache-tomcat-9.0.24.zip
      fi
    else
      curl -o $ords_file_name $oss_url$ords_file_name
      #curl -o $tomcat_file_name http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-9/v9.0.24/bin/apache-tomcat-9.0.24.zip
    fi
  fi

  # 3. try to download oracle xe installation rpm file
  cd $work_path/docker-xe/files
  if [ ! -f $db_file_name ]; then
    httpRequest "$oss_url$db_file_name"
    if [ "$url_check" = "N" ]; then
      httpRequest "$oss_url2$db_file_name"
      if [ "$url_check" = "N" ]; then
        exit;
      else
        curl -o $db_file_name $oss_url2$db_file_name
      fi
    else
      curl -o $db_file_name $oss_url$db_file_name
    fi
  fi
}

# call downloadFiles() to try to download installation files
downloadFiles


cd $work_path/docker-xe

if [ ! -d ../apex ]; then
  echo ">>> unzip apex installation media ..."
  mkdir ../apex
  cp scripts/apex-install*  ../apex/
  unzip -oq files/$apex_file_name -d ../ &
fi;

echo ""
echo "--------- Step 2: compile oracle xe docker image ---------"
echo ""


echo ">>> docker image registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-xe:$db_version does not exist, begin to build docker image..."
    docker build -t registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-xe:$db_version --build-arg DB_SYS_PWD=$db_sys_pwd .


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
  registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-xe:$db_version


# wait until database configuration is done
rm -f xe_installation.log
docker logs oracle-xe >& xe_installation.log
while : ; do
    [[ `grep "Completed: ALTER PLUGGABLE DATABASE" xe_installation.log` ]] && break
    docker logs oracle-xe >& xe_installation.log
    echo "wait until oracle-xe configuration is done..."
    sleep 10
done

##############################################################################################################

echo ""
echo "--------- Step 4: install apex on xe docker image ---------"
echo ""

docker exec -it oracle-xe bash -c "source /home/oracle/.bashrc && cd /tmp/apex && chmod +x apex-install.sh && . apex-install.sh XEPDB1 $db_sys_pwd $apex_admin_username $apex_admin_pwd $apex_admin_email"


##############################################################################################################

echo ""
echo "--------- Step 5: compile oracle ords docker image ---------"
echo ""

cd $work_path/docker-ords/

if [[ "$(docker images -q registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-ords:$ords_version 2> /dev/null)" == "" ]]; then
  echo ">>> docker image registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-ords:$ords_version does not exist, begin to build docker image..."
  docker build -t registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-ords:$ords_version .
else
  echo ">>> docker image registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-ords:$ords_version is found, skip compile step and go on..."
fi;



##############################################################################################################

echo ""
echo "--------- Step 6: startup oracle ords docker image ---------"
echo ""
docker run -d -it --network=$docker_network \
  -e TZ=Asia/Shanghai \
  -e DB_HOSTNAME=oracle-xe \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=XEPDB1 \
  -e APEX_PUBLIC_USER_PASS=oracle \
  -e APEX_LISTENER_PASS=oracle \
  -e APEX_REST_PASS=oracle \
  -e ORDS_PASS=oracle \
  -e SYS_PASS=$db_sys_pwd \
  -e TOMCAT_FILE_NAME=$tomcat_file_name \
  --volume $work_path/oracle-ords/$ords_version/config:/opt/ords \
  --volume $work_path/apex/images:/ords/apex-images \
  -p $ords_port:8080 \
  registry-vpc.cn-shanghai.aliyuncs.com/kwang/oracle-ords:$ords_version

cd $work_path

echo ""
echo "--------- All installations are done, enjoy it! ---------"

##############################################################################################################

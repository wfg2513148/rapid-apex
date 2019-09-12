#!/bin/bash

echo ""
echo "--------- Step 0: Initialzation ---------"
echo ""

source env.properties

cd ~/docker/oracle-xe-apex-ords/docker-xe/

echo ">>> unzip apex installation media ..."
mkdir ../apex
cp scripts/apex-install*  ../apex/

unzip -oq files/$apex_file_name -d ../ &

echo ""
echo "--------- Step 1: compile oracle xe docker image ---------"
echo ""


docker build -t oracle-xe:$db_version --build-arg DB_SYS_PWD=$db_sys_pwd .

echo ""
echo "--------- Step 2: startup oracle xe docker image ---------"
echo ""
docker run -d \
  -p $db_port:1521 \
  -p $em_port:5500 \
  --name=oracle-xe \
  --volume ~/docker/oracle-xe-apex-ords/oradata:/opt/oracle/oradata \
  --volume ~/docker/oracle-xe-apex-ords/apex:/tmp/apex \
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


echo ""
echo "--------- Step 3: install apex on xe docker image ---------"
echo ""

docker exec -it oracle-xe bash -c "source /home/oracle/.bashrc && cd /tmp/apex && chmod +x apex-install.sh && . apex-install.sh $db_sys_pwd $apex_admin_pwd $db_pdb_name $apex_admin_email"



echo ""
echo "--------- Step 4: compile oracle ords docker image ---------"
echo ""
cd ../docker-ords/

docker build -t oracle-ords:$ords_version .

echo ""
echo "--------- Step 5: startup oracle ords docker image ---------"
echo ""
docker run -d -it --network=oracle_network \
  -e TZ=Asia/Shanghai \
  -e DB_HOSTNAME=oracle-xe \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=$db_pdb_name \
  -e APEX_PUBLIC_USER_PASS=$apex_public_user_pass \
  -e APEX_LISTENER_PASS=$apex_listener_pass \
  -e APEX_REST_PASS=$apex_rest_pass \
  -e ORDS_PASS=$ords_pass \
  -e SYS_PASS=$db_sys_pwd \
  --volume ~/docker/oracle-xe-apex-ords/oracle-ords/$ords_version/config:/opt/ords \
  --volume ~/docker/oracle-xe-apex-ords/apex/images:/ords/apex-images \
  -p $ords_port:8080 \
  oracle-ords:$ords_version

cd ~/docker/oracle-xe-apex-ords

echo ""
echo "--------- All installations are done, enjoy it! ---------"
echo ""



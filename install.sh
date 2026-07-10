#!/bin/bash
set -e


##############################################################################################################

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [ -f "$script_dir/tools/version-matrix.sh" ]; then
  # shellcheck source=tools/version-matrix.sh
  . "$script_dir/tools/version-matrix.sh"
fi

if [ "${1:-}" = "--list-versions" ]; then
  rapid_apex_print_matrix
  exit 0
fi

quick_install=${1:-"N"}
docker_network=${2:-'oracle_network'}
db_file_name=${3:-'oracle-database-xe-18c-1.0-1.x86_64.rpm'}
db_version=${4:-'18c'}
db_sys_pwd=${5:-'oracle'}
db_port=${6:-31521}
em_port=${7:-35500}
apex_file_name=${8:-'apex_21.2.zip'}
apex_version=${9:-'21.2'}
apex_admin_username=${10:-'ADMIN'}
apex_admin_pwd=${11:-'Welc0me@1'}
apex_admin_email=${12:-'wfgdlut@gmail.com'}
ords_file_name=${13:-'ords-21.4.2.062.1806.zip'}
ords_version=${14:-'21'}
ords_port=${15:-32521}
ip_address=${16:-'localhost'}
db_container_name=${RAPID_APEX_DB_CONTAINER:-oracle-xe}
ords_container_name=${RAPID_APEX_ORDS_CONTAINER:-oracle-ords}
legacy_db_timeout_seconds=${RAPID_APEX_LEGACY_DB_TIMEOUT:-2400}

url_check=""
fileName=""
docker_prefix='rapid-apex'

if command -v rapid_apex_validate_versions >/dev/null 2>&1; then
  rapid_apex_validate_versions "$db_version" "$apex_version" "$ords_version"
fi


echo ">>> print all of input parameters..."
echo $*
echo ">>> end of print all of input parameters..."

##############################################################################################################

echo ""
echo "--------- Step 1: Download installation media ---------"
echo ""

work_path=`pwd`
lab_name=${RAPID_APEX_LAB_NAME:-"${db_container_name%_db}"}
db_data_volume=${RAPID_APEX_DB_VOLUME:-"${lab_name}_db_data"}
ords_config_volume=${RAPID_APEX_ORDS_VOLUME:-"${lab_name}_ords_config"}
apex_unzip_pid=""

echo ">>> current work path is $work_path"


# check if url is valid
function httpRequest()
{
    unset url_check

    #curl request
    info=`curl -s -L -m 10 --connect-timeout 10 -I $1`

    #get return code
    code=`echo "$info"|grep "HTTP"|awk '{code=$2} END {print code}'`
    #check return code
    if [ "$code" != "200" ];then
      echo ">>> $1 cannot be touched..."
      url_check="N"
    fi
}

function official_media_url()
{
  local file_name=$1
  local apex_version_from_file

  case "$file_name" in
    apex_*.zip)
      apex_version_from_file=${file_name#apex_}
      apex_version_from_file=${apex_version_from_file%.zip}
      case "$apex_version_from_file" in
        5.0.4|5.1.4|18.1|18.2|19.1|19.2|20.1|20.2)
          printf 'https://download.oracle.com/otn/java/appexpress/%s\n' "$file_name"
          ;;
        21.1|21.2|22.1|22.2|23.1|23.2|24.1|24.2|26.1)
          printf 'https://download.oracle.com/otn_software/apex/%s\n' "$file_name"
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    ords-21.4.2.062.1806.zip)
      printf 'https://download.oracle.com/otn_software/java/ords/%s\n' "$file_name"
      ;;
    oracle-database-xe-18c-1.0-1.x86_64.rpm)
      printf 'https://download.oracle.com/otn-pub/otn_software/db-express/%s\n' "$file_name"
      ;;
    *)
      return 1
      ;;
  esac
}

function is_oracle_download_url()
{
  case "$1" in
    https://download.oracle.com/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}


# download installation file
function download()
{
  fileUrl=$1
  fileName=""
  officialUrl=""
  echo "fileUrl=$fileUrl"

  if [[ $1 =~ "/" ]]; then
    # user has downloaded the file, just copy it
    if [[ ${fileUrl:0:1} == "/" ]]; then
      echo ">>> copy installation file to files folder"
      fileName=${fileUrl##*"/"}
      cp $fileUrl .
    elif [[ $fileUrl =~ ^https?:// ]]; then
      if ! is_oracle_download_url "$fileUrl"; then
        echo ">>> refusing non-Oracle installation media URL: $fileUrl"
        exit 2
      fi
      echo ">>> download installation file from Oracle official URL"
      httpRequest "$fileUrl"
      if [ "$url_check" = "N" ]; then
        fileName=""
        exit;
      else
        fileName=${fileUrl##*"/"}
        curl --fail --location -o $fileName $fileUrl
      fi
    else
      echo ">>> relative media paths are not supported; use an absolute local path or Oracle official URL"
      exit 2
    fi;
  else
    fileName=$fileUrl
    if ! officialUrl="$(official_media_url "$fileName")"; then
      echo ">>> no Oracle official media URL is known for $fileName"
      exit 2
    fi
    echo ">>> download $fileName from Oracle official URL"
    if [ ! -f $fileName ]; then
      httpRequest "$officialUrl"
      if [ "$url_check" = "N" ]; then
        exit;
      else
        curl --fail --location -o $fileName $officialUrl
      fi
    fi
  fi;

}

function keep_only_selected_ords_media()
{
  local selected_file=$1
  local ords_media

  for ords_media in ords*.zip; do
    if [ ! -e "$ords_media" ]; then
      continue
    fi
    if [ "$ords_media" = "$selected_file" ]; then
      continue
    fi
    rm -f "$ords_media"
  done
}

function validate_zip_media()
{
  local media_file=$1
  local label=$2
  local test_output

  if [ ! -s "$media_file" ]; then
    echo "$label is empty or missing: $media_file" >&2
    exit 1
  fi

  if ! test_output=$(unzip -tq "$media_file" 2>&1); then
    echo "$label is not a valid zip archive: $media_file" >&2
    echo "$test_output" >&2
    echo "Oracle archive downloads may require accepting the license agreement in a browser." >&2
    echo "Download the authorized zip manually, place it at this path, or rerun install.sh with an absolute local media path." >&2
    exit 1
  fi
}




# download apex installation file
cd $work_path/docker-xe/files
download $apex_file_name
apex_file_name=$fileName
validate_zip_media "$apex_file_name" "APEX installation media"

echo ">>> apex_file_name="$apex_file_name
echo ""

# download ords installation file
cd $work_path/docker-ords/files
download $ords_file_name
ords_file_name=$fileName
validate_zip_media "$ords_file_name" "ORDS installation media"
keep_only_selected_ords_media "$ords_file_name"

echo ">>> ords_file_name="$ords_file_name
echo ""

# download oracle db installation file
cd $work_path/docker-xe/files
download $db_file_name
db_file_name=$fileName

echo ">>> db_file_name="$db_file_name
echo ""




cd $work_path/docker-xe

apex_media_marker="../apex/.rapid-apex-media"
if [ ! -d ../apex ] || [ ! -f "$apex_media_marker" ] || [ "$(cat "$apex_media_marker")" != "$apex_file_name" ]; then
  echo ">>> unzip apex installation media ..."
  rm -rf ../apex
  mkdir ../apex
  unzip -oq files/$apex_file_name -d ../ &
  apex_unzip_pid=$!
  echo "$apex_file_name" > "$apex_media_marker"
fi;
cp scripts/apex-install*  ../apex/

echo ""
echo "--------- Step 2: compile oracle xe docker image ---------"
echo ""

db_family="legacy-xe-rpm"
ords_install_family="legacy-simple"
ords_java_base_image="openjdk:8-jre-alpine"

if command -v rapid_apex_db_family >/dev/null 2>&1; then
  db_family="$(rapid_apex_db_family "$db_version")"
fi

if command -v rapid_apex_ords_install_family >/dev/null 2>&1; then
  ords_install_family="$(rapid_apex_ords_install_family "$ords_version")"
fi

if command -v rapid_apex_ords_java_base_image >/dev/null 2>&1; then
  ords_java_base_image="$(rapid_apex_ords_java_base_image "$ords_version")"
fi

if [ "$db_family" != "legacy-xe-rpm" ] && [ "$db_family" != "oracle-express-container" ]; then
  echo ">>> Oracle Database $db_version is recognized as $db_family."
  echo ">>> This legacy install path currently builds only the XE RPM image. Use a dedicated $db_family implementation for full installs."
  exit 2
fi

echo ">>> docker image $docker_prefix/oracle-xe:$db_version does not exist, begin to build docker image..."
    DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t $docker_prefix/oracle-xe:$db_version --build-arg DB_SYS_PWD=$db_sys_pwd --build-arg DB_FILE=$db_file_name .



echo ""
echo "--------- Step 3: startup oracle xe docker image ---------"
echo ""
docker volume create "$db_data_volume" >/dev/null
docker volume create "$ords_config_volume" >/dev/null

docker run -d \
  -p $db_port:1521 \
  -p $em_port:5500 \
  --name=$db_container_name \
  --volume $db_data_volume:/opt/oracle/oradata \
  --volume $work_path/apex:/tmp/apex \
  --network=$docker_network \
  $docker_prefix/oracle-xe:$db_version



# wait until database configuration is done
rm -f xe_installation.log
wait_seconds=0
legacy_ready_pattern="Completed: ALTER PLUGGABLE DATABASE|Pluggable database .* opened read write|DATABASE IS READY TO USE"
legacy_progress_pattern="DBCA progress|Starting Oracle|Configuring Oracle|DATABASE IS READY TO USE|Completed: ALTER PLUGGABLE DATABASE|Pluggable database .* opened read write"
echo ">>> waiting up to ${legacy_db_timeout_seconds}s for oracle-xe configuration; first startup can take several minutes."
while : ; do
    db_state=$(docker inspect --format '{{.State.Status}}' "$db_container_name" 2>/dev/null || true)
    db_health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$db_container_name" 2>/dev/null || true)
    if [ -z "$db_health" ]; then
      db_health=$db_state
    fi
    if [ "$db_state" = "exited" ] || [ "$db_state" = "dead" ]; then
      echo "oracle-xe container stopped before configuration completed." >&2
      docker logs --tail 120 "$db_container_name" >&2 || true
      exit 1
    fi
    if [ "$db_health" = "healthy" ]; then
      echo ">>> oracle-xe container is healthy."
      break
    fi
    docker logs "$db_container_name" > xe_installation.log 2>&1 || true
    if grep -Eiq "$legacy_ready_pattern" xe_installation.log; then
      echo ">>> oracle-xe configuration log reports database ready."
      break
    fi
    if [ "$wait_seconds" -ge "$legacy_db_timeout_seconds" ]; then
      echo "Timed out waiting for oracle-xe configuration." >&2
      docker logs --tail 120 "$db_container_name" >&2 || true
      exit 1
    fi
    echo "waiting for oracle-xe configuration (${wait_seconds}s/${legacy_db_timeout_seconds}s, state=${db_state:-unknown}, health=${db_health:-unknown})..."
    safe_progress=$(grep -Ei "$legacy_progress_pattern" xe_installation.log | tail -n 8 || true)
    if [ -n "$safe_progress" ]; then
      echo "$safe_progress" | sed 's/^/  recent: /'
    fi
    sleep 10
    wait_seconds=$((wait_seconds + 10))
done

##############################################################################################################

echo ""
echo "--------- Step 4: install apex on xe docker image ---------"
echo ""

if [ -n "$apex_unzip_pid" ]; then
  wait "$apex_unzip_pid"
fi

docker exec -i $db_container_name bash -c "source /home/oracle/.bashrc && cd /tmp/apex && chmod +x apex-install.sh && . apex-install.sh XEPDB1 $db_sys_pwd $apex_admin_username $apex_admin_pwd $apex_admin_email demo demo demo"


##############################################################################################################

echo ""
echo "--------- Step 5: compile oracle ords docker image ---------"
echo ""

cd $work_path/docker-ords/

if [[ "$(docker images -q $docker_prefix/oracle-ords:$ords_version 2> /dev/null)" == "" ]]; then
  echo ">>> docker image $docker_prefix/oracle-ords:$ords_version does not exist, begin to build docker image..."
  docker build -t $docker_prefix/oracle-ords:$ords_version --build-arg JAVA_BASE_IMAGE=$ords_java_base_image .
else
  echo ">>> docker image $docker_prefix/oracle-ords:$ords_version is found, skip compile step and go on..."
fi;



##############################################################################################################

echo ""
echo "--------- Step 6: startup oracle ords docker image ---------"
echo ""
docker run -d -it --network=$docker_network \
  --name=$ords_container_name \
  -e TZ=Asia/Shanghai \
  -e DB_HOSTNAME=$db_container_name \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=XEPDB1 \
  -e APEX_PUBLIC_USER_PASS=oracle \
  -e APEX_LISTENER_PASS=oracle \
  -e APEX_REST_PASS=oracle \
  -e ORDS_PASS=oracle \
  -e SYS_PASS=$db_sys_pwd \
  -e TOMCAT_FILE_NAME=$tomcat_file_name \
  -e ORDS_INSTALL_FAMILY=$ords_install_family \
  --volume $ords_config_volume:/opt/ords \
  --volume $work_path/apex/images:/ords/apex-images \
  -p $ords_port:8080 \
  $docker_prefix/oracle-ords:$ords_version

cd $work_path

echo ""
echo "----------------------- APEX Info -----------------------"
echo ""
echo "Admin URL: http://$ip_address:$ords_port/ords"
echo "Workspace: INTERNAL"
echo "User Name: $apex_admin_username"
echo "Password:  (redacted; use the configured APEX admin password)"
echo ""
echo "------------------------ DB Info ------------------------"
echo ""
echo "CDB: sqlplus sys/<password>@$ip_address:$db_port/XE as sysdba"
echo "PDB: sqlplus sys/<password>@$ip_address:$db_port/XEPDB1 as sysdba"
echo ""
echo "---------------------- Config Info ----------------------"
echo ""
echo "Database Data Volume: $db_data_volume"
echo "ORDS Config Volume: $ords_config_volume"
echo ""
echo "---------------------- Docker Info ----------------------"
echo ""
echo "docker images"
echo "docker ps -a"
echo ""
echo "--------- All installations are done, enjoy it! ---------"
echo ""
echo "star me if you like it: https://github.com/wfg2513148/rapid-apex"
echo ""

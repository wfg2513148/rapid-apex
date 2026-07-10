#!/bin/bash
set -eo pipefail

source /home/oracle/.bashrc

cd /tmp/apex/

# $1: db_pdb_name
# $2: db_sys_pwd
# $3: apex_admin_username
# $4: apex_admin_pwd
# $5: apex_admin_email
# $6: demo_workspace_name
# $7: demo_workspace_user
# $8: demo_workspace_pwd
run_sqlplus_stage() {
  local stage_name=$1
  shift
  local log_file="/tmp/apex/${stage_name}.log"

  echo ">>> APEX SQL stage: ${stage_name}"
  set +e
  "$ORACLE_HOME/bin/sqlplus" "$@" 2>&1 | tee "$log_file"
  local sqlplus_status=${PIPESTATUS[0]}
  set -e
  if [ "$sqlplus_status" -ne 0 ]; then
    echo ">>> APEX SQL stage failed: ${stage_name} (exit ${sqlplus_status})" >&2
    echo ">>> Last lines from ${log_file}:" >&2
    tail -n 80 "$log_file" >&2 || true
    exit "$sqlplus_status"
  fi
}

run_sqlplus_stage apex-install "sys/$2@localhost/$1" as sysdba @apex-install.sql

run_sqlplus_stage apex-install-post "sys/$2@localhost/$1" as sysdba @apex-install-post.sql "$3" "$4" "$5"

demo_workspace_name=${6:-demo}
demo_workspace_user=${7:-demo}
demo_workspace_pwd=${8:-demo}

run_sqlplus_stage apex-install-demo-workspace "sys/$2@localhost/$1" as sysdba @apex-install-demo-workspace.sql "$demo_workspace_name" "$demo_workspace_user" "$demo_workspace_pwd"

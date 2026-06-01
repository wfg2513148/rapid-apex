#!/bin/bash

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
$ORACLE_HOME/bin/sqlplus sys/$2@localhost/$1 as sysdba @apex-install.sql

$ORACLE_HOME/bin/sqlplus sys/$2@localhost/$1 as sysdba @apex-install-post.sql $3 $4 $5

demo_workspace_name=${6:-demo}
demo_workspace_user=${7:-demo}
demo_workspace_pwd=${8:-demo}

$ORACLE_HOME/bin/sqlplus sys/$2@localhost/$1 as sysdba @apex-install-demo-workspace.sql $demo_workspace_name $demo_workspace_user $demo_workspace_pwd

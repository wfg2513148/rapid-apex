#!/bin/bash

source /home/oracle/.bashrc

cd /tmp/apex/

# $1: db_pdb_name
# $2: db_sys_pwd
# $3: apex_admin_username
# $4: apex_admin_pwd
# $5: apex_admin_email
$ORACLE_HOME/bin/sqlplus sys/$2@localhost/$1 as sysdba @apex-install.sql

$ORACLE_HOME/bin/sqlplus sys/$2@localhost/$1 as sysdba @apex-install-post.sql $3 $4 $5

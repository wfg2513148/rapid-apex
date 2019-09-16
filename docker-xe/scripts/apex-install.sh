#!/bin/bash

source /home/oracle/.bashrc

cd /tmp/apex/


# $1: db_sys_pwd
# $2: apex_admin_pwd
# $3: db_pdb_name
# $4: apex_admin_email
$ORACLE_HOME/bin/sqlplus sys/$1@localhost/$3 as sysdba @apex-install.sql

$ORACLE_HOME/bin/sqlplus sys/$1@localhost/$3 as sysdba @apex-install-post.sql $4 $2

#!/usr/bin/env bash
set -euo pipefail

workspace_name="${DEMO_WORKSPACE_NAME:-demo}"
workspace_user="${DEMO_WORKSPACE_USER:-demo}"
workspace_pwd="${DEMO_WORKSPACE_PWD:-demo}"

sql -s "sys/${ORACLE_PWD}@${DBHOST}:${DBPORT}/${DBSERVICENAME} as sysdba" <<SQL
@/ords-entrypoint.d/apex-install-demo-workspace.sql ${workspace_name} ${workspace_user} ${workspace_pwd}
SQL

ords config set standalone.http.port 8080 >/dev/null

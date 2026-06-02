#!/usr/bin/env bash
set -euo pipefail

apex_public_user_pwd="${ORACLE_USER_PWD:-oracle}"
apex_images="/opt/oracle/apex/${APEX_VER}/images"

ords --config /etc/ords/config install \
  --admin-user SYS \
  --proxy-user \
  --db-hostname "$DBHOST" \
  --db-port "$DBPORT" \
  --db-servicename "$DBSERVICENAME" \
  --gateway-mode proxied \
  --gateway-user APEX_PUBLIC_USER \
  --feature-sdw true \
  --feature-rest-enabled-sql true \
  --password-stdin <<ORDS_PASSWORD
${apex_public_user_pwd}
${apex_public_user_pwd}
${apex_public_user_pwd}
ORDS_PASSWORD

ords --config /etc/ords/config config set misc.defaultPage 'f?p=4550:1' >/dev/null
exec ords --config /etc/ords/config serve --port 8181 --apex-images "$apex_images"

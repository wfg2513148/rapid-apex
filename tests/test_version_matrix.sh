#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

# shellcheck source=../tools/version-matrix.sh
. "$ROOT_DIR/tools/version-matrix.sh"

for db_version in 18c 19c 26ai 26ai-ee; do
  rapid_apex_is_supported_db_version "$db_version"
done

for apex_version in \
  5.0.4 5.1.4 \
  18.1 18.2 \
  19.1 19.2 \
  20.1 20.2 \
  21.1 21.2 \
  22.1 22.2 \
  23.1 23.2 \
  24.1 24.2 \
  26.1; do
  rapid_apex_is_supported_apex_version "$apex_version"
  [[ "$(rapid_apex_apex_file_name "$apex_version")" == "apex_${apex_version}.zip" ]]
done

for ords_version in \
  21 21.x \
  22 22.x \
  23 23.x \
  24 24.x \
  25 25.x \
  26 26.x; do
  rapid_apex_is_supported_ords_version "$ords_version"
done

[[ "$(rapid_apex_db_family 18c)" == "oracle-express-container" ]]
[[ "$(rapid_apex_db_family 19c)" == "oracle-enterprise-ru-container" ]]
[[ "$(rapid_apex_db_family 26ai)" == "oracle-free-container" ]]
[[ "$(rapid_apex_db_family 26ai-ee)" == "oracle-enterprise-ru-container" ]]
[[ "$(rapid_apex_db_image_strategy 18c)" == "official-oracle-image-preferred" ]]
[[ "$(rapid_apex_db_image_strategy 19c)" == "official-oracle-image-byol" ]]
[[ "$(rapid_apex_db_image_strategy 26ai)" == "official-oracle-image" ]]
[[ "$(rapid_apex_db_image_strategy 26ai-ee)" == "official-oracle-image-byol" ]]
[[ "$(rapid_apex_db_license_family 19c)" == "byol" ]]
[[ "$(rapid_apex_db_license_family 26ai-ee)" == "byol" ]]

[[ "$(rapid_apex_ords_install_family 21)" == "legacy-simple" ]]
[[ "$(rapid_apex_ords_install_family 22)" == "official-oracle-image" ]]
[[ "$(rapid_apex_ords_image_strategy 26)" == "official-oracle-image-preferred" ]]
[[ "$(rapid_apex_ords_java_base_image 26)" == "eclipse-temurin:17-jre-alpine" ]]

rapid_apex_validate_versions 19c 24.2 25
rapid_apex_validate_versions 26ai 26.1 26
rapid_apex_validate_versions 26ai-ee 26.1 26

list_output="$("$ROOT_DIR/install.sh" --list-versions)"
grep -q "Oracle Database: 18c 19c 26ai 26ai-ee" <<<"$list_output"

if rapid_apex_validate_versions 11g 24.2 25 >/dev/null 2>&1; then
  echo "expected unsupported database version to fail" >&2
  exit 1
fi

if rapid_apex_validate_versions 19c 25.9 25 >/dev/null 2>&1; then
  echo "expected unsupported APEX version to fail" >&2
  exit 1
fi

if rapid_apex_validate_versions 19c 24.2 27 >/dev/null 2>&1; then
  echo "expected unsupported ORDS version to fail" >&2
  exit 1
fi

for unsupported_ords_version in 3.0.12 18.1 18.2 18.4 19.2 19.2.0 20 20.x; do
  if rapid_apex_validate_versions 18c 21.2 "$unsupported_ords_version" >/dev/null 2>&1; then
    echo "expected ORDS $unsupported_ords_version to be removed from supported versions" >&2
    exit 1
  fi
done

echo "version matrix guard passed"

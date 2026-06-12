#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
MATRIX_FILE="$ROOT_DIR/profiles/profile-matrix.tsv"
CLI="$ROOT_DIR/bin/rapid-apex"

if [[ ! -f "$MATRIX_FILE" ]]; then
  echo "expected profile matrix file: profiles/profile-matrix.tsv" >&2
  exit 1
fi

expected_profiles_file="$(mktemp)"
trap 'rm -f "$expected_profiles_file"' EXIT
line_number=0
while IFS=$'\t' read -r profile db apex ords license name db_port em_port ords_port; do
  line_number=$((line_number + 1))
  if [[ "$line_number" -eq 1 ]]; then
    [[ "$profile" == "profile" ]]
    [[ "$db" == "db" ]]
    [[ "$apex" == "apex" ]]
    [[ "$ords" == "ords" ]]
    [[ "$license" == "license" ]]
    [[ "$name" == "name" ]]
    [[ "$db_port" == "db_port" ]]
    [[ "$em_port" == "em_port" ]]
    [[ "$ords_port" == "ords_port" ]]
    continue
  fi

  [[ -n "$profile" ]]
  [[ -f "$ROOT_DIR/$profile" ]]
  printf '%s\n' "$profile" >>"$expected_profiles_file"

  "$CLI" validate --profile "$ROOT_DIR/$profile" >/dev/null
  "$CLI" install --dry-run --profile "$ROOT_DIR/$profile" >/dev/null

  profile_content="$(sed 's/"//g' "$ROOT_DIR/$profile")"
  grep -qx "RAPID_APEX_DB_VERSION=$db" <<<"$profile_content"
  grep -qx "RAPID_APEX_APEX_VERSION=$apex" <<<"$profile_content"
  grep -qx "RAPID_APEX_ORDS_VERSION=$ords" <<<"$profile_content"
  grep -qx "RAPID_APEX_NAME=$name" <<<"$profile_content"
  grep -qx "RAPID_APEX_DB_PORT=$db_port" <<<"$profile_content"
  grep -qx "RAPID_APEX_EM_PORT=$em_port" <<<"$profile_content"
  grep -qx "RAPID_APEX_ORDS_PORT=$ords_port" <<<"$profile_content"

  if [[ "$license" == "demo" ]]; then
    if grep -q "^RAPID_APEX_LICENSE_POLICY=" <<<"$profile_content"; then
      grep -qx "RAPID_APEX_LICENSE_POLICY=demo" <<<"$profile_content"
    fi
  else
    grep -qx "RAPID_APEX_LICENSE_POLICY=$license" <<<"$profile_content"
  fi
done <"$MATRIX_FILE"

for profile_path in "$ROOT_DIR"/profiles/*.env; do
  profile="profiles/$(basename "$profile_path")"
  if ! grep -qxF "$profile" "$expected_profiles_file"; then
    echo "profile is missing from profiles/profile-matrix.tsv: $profile" >&2
    exit 1
  fi
done

echo "profile matrix guard passed"

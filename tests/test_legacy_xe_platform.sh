#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

if ! grep -Eq 'DOCKER_BUILDKIT=1 docker build .*--platform linux/amd64 .*oracle-xe' "$ROOT_DIR/install.sh"; then
  echo "legacy XE Docker build must use BuildKit and force linux/amd64 because Oracle XE 18c RPM is x86_64-only" >&2
  exit 1
fi

if ! grep -q 'memory.max' "$ROOT_DIR/docker-xe/scripts/runOracle.sh"; then
  echo "legacy XE runtime must handle cgroup v2 memory limits" >&2
  exit 1
fi

if ! grep -q 'oracle.assistants.dbca.validate.ConfigurationParams=false' "$ROOT_DIR/docker-xe/Dockerfile"; then
  echo "legacy XE image must disable DBCA configuration parameter validation for cgroup v2 hosts" >&2
  exit 1
fi

if ! grep -q 'docker volume create "$db_data_volume"' "$ROOT_DIR/install.sh"; then
  echo "legacy XE install must use a Docker volume for database data" >&2
  exit 1
fi

if ! grep -q 'RAPID_APEX_LEGACY_DB_TIMEOUT:-2400' "$ROOT_DIR/install.sh"; then
  echo "legacy XE install must allow slow DBCA configuration on x86 compatibility VMs" >&2
  exit 1
fi

if grep -q -- '--volume $work_path/oradata:/opt/oracle/oradata' "$ROOT_DIR/install.sh"; then
  echo "legacy XE install must not mount the repository root oradata path" >&2
  exit 1
fi

if ! grep -q '_JAVA_OPTIONS="-Xint"' "$ROOT_DIR/docker-xe/scripts/runOracle.sh"; then
  echo "legacy XE runtime must disable Java JIT during DBCA configuration" >&2
  exit 1
fi

if ! grep -q '_db_data.*_ords_config' "$ROOT_DIR/lib/rapid-apex-cli.sh"; then
  echo "legacy XE destroy/recover must purge lab Docker volumes" >&2
  exit 1
fi

echo "legacy XE platform guard passed"

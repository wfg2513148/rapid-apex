#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
CLI="$ROOT_DIR/bin/rapid-apex"

list_output="$("$CLI" list-versions)"
grep -q "Oracle Database: 18c 19c 26ai 26ai-ee" <<<"$list_output"
grep -q "26.1" <<<"$list_output"
grep -q "26.x" <<<"$list_output"

validate_output="$("$CLI" validate --db 26ai --apex 26.1 --ords 26 --name codex-lab)"
grep -q "Rapid-APEX profile is valid" <<<"$validate_output"
grep -q "db=26ai apex=26.1 ords=26 name=codex-lab" <<<"$validate_output"

plan_output="$("$CLI" plan --db 26ai --apex 26.1 --ords 26 --name codex-lab)"
grep -q "Name: codex-lab" <<<"$plan_output"
grep -q "Database: 26ai (oracle-free-container, free, official-oracle-image)" <<<"$plan_output"
grep -q "APEX: 26.1 (apex_26.1.zip)" <<<"$plan_output"
grep -q "ORDS: 26 (official-oracle-image, official-oracle-image-preferred" <<<"$plan_output"
grep -q "Database official image: container-registry.oracle.com/database/free:latest" <<<"$plan_output"
grep -q "ORDS official image: container-registry.oracle.com/database/ords:26.1.1" <<<"$plan_output"
grep -q "https://download.oracle.com/otn_software/apex/apex_26.1.zip" <<<"$plan_output"
grep -q "Full install execution is implemented for legacy XE and official Database/ORDS profiles." <<<"$plan_output"

profile_output="$("$CLI" plan --profile "$ROOT_DIR/profiles/18c-apex212-ords21.env")"
grep -q "Name: apex212-xe18c-lab" <<<"$profile_output"
grep -q "Database: 18c (oracle-express-container, xe, official-oracle-image-preferred)" <<<"$profile_output"
grep -q "ORDS: 21 (legacy-simple" <<<"$profile_output"

for profile in "$ROOT_DIR"/profiles/*.env; do
  "$CLI" validate --profile "$profile" >/dev/null
  "$CLI" install --dry-run --profile "$profile" >/dev/null
done

override_output="$("$CLI" plan --profile "$ROOT_DIR/profiles/18c-apex212-ords21.env" --name override-lab --ords 21)"
grep -q "Name: override-lab" <<<"$override_output"
grep -q "ORDS: 21 (legacy-simple" <<<"$override_output"
grep -q "APEX media: https://download.oracle.com/otn_software/apex/apex_21.2.zip" <<<"$override_output"
grep -q "ORDS media: https://download.oracle.com/otn_software/java/ords/ords-21.4.2.062.1806.zip" <<<"$override_output"

legacy_apex_output="$("$CLI" plan --db 18c --apex 20.2 --ords 21 --name legacy-apex-lab)"
grep -q "APEX media: https://download.oracle.com/otn/java/appexpress/apex_20.2.zip" <<<"$legacy_apex_output"
if "$CLI" validate --db 18c --apex 20.2 --ords 20 >/tmp/rapid-apex-ords20.out 2>&1; then
  echo "expected ORDS 20 to be removed from supported versions" >&2
  rm -f /tmp/rapid-apex-ords20.out
  exit 1
fi
grep -q "Unsupported ORDS version: 20" /tmp/rapid-apex-ords20.out
rm -f /tmp/rapid-apex-ords20.out
if "$CLI" validate --db 18c --apex 5.1.4 --ords 3.0.12 >/tmp/rapid-apex-ords3.out 2>&1; then
  echo "expected ORDS 3.0.12 to be removed from supported versions" >&2
  rm -f /tmp/rapid-apex-ords3.out
  exit 1
fi
grep -q "Unsupported ORDS version: 3.0.12" /tmp/rapid-apex-ords3.out
rm -f /tmp/rapid-apex-ords3.out
if grep -q "oracle-apex-bucket\\|ords-20.x.zip\\|ords-21.x.zip" <<<"$override_output$legacy_apex_output"; then
  echo "legacy ORDS plans must use concrete media filenames" >&2
  exit 1
fi

dry_run_output="$("$CLI" install --dry-run --profile "$ROOT_DIR/profiles/26ai-apex261-ords26.env")"
grep -q "Rapid-APEX installation plan" <<<"$dry_run_output"
grep -q "Database: 26ai" <<<"$dry_run_output"

info_output="$("$CLI" info --profile "$ROOT_DIR/profiles/26ai-apex261-ords26.env")"
grep -q "Rapid-APEX environment" <<<"$info_output"
grep -q "Name: apex261-26ai-lab" <<<"$info_output"
grep -q "Database/APEX/ORDS: 26ai / 26.1 / 26" <<<"$info_output"
grep -q "Profile: $ROOT_DIR/profiles/26ai-apex261-ords26.env" <<<"$info_output"
grep -q "Database container: apex261-26ai-lab_db" <<<"$info_output"
grep -q "ORDS container: apex261-26ai-lab_ords" <<<"$info_output"
grep -q "ORDS HTTP: 32514" <<<"$info_output"
grep -q "Builder URL: http://localhost:32514/ords/" <<<"$info_output"
grep -q "Workspace: demo" <<<"$info_output"
grep -q "Evidence directory: $ROOT_DIR/.rapid-apex/evidence/apex261-26ai-lab" <<<"$info_output"
if grep -q "Unknown command" <<<"$info_output"; then
  echo "info command is not registered" >&2
  exit 1
fi

preflight_output="$("$CLI" preflight --db 26ai --apex 26.1 --ords 26 --name codex-lab 2>&1 || true)"
grep -q "Rapid-APEX preflight" <<<"$preflight_output"
if grep -q "Unknown command" <<<"$preflight_output"; then
  echo "preflight command is not registered" >&2
  exit 1
fi

status_output="$("$CLI" status --name codex-lab 2>&1 || true)"
if grep -q "Unknown command" <<<"$status_output"; then
  echo "status command is not registered" >&2
  exit 1
fi

fake_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin"' EXIT
cat >"$fake_bin/curl" <<'FAKE_CURL'
#!/usr/bin/env bash
set -euo pipefail
for arg in "$@"; do
  if [[ "$arg" == "--location" ]]; then
    echo "smoke must not follow APEX login redirects" >&2
    exit 47
  fi
done
printf '302'
FAKE_CURL
chmod +x "$fake_bin/curl"
smoke_output="$(PATH="$fake_bin:$PATH" "$CLI" smoke --db 26ai --apex 26.1 --ords 26 --name codex-lab --ords-port 9090)"
grep -q "Smoke check passed: http://localhost:9090/ords/ (HTTP 302)" <<<"$smoke_output"

browser_smoke_plan="$("$CLI" browser-smoke --dry-run --db 26ai --apex 26.1 --ords 26 --name codex-lab --ords-port 9090)"
grep -q "Browser smoke plan" <<<"$browser_smoke_plan"
grep -q "ORDS URL: http://localhost:9090/ords" <<<"$browser_smoke_plan"
grep -q "Workspace: demo" <<<"$browser_smoke_plan"
grep -q "Evidence directory: $ROOT_DIR/.rapid-apex/evidence/codex-lab" <<<"$browser_smoke_plan"

fake_browser_runner="$fake_bin/browser-runner"
cat >"$fake_browser_runner" <<'FAKE_BROWSER'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"${RAPID_APEX_BROWSER_RUNNER_CAPTURE:?}"
printf '{"status":"passed"}\n'
FAKE_BROWSER
chmod +x "$fake_browser_runner"
browser_runner_capture="$(mktemp)"
runner_output="$(RAPID_APEX_BROWSER_SMOKE_RUNNER="$fake_browser_runner" RAPID_APEX_BROWSER_RUNNER_CAPTURE="$browser_runner_capture" "$CLI" browser-smoke --db 26ai --apex 26.1 --ords 26 --name codex-lab --ords-port 9090 --app-name "Rapid Apex Test")"
grep -q '"status":"passed"' <<<"$runner_output"
grep -q -- "--ords-url http://localhost:9090/ords" "$browser_runner_capture"
grep -q -- "--app-name Rapid Apex Test" "$browser_runner_capture"
rm -f "$browser_runner_capture"

e2e_plan="$("$CLI" e2e --dry-run --db 26ai --apex 26.1 --ords 26 --name codex-lab --destroy-after --purge-data)"
grep -q "Rapid-APEX e2e plan" <<<"$e2e_plan"
grep -q "1. preflight" <<<"$e2e_plan"
grep -q "5. browser-smoke" <<<"$e2e_plan"
grep -q "6. destroy" <<<"$e2e_plan"
grep -q "purge generated lab data" <<<"$e2e_plan"
grep -q "Summary path: $ROOT_DIR/.rapid-apex/evidence/codex-lab/e2e-summary.json" <<<"$e2e_plan"

fake_e2e_dir="$(mktemp -d)"
fake_e2e_output="$(bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh';
  rapid_apex_cmd_preflight() { :; };
  rapid_apex_cmd_install() { :; };
  rapid_apex_cmd_status() { :; };
  rapid_apex_wait_for_http() { :; };
  rapid_apex_grant_runtime_proxy_users() { :; };
  rapid_apex_restart_ords_after_proxy_grant() { :; };
  rapid_apex_cmd_smoke() { :; };
  rapid_apex_cmd_browser_smoke() { printf '{\"status\":\"passed\",\"appName\":\"Rapid Apex Test\",\"appId\":\"101\",\"appAlias\":\"RAPID-APEX-TEST\",\"finalUrl\":\"http://localhost:9090/ords/r/demo/test/home\",\"evidence\":{\"workspaceHome\":\"$fake_e2e_dir/workspace-home.png\",\"applicationHome\":\"$fake_e2e_dir/application-home.png\"}}\n'; };
  rapid_apex_cmd_destroy() { :; };
  rapid_apex_cmd_e2e --db 26ai --apex 26.1 --ords 26 --name fake-e2e-lab --ords-port 9090 --evidence-dir '$fake_e2e_dir' --destroy-after")"
grep -q "E2E summary: $fake_e2e_dir/e2e-summary.json" <<<"$fake_e2e_output"
grep -q '"status": "passed"' "$fake_e2e_dir/e2e-summary.json"
grep -q '"exitStatus": 0' "$fake_e2e_dir/e2e-summary.json"
grep -q '"appId": "101"' "$fake_e2e_dir/e2e-summary.json"
grep -q '"finalUrl": "http://localhost:9090/ords/r/demo/test/home"' "$fake_e2e_dir/e2e-summary.json"
grep -q '"cleanupStatus": "passed"' "$fake_e2e_dir/e2e-summary.json"
if grep -q "demo/demo\\|RAPID_APEX_WORKSPACE_PASSWORD\\|password" "$fake_e2e_dir/e2e-summary.json"; then
  echo "e2e summary must not write passwords" >&2
  exit 1
fi
rm -rf "$fake_e2e_dir"

fake_existing_e2e_dir="$(mktemp -d)"
fake_existing_e2e_output="$(bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh';
  rapid_apex_cmd_preflight() { :; };
  rapid_apex_lab_containers_running() { return 0; };
  rapid_apex_cmd_install() { echo 'install should be skipped'; return 99; };
  rapid_apex_cmd_status() { :; };
  rapid_apex_wait_for_http() { :; };
  rapid_apex_grant_runtime_proxy_users() { :; };
  rapid_apex_restart_ords_after_proxy_grant() { :; };
  rapid_apex_cmd_smoke() { :; };
  rapid_apex_cmd_browser_smoke() { printf '{\"status\":\"passed\"}\n'; };
  rapid_apex_cmd_e2e --db 26ai --apex 26.1 --ords 26 --name existing-e2e-lab --ords-port 9090 --evidence-dir '$fake_existing_e2e_dir'")"
grep -q "Lab containers already exist and are running; skipping install." <<<"$fake_existing_e2e_output"
if grep -q "install should be skipped" <<<"$fake_existing_e2e_output"; then
  echo "e2e must not reinstall over an already running lab" >&2
  exit 1
fi
grep -q '"status": "passed"' "$fake_existing_e2e_dir/e2e-summary.json"
rm -rf "$fake_existing_e2e_dir"

fake_failed_e2e_dir="$(mktemp -d)"
if bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh';
  rapid_apex_cmd_preflight() { return 2; };
  rapid_apex_cmd_e2e --db 26ai --apex 26.1 --ords 26 --name failed-e2e-lab --evidence-dir '$fake_failed_e2e_dir'" >/tmp/rapid-apex-failed-e2e.out 2>&1; then
  echo "expected fake failed e2e to return non-zero" >&2
  rm -rf "$fake_failed_e2e_dir" /tmp/rapid-apex-failed-e2e.out
  exit 1
fi
grep -q '"status": "failed"' "$fake_failed_e2e_dir/e2e-summary.json"
grep -q '"exitStatus": 2' "$fake_failed_e2e_dir/e2e-summary.json"
rm -rf "$fake_failed_e2e_dir" /tmp/rapid-apex-failed-e2e.out

generated_profile="$(mktemp)"
"$CLI" generate-profile --db 26ai --apex 26.1 --ords 26 --output "$generated_profile" >/tmp/rapid-apex-generate.out
grep -q "Generated profile: $generated_profile" /tmp/rapid-apex-generate.out
grep -q "RAPID_APEX_NAME=apex261-26ai-lab" "$generated_profile"
grep -q "RAPID_APEX_DB_VERSION=26ai" "$generated_profile"
grep -q "RAPID_APEX_APEX_VERSION=26.1" "$generated_profile"
grep -q "RAPID_APEX_ORDS_VERSION=26" "$generated_profile"
grep -q "RAPID_APEX_LICENSE_POLICY=demo" "$generated_profile"
"$CLI" validate --profile "$generated_profile" >/dev/null
rm -f "$generated_profile" /tmp/rapid-apex-generate.out

generated_byol_profile="$(mktemp)"
"$CLI" generate-profile --db 19c --apex 24.2 --ords 25 --license-policy byol --output "$generated_byol_profile" >/dev/null
grep -q "RAPID_APEX_NAME=apex242-19c-lab" "$generated_byol_profile"
grep -q "RAPID_APEX_LICENSE_POLICY=byol" "$generated_byol_profile"
grep -q "RAPID_APEX_DB_IMAGE=container-registry.oracle.com/database/enterprise:19.3.0.0" "$generated_byol_profile"
"$CLI" validate --profile "$generated_byol_profile" >/dev/null
rm -f "$generated_byol_profile"

generated_legacy_profile="$(mktemp)"
"$CLI" generate-profile --db 18c --apex 19.1 --ords 21 --output "$generated_legacy_profile" >/dev/null
grep -q "RAPID_APEX_NAME=apex191-xe18c-lab" "$generated_legacy_profile"
grep -q "RAPID_APEX_DB_PORT=31521" "$generated_legacy_profile"
"$CLI" validate --profile "$generated_legacy_profile" >/dev/null
rm -f "$generated_legacy_profile"

generated_ee26_profile="$(mktemp)"
"$CLI" generate-profile --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol --output "$generated_ee26_profile" >/dev/null
grep -q "RAPID_APEX_NAME=apex261-26ai-ee-lab" "$generated_ee26_profile"
grep -q "RAPID_APEX_DB_IMAGE=container-registry.oracle.com/database/enterprise:latest" "$generated_ee26_profile"
"$CLI" validate --profile "$generated_ee26_profile" >/dev/null
rm -f "$generated_ee26_profile"

if "$CLI" generate-profile --db 19c --apex 24.2 --ords 25 >/tmp/rapid-apex-generate-byol.out 2>&1; then
  echo "expected 19c profile generation to require BYOL license policy" >&2
  rm -f /tmp/rapid-apex-generate-byol.out
  exit 1
fi
grep -q "requires --license-policy byol" /tmp/rapid-apex-generate-byol.out
rm -f /tmp/rapid-apex-generate-byol.out

byol_output="$("$CLI" plan --db 19c --apex 24.2 --ords 25 --license-policy byol --name oracle19c-lab)"
grep -q "Name: oracle19c-lab" <<<"$byol_output"
grep -q "Database: 19c (oracle-enterprise-ru-container, byol, official-oracle-image-byol)" <<<"$byol_output"
grep -q "License policy: byol" <<<"$byol_output"
grep -q "Database official image: container-registry.oracle.com/database/enterprise:19.3.0.0" <<<"$byol_output"
grep -q "ORDS official image: container-registry.oracle.com/database/ords:25.4.0" <<<"$byol_output"

ords_tag_output="$("$CLI" plan --db 26ai --apex 26.1 --ords 26 --ords-image-tag 26.1.2 --name pinned-ords-lab)"
grep -q "ORDS official image: container-registry.oracle.com/database/ords:26.1.2" <<<"$ords_tag_output"

ee26_output="$("$CLI" plan --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol --name oracle26ai-ee-lab)"
grep -q "Database: 26ai-ee (oracle-enterprise-ru-container, byol, official-oracle-image-byol)" <<<"$ee26_output"
grep -q "Database official image: container-registry.oracle.com/database/enterprise:latest" <<<"$ee26_output"

if "$CLI" validate --db 26ai-ee --apex 26.1 --ords 26 >/tmp/rapid-apex-ee.out 2>&1; then
  echo "expected enterprise editions to require explicit BYOL license policy" >&2
  rm -f /tmp/rapid-apex-ee.out
  exit 1
fi
grep -q "requires --license-policy byol" /tmp/rapid-apex-ee.out
rm -f /tmp/rapid-apex-ee.out

if "$CLI" preflight --db 19c --apex 24.2 --ords 25 >/tmp/rapid-apex-19c-preflight.out 2>&1; then
  echo "expected 19c preflight to require explicit BYOL license policy" >&2
  rm -f /tmp/rapid-apex-19c-preflight.out
  exit 1
fi
grep -q "requires --license-policy byol" /tmp/rapid-apex-19c-preflight.out
rm -f /tmp/rapid-apex-19c-preflight.out

fake_docker_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin"' EXIT
cat >"$fake_docker_bin/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info) exit 0 ;;
  image)
    [[ "${2:-}" == "inspect" ]] && exit 1
    ;;
  manifest)
    [[ "${2:-}" == "inspect" ]] && {
      echo 'unauthorized: Auth failed' >&2
      exit 1
    }
    ;;
  ps) exit 0 ;;
esac
exit 1
FAKE_DOCKER
chmod +x "$fake_docker_bin/docker"

if PATH="$fake_docker_bin:$PATH" "$CLI" preflight --db 19c --apex 24.2 --ords 25 --license-policy byol --name oracle19c-lab >/tmp/rapid-apex-19c-auth.out 2>&1; then
  echo "expected 19c BYOL preflight to fail without registry authorization" >&2
  rm -f /tmp/rapid-apex-19c-auth.out
  exit 1
fi
grep -q "Database official image is not reachable: container-registry.oracle.com/database/enterprise:19.3.0.0" /tmp/rapid-apex-19c-auth.out
grep -q "accept the required BYOL image terms" /tmp/rapid-apex-19c-auth.out
grep -q "Open: https://container-registry.oracle.com/ords/ocr/ba/database/enterprise" /tmp/rapid-apex-19c-auth.out
grep -q "Run: docker login container-registry.oracle.com" /tmp/rapid-apex-19c-auth.out
grep -q "Run: docker pull container-registry.oracle.com/database/enterprise:19.3.0.0" /tmp/rapid-apex-19c-auth.out
grep -q "Retry: bin/rapid-apex preflight --db 19c --apex 24.2 --ords 25 --license-policy byol --name oracle19c-lab" /tmp/rapid-apex-19c-auth.out
rm -f /tmp/rapid-apex-19c-auth.out

fake_install_docker_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_install_docker_bin"' EXIT
install_capture="$(mktemp)"
cat >"$fake_install_docker_bin/apt-get" <<'FAKE_APT_GET'
#!/usr/bin/env bash
set -euo pipefail
printf 'apt-get %s\n' "$*" >>"${RAPID_APEX_INSTALL_CAPTURE:?}"
if [[ " $* " == *" install "* ]]; then
  cat >"${RAPID_APEX_FAKE_DOCKER_DIR:?}/docker" <<'FAKE_INSTALLED_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info) exit 0 ;;
  ps) exit 0 ;;
esac
exit 0
FAKE_INSTALLED_DOCKER
  chmod +x "${RAPID_APEX_FAKE_DOCKER_DIR:?}/docker"
fi
FAKE_APT_GET
chmod +x "$fake_install_docker_bin/apt-get"
cat >"$fake_install_docker_bin/sudo" <<'FAKE_SUDO'
#!/usr/bin/env bash
set -euo pipefail
exec "$@"
FAKE_SUDO
chmod +x "$fake_install_docker_bin/sudo"
PATH="$fake_install_docker_bin:/usr/bin:/bin" \
  RAPID_APEX_INSTALL_CAPTURE="$install_capture" \
  RAPID_APEX_FAKE_DOCKER_DIR="$fake_install_docker_bin" \
  bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_require_docker"
grep -q "apt-get update" "$install_capture"
grep -q "apt-get install -y docker.io" "$install_capture"
rm -f "$install_capture"

fake_start_docker_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_install_docker_bin" "$fake_start_docker_bin"' EXIT
start_capture="$(mktemp)"
docker_started_marker="$(mktemp)"
rm -f "$docker_started_marker"
cat >"$fake_start_docker_bin/docker" <<'FAKE_START_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info)
    [[ -f "${RAPID_APEX_DOCKER_STARTED_MARKER:?}" ]]
    ;;
  ps) exit 0 ;;
esac
FAKE_START_DOCKER
chmod +x "$fake_start_docker_bin/docker"
cat >"$fake_start_docker_bin/systemctl" <<'FAKE_SYSTEMCTL'
#!/usr/bin/env bash
set -euo pipefail
printf 'systemctl %s\n' "$*" >>"${RAPID_APEX_START_CAPTURE:?}"
touch "${RAPID_APEX_DOCKER_STARTED_MARKER:?}"
FAKE_SYSTEMCTL
chmod +x "$fake_start_docker_bin/systemctl"
cat >"$fake_start_docker_bin/sudo" <<'FAKE_SUDO'
#!/usr/bin/env bash
set -euo pipefail
exec "$@"
FAKE_SUDO
chmod +x "$fake_start_docker_bin/sudo"
PATH="$fake_start_docker_bin:/usr/bin:/bin" \
  RAPID_APEX_START_CAPTURE="$start_capture" \
  RAPID_APEX_DOCKER_STARTED_MARKER="$docker_started_marker" \
  bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_require_docker"
grep -q "systemctl enable --now docker" "$start_capture"
rm -f "$start_capture" "$docker_started_marker"

fake_colima_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_install_docker_bin" "$fake_start_docker_bin" "$fake_colima_bin"' EXIT
colima_capture="$(mktemp)"
colima_started_marker="$(mktemp)"
rm -f "$colima_started_marker"
cat >"$fake_colima_bin/docker" <<'FAKE_COLIMA_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info)
    [[ -f "${RAPID_APEX_COLIMA_STARTED_MARKER:?}" ]]
    ;;
  ps) exit 0 ;;
esac
FAKE_COLIMA_DOCKER
chmod +x "$fake_colima_bin/docker"
cat >"$fake_colima_bin/colima" <<'FAKE_COLIMA'
#!/usr/bin/env bash
set -euo pipefail
printf 'colima %s\n' "$*" >>"${RAPID_APEX_COLIMA_CAPTURE:?}"
touch "${RAPID_APEX_COLIMA_STARTED_MARKER:?}"
FAKE_COLIMA
chmod +x "$fake_colima_bin/colima"
PATH="$fake_colima_bin:/usr/bin:/bin" \
  RAPID_APEX_COLIMA_CAPTURE="$colima_capture" \
  RAPID_APEX_COLIMA_STARTED_MARKER="$colima_started_marker" \
  bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_require_docker"
grep -q "colima start" "$colima_capture"
rm -f "$colima_capture" "$colima_started_marker"

fake_required_tool_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_install_docker_bin" "$fake_start_docker_bin" "$fake_colima_bin" "$fake_required_tool_bin"' EXIT
required_tool_capture="$(mktemp)"
cat >"$fake_required_tool_bin/apt-get" <<'FAKE_REQUIRED_APT_GET'
#!/usr/bin/env bash
set -euo pipefail
printf 'apt-get %s\n' "$*" >>"${RAPID_APEX_REQUIRED_TOOL_CAPTURE:?}"
if [[ " $* " == *" install "* ]]; then
  cat >"${RAPID_APEX_FAKE_TOOL_DIR:?}/${RAPID_APEX_FAKE_TOOL_NAME:?}" <<'FAKE_REQUIRED_TOOL'
#!/usr/bin/env bash
set -euo pipefail
exit 0
FAKE_REQUIRED_TOOL
  chmod +x "${RAPID_APEX_FAKE_TOOL_DIR:?}/${RAPID_APEX_FAKE_TOOL_NAME:?}"
fi
FAKE_REQUIRED_APT_GET
chmod +x "$fake_required_tool_bin/apt-get"
RAPID_APEX_REQUIRED_TOOL_CAPTURE="$required_tool_capture" \
  RAPID_APEX_FAKE_TOOL_DIR="$fake_required_tool_bin" \
  RAPID_APEX_FAKE_TOOL_NAME="curl" \
  /bin/bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; PATH='$fake_required_tool_bin:/bin'; rapid_apex_require_command curl curl"
grep -q "apt-get update" "$required_tool_capture"
grep -q "apt-get install -y curl" "$required_tool_capture"
rm -f "$required_tool_capture"

fake_local_image_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin"' EXIT
cat >"$fake_local_image_bin/docker" <<'FAKE_LOCAL_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  image)
    [[ "${2:-}" == "inspect" ]] && exit 0
    ;;
  pull)
    echo "pull should not run when image exists locally" >&2
    exit 99
    ;;
esac
exit 0
FAKE_LOCAL_DOCKER
chmod +x "$fake_local_image_bin/docker"

pull_skip_output="$(PATH="$fake_local_image_bin:$PATH" bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_pull_image_if_needed container-registry.oracle.com/database/enterprise:19.3.0.0")"
grep -q "Docker image already exists locally: container-registry.oracle.com/database/enterprise:19.3.0.0" <<<"$pull_skip_output"

fake_retry_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin"' EXIT
retry_count_file="$(mktemp)"
cat >"$fake_retry_bin/curl" <<'FAKE_RETRY_CURL'
#!/usr/bin/env bash
set -euo pipefail
count=0
if [[ -f "${RAPID_APEX_RETRY_COUNT_FILE:?}" ]]; then
  count="$(cat "$RAPID_APEX_RETRY_COUNT_FILE")"
fi
count=$((count + 1))
printf '%s' "$count" >"$RAPID_APEX_RETRY_COUNT_FILE"
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) target="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if (( count < 2 )); then
  exit 22
fi
printf 'ok\n' >"$target"
FAKE_RETRY_CURL
chmod +x "$fake_retry_bin/curl"
retry_target="$(mktemp)"
rm -f "$retry_target"
PATH="$fake_retry_bin:$PATH" \
  RAPID_APEX_DOWNLOAD_ATTEMPTS=2 \
  RAPID_APEX_RETRY_SLEEP_SECONDS=0 \
  RAPID_APEX_RETRY_COUNT_FILE="$retry_count_file" \
  bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_download_file https://example.invalid/apex.zip '$retry_target'"
grep -q "ok" "$retry_target"
grep -q "2" "$retry_count_file"
rm -f "$retry_count_file" "$retry_target"

fake_proxy_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin"' EXIT
proxy_args_capture="$(mktemp)"
proxy_sql_capture="$(mktemp)"
restart_capture="$(mktemp)"
cat >"$fake_proxy_bin/docker" <<'FAKE_PROXY_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  container)
    [[ "${2:-}" == "inspect" ]] && exit 0
    ;;
  exec)
    printf '%s\n' "$*" >"${RAPID_APEX_PROXY_ARGS_CAPTURE:?}"
    cat >"${RAPID_APEX_PROXY_SQL_CAPTURE:?}"
    exit 0
    ;;
  restart)
    printf '%s\n' "$*" >"${RAPID_APEX_RESTART_CAPTURE:?}"
    exit 0
    ;;
esac
exit 1
FAKE_PROXY_DOCKER
chmod +x "$fake_proxy_bin/docker"

PATH="$fake_proxy_bin:$PATH" \
  RAPID_APEX_PROXY_ARGS_CAPTURE="$proxy_args_capture" \
  RAPID_APEX_PROXY_SQL_CAPTURE="$proxy_sql_capture" \
  bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_default_config; rapid_apex_parse_options --db 19c --apex 23.1 --ords 24 --license-policy byol --name proxy-lab; rapid_apex_grant_runtime_proxy_users"
grep -q "sys/oracle@localhost:1521/ORCLPDB1 as sysdba" "$proxy_args_capture"
grep -q "ORDS_PUBLIC_USER" "$proxy_sql_capture"
rm -f "$proxy_args_capture" "$proxy_sql_capture"

restart_output="$(PATH="$fake_proxy_bin:$PATH" RAPID_APEX_RESTART_CAPTURE="$restart_capture" bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_wait_for_http() { printf 'waited %s %s\n' \"\$1\" \"\$2\"; }; rapid_apex_default_config; rapid_apex_parse_options --db 19c --apex 23.1 --ords 24 --license-policy byol --name proxy-lab --ords-port 32523; rapid_apex_restart_ords_after_proxy_grant")"
grep -q "restart proxy-lab_ords" "$restart_capture"
grep -q "waited http://localhost:32523/ords/ proxy-lab_ords" <<<"$restart_output"
rm -f "$restart_capture"

fake_port_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin" "$fake_port_bin"' EXIT
cat >"$fake_port_bin/docker" <<'FAKE_PORT_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info) exit 0 ;;
  ps)
    if [[ "${2:-}" == "--format" ]]; then
      printf 'owner_db\t0.0.0.0:9090->8080/tcp\n'
    fi
    exit 0
    ;;
esac
exit 0
FAKE_PORT_DOCKER
chmod +x "$fake_port_bin/docker"
preflight_port_output="$(PATH="$fake_port_bin:$PATH" bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_default_config; rapid_apex_parse_options --db 26ai --apex 26.1 --ords 26 --name port-lab --db-port 31522 --em-port 35501 --ords-port 9090; rapid_apex_print_port_check 'ORDS HTTP' \"\$RAPID_APEX_ORDS_PORT\"" 2>&1 || true)"
grep -q "port 9090 is already in use" <<<"$preflight_port_output"
grep -q "owner_db" <<<"$preflight_port_output"

own_port_output="$(PATH="$fake_port_bin:$PATH" bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_default_config; rapid_apex_parse_options --db 26ai --apex 26.1 --ords 26 --name owner --ords-port 9090; rapid_apex_print_port_check 'ORDS HTTP' \"\$RAPID_APEX_ORDS_PORT\"")"
grep -q "PASS ORDS HTTP" <<<"$own_port_output"
grep -q "already bound by current lab container owner_db" <<<"$own_port_output"

fake_status_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin" "$fake_port_bin" "$fake_status_bin"' EXIT
cat >"$fake_status_bin/docker" <<'FAKE_STATUS_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info) exit 0 ;;
  ps)
    printf 'apex261-26ai-lab_ords\tcontainer-registry.oracle.com/database/ords:26.1.1\tUp 17 minutes\t0.0.0.0:32514->8181/tcp\n'
    printf 'apex261-26ai-lab_db\tcontainer-registry.oracle.com/database/free:latest\tUp 28 minutes (healthy)\t0.0.0.0:31522->1521/tcp, 0.0.0.0:35501->5500/tcp\n'
    exit 0
    ;;
esac
exit 0
FAKE_STATUS_DOCKER
chmod +x "$fake_status_bin/docker"
status_access_output="$(PATH="$fake_status_bin:$PATH" "$CLI" status --profile "$ROOT_DIR/profiles/26ai-apex261-ords26.env")"
grep -q "APEX access" <<<"$status_access_output"
grep -q "Builder URL: http://localhost:32514/ords/" <<<"$status_access_output"
grep -q "Workspace: demo" <<<"$status_access_output"
grep -q "Username: demo" <<<"$status_access_output"
grep -q "Password: demo" <<<"$status_access_output"
status_custom_password_output="$(PATH="$fake_status_bin:$PATH" "$CLI" status --profile "$ROOT_DIR/profiles/26ai-apex261-ords26.env" --password "do-not-print")"
grep -q "Password: <custom password is set; not printed>" <<<"$status_custom_password_output"
if grep -q "do-not-print" <<<"$status_custom_password_output"; then
  echo "status must not print custom workspace passwords" >&2
  exit 1
fi

fake_disk_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin" "$fake_port_bin" "$fake_status_bin" "$fake_disk_bin"' EXIT
cat >"$fake_disk_bin/df" <<'FAKE_DISK_DF'
#!/usr/bin/env bash
set -euo pipefail
cat <<'FAKE_DISK_OUTPUT'
Filesystem   1024-blocks      Used Available Capacity  Mounted on
/dev/disk3s5   482797652 306996948 146958228    68%    /System/Volumes/Data
FAKE_DISK_OUTPUT
FAKE_DISK_DF
chmod +x "$fake_disk_bin/df"
disk_output="$(PATH="$fake_disk_bin:$PATH" bash -c ". '$ROOT_DIR/lib/rapid-apex-cli.sh'; rapid_apex_check_official_install_disk" 2>&1)"
grep -q "PASS Disk free space is 140.2 GiB for official Database/ORDS profile" <<<"$disk_output"
if grep -q "awk: syntax error\\|0.0 GiB" <<<"$disk_output"; then
  echo "disk check must not emit awk errors or report 0.0 GiB for available space" >&2
  exit 1
fi

fake_recover_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin" "$fake_port_bin" "$fake_disk_bin" "$fake_recover_bin"' EXIT
recover_capture="$(mktemp)"
cat >"$fake_recover_bin/docker" <<'FAKE_RECOVER_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${RAPID_APEX_RECOVER_CAPTURE:?}"
case "${1:-}" in
  info) exit 0 ;;
  container)
    [[ "${2:-}" == "inspect" ]] && exit 0
    ;;
  rm) exit 0 ;;
  network)
    case "${2:-}" in
      inspect) exit 0 ;;
      rm) exit 0 ;;
    esac
    ;;
esac
exit 0
FAKE_RECOVER_DOCKER
chmod +x "$fake_recover_bin/docker"
recover_output="$(PATH="$fake_recover_bin:$PATH" RAPID_APEX_RECOVER_CAPTURE="$recover_capture" "$CLI" recover --name recover-lab)"
grep -q "Recovering selected lab resources: recover-lab" <<<"$recover_output"
grep -q "rm -f recover-lab_ords" "$recover_capture"
grep -q "rm -f recover-lab_db" "$recover_capture"
grep -q "network rm recover-lab_network" "$recover_capture"
rm -f "$recover_capture"

fake_destroy_fail_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_retry_bin" "$fake_proxy_bin" "$fake_port_bin" "$fake_recover_bin" "$fake_destroy_fail_bin"' EXIT
cat >"$fake_destroy_fail_bin/docker" <<'FAKE_DESTROY_FAIL_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  info) exit 0 ;;
  container)
    [[ "${2:-}" == "inspect" ]] && exit 0
    ;;
  rm)
    if [[ "${3:-}" == "broken-lab_db" ]]; then
      echo "database container removal failed" >&2
      exit 1
    fi
    exit 0
    ;;
  network)
    case "${2:-}" in
      inspect) exit 0 ;;
      rm)
        echo "network removal failed" >&2
        exit 1
        ;;
    esac
    ;;
esac
exit 0
FAKE_DESTROY_FAIL_DOCKER
chmod +x "$fake_destroy_fail_bin/docker"
if PATH="$fake_destroy_fail_bin:$PATH" "$CLI" destroy --name broken-lab >/tmp/rapid-apex-destroy-fail.out 2>&1; then
  echo "expected destroy to fail when selected lab resources remain" >&2
  rm -f /tmp/rapid-apex-destroy-fail.out
  exit 1
fi
grep -q "Failed to remove container: broken-lab_db" /tmp/rapid-apex-destroy-fail.out
grep -q "Failed to remove network: broken-lab_network" /tmp/rapid-apex-destroy-fail.out
grep -q "Residual Rapid-APEX resources for broken-lab:" /tmp/rapid-apex-destroy-fail.out
grep -q "container: broken-lab_db" /tmp/rapid-apex-destroy-fail.out
grep -q "network: broken-lab_network" /tmp/rapid-apex-destroy-fail.out
rm -f /tmp/rapid-apex-destroy-fail.out

echo "rapid-apex CLI guard passed"

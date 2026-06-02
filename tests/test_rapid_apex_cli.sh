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

plan_output="$("$CLI" plan --db 26ai --apex 26.1 --ords 26 --name codex-lab --media-base https://oss.example/rapid-apex)"
grep -q "Name: codex-lab" <<<"$plan_output"
grep -q "Database: 26ai (oracle-free-container, free, official-oracle-image)" <<<"$plan_output"
grep -q "APEX: 26.1 (apex_26.1.zip)" <<<"$plan_output"
grep -q "ORDS: 26 (official-oracle-image, official-oracle-image-preferred" <<<"$plan_output"
grep -q "Database official image: container-registry.oracle.com/database/free:latest" <<<"$plan_output"
grep -q "ORDS official image: container-registry.oracle.com/database/ords:26.1.1" <<<"$plan_output"
grep -q "https://download.oracle.com/otn_software/apex/apex_26.1.zip" <<<"$plan_output"
grep -q "Full install execution is implemented for legacy XE and official Database/ORDS profiles." <<<"$plan_output"

profile_output="$("$CLI" plan --profile "$ROOT_DIR/profiles/18c-apex191-ords192.env")"
grep -q "Name: apex191-xe18c-lab" <<<"$profile_output"
grep -q "Database: 18c (oracle-express-container, xe, official-oracle-image-preferred)" <<<"$profile_output"
grep -q "ORDS: 19.2 (legacy-simple" <<<"$profile_output"

for profile in "$ROOT_DIR"/profiles/*.env; do
  "$CLI" validate --profile "$profile" >/dev/null
  "$CLI" install --dry-run --profile "$profile" >/dev/null
done

override_output="$("$CLI" plan --profile "$ROOT_DIR/profiles/18c-apex191-ords192.env" --name override-lab --ords 21)"
grep -q "Name: override-lab" <<<"$override_output"
grep -q "ORDS: 21 (legacy-simple" <<<"$override_output"
grep -q "ORDS media: https://oracle-apex-bucket.s3.ap-northeast-1.amazonaws.com/ords-21.4.2.062.1806.zip" <<<"$override_output"

ords20_output="$("$CLI" plan --db 18c --apex 20.2 --ords 20 --name ords20-lab)"
grep -q "ORDS media: https://oracle-apex-bucket.s3.ap-northeast-1.amazonaws.com/ords-20.4.3.050.1904.zip" <<<"$ords20_output"
ords3_output="$("$CLI" plan --db 18c --apex 5.1.4 --ords 3.0.12 --name ords3-lab)"
grep -q "ORDS media: https://oracle-apex-bucket.s3.ap-northeast-1.amazonaws.com/ords-3.0.12.263.15.32.zip" <<<"$ords3_output"
if grep -q "ords-20.x.zip\\|ords-21.x.zip" <<<"$override_output$ords20_output"; then
  echo "legacy ORDS plans must use concrete media filenames" >&2
  exit 1
fi

dry_run_output="$("$CLI" install --dry-run --profile "$ROOT_DIR/profiles/26ai-apex261-ords26.env")"
grep -q "Rapid-APEX installation plan" <<<"$dry_run_output"
grep -q "Database: 26ai" <<<"$dry_run_output"

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
rm -f /tmp/rapid-apex-19c-auth.out

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

fake_proxy_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin" "$fake_docker_bin" "$fake_local_image_bin" "$fake_proxy_bin"' EXIT
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

echo "rapid-apex CLI guard passed"

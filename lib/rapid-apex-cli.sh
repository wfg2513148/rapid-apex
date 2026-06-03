#!/usr/bin/env bash

RAPID_APEX_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

# shellcheck source=../tools/version-matrix.sh
. "$RAPID_APEX_ROOT_DIR/tools/version-matrix.sh"

rapid_apex_usage() {
  cat <<'EOF'
Rapid-APEX one-stop Oracle APEX lab tool

Usage:
  rapid-apex list-versions
  rapid-apex validate [--profile FILE] [--db VERSION] [--apex VERSION] [--ords VERSION] [--license-policy demo|byol]
  rapid-apex plan [--profile FILE] [--db VERSION] [--apex VERSION] [--ords VERSION] [--license-policy demo|byol] [--name NAME] [--media-base URL] [--db-port PORT] [--ords-port PORT] [--db-image IMAGE] [--ords-image-tag TAG]
  rapid-apex generate-profile [same options as plan] [--output FILE]
  rapid-apex preflight [same options as plan]
  rapid-apex install --dry-run [same options as plan]
  rapid-apex status [--profile FILE] [--name NAME]
  rapid-apex logs [--profile FILE] [--name NAME]
  rapid-apex smoke [same options as plan]
  rapid-apex browser-smoke [same options as plan] [--ords-url URL] [--evidence-dir DIR]
  rapid-apex e2e [same options as plan] [--ords-url URL] [--evidence-dir DIR] [--destroy-after] [--purge-data]
  rapid-apex destroy [--profile FILE] [--name NAME] [--purge-data]
  rapid-apex recover [--profile FILE] [--name NAME] [--purge-data]

License policy:
  The default policy is demo, which allows XE and Free editions.
  Use --license-policy byol to plan Enterprise Edition installations with Oracle official enterprise images and your own valid Oracle license/terms.
EOF
}

rapid_apex_default_config() {
  RAPID_APEX_NAME="rapid-apex-lab"
  RAPID_APEX_DB_VERSION="26ai"
  RAPID_APEX_DB_IMAGE="${RAPID_APEX_DB_IMAGE:-}"
  RAPID_APEX_APEX_VERSION="26.1"
  RAPID_APEX_ORDS_VERSION="26"
  RAPID_APEX_ORDS_IMAGE_TAG="${RAPID_APEX_ORDS_IMAGE_TAG:-}"
  RAPID_APEX_MEDIA_BASE_URL="${RAPID_APEX_MEDIA_BASE_URL:-https://oracle-apex-bucket.s3.ap-northeast-1.amazonaws.com/}"
  RAPID_APEX_DB_PORT="1521"
  RAPID_APEX_EM_PORT="5500"
  RAPID_APEX_ORDS_PORT="8080"
  RAPID_APEX_DRY_RUN="N"
  RAPID_APEX_PROFILE=""
  RAPID_APEX_PROFILE_OUTPUT=""
  RAPID_APEX_LICENSE_POLICY="demo"
  RAPID_APEX_ORDS_URL=""
  RAPID_APEX_EVIDENCE_DIR=""
  RAPID_APEX_BROWSER_TIMEOUT="120000"
  RAPID_APEX_WORKSPACE="demo"
  RAPID_APEX_WORKSPACE_USER="demo"
  RAPID_APEX_WORKSPACE_PASSWORD="demo"
  RAPID_APEX_APP_NAME=""
  RAPID_APEX_APP_ID=""
  RAPID_APEX_DESTROY_AFTER="N"
  RAPID_APEX_PURGE_DATA="N"
  RAPID_APEX_NAME_SET="N"
  RAPID_APEX_DB_PORT_SET="N"
  RAPID_APEX_EM_PORT_SET="N"
  RAPID_APEX_ORDS_PORT_SET="N"
}

rapid_apex_load_profile() {
  local profile="$1"
  if [[ ! -f "$profile" ]]; then
    printf 'Profile not found: %s\n' "$profile" >&2
    return 1
  fi

  # Profiles are repository-owned shell fragments with simple key=value pairs.
  # shellcheck source=/dev/null
  . "$profile"
}

rapid_apex_parse_options() {
  local args=("$@")
  local i=0

  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --profile)
        RAPID_APEX_PROFILE="${args[$((i + 1))]:-}"
        if [[ -z "$RAPID_APEX_PROFILE" ]]; then
          printf 'Missing value for --profile\n' >&2
          return 1
        fi
        rapid_apex_load_profile "$RAPID_APEX_PROFILE"
        i=$((i + 2))
        ;;
      *)
        i=$((i + 1))
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        RAPID_APEX_PROFILE="${2:-}"
        if [[ -z "$RAPID_APEX_PROFILE" ]]; then
          printf 'Missing value for --profile\n' >&2
          return 1
        fi
        shift 2
        ;;
      --db)
        RAPID_APEX_DB_VERSION="${2:-}"
        shift 2
        ;;
      --db-image)
        RAPID_APEX_DB_IMAGE="${2:-}"
        shift 2
        ;;
      --apex)
        RAPID_APEX_APEX_VERSION="${2:-}"
        shift 2
        ;;
      --ords)
        RAPID_APEX_ORDS_VERSION="${2:-}"
        shift 2
        ;;
      --ords-image-tag)
        RAPID_APEX_ORDS_IMAGE_TAG="${2:-}"
        shift 2
        ;;
      --name)
        RAPID_APEX_NAME="${2:-}"
        RAPID_APEX_NAME_SET="Y"
        shift 2
        ;;
      --media-base)
        RAPID_APEX_MEDIA_BASE_URL="${2:-}"
        shift 2
        ;;
      --license-policy)
        RAPID_APEX_LICENSE_POLICY="${2:-}"
        shift 2
        ;;
      --db-port)
        RAPID_APEX_DB_PORT="${2:-}"
        RAPID_APEX_DB_PORT_SET="Y"
        shift 2
        ;;
      --em-port)
        RAPID_APEX_EM_PORT="${2:-}"
        RAPID_APEX_EM_PORT_SET="Y"
        shift 2
        ;;
      --ords-port)
        RAPID_APEX_ORDS_PORT="${2:-}"
        RAPID_APEX_ORDS_PORT_SET="Y"
        shift 2
        ;;
      --output)
        RAPID_APEX_PROFILE_OUTPUT="${2:-}"
        shift 2
        ;;
      --ords-url)
        RAPID_APEX_ORDS_URL="${2:-}"
        shift 2
        ;;
      --evidence-dir)
        RAPID_APEX_EVIDENCE_DIR="${2:-}"
        shift 2
        ;;
      --browser-timeout)
        RAPID_APEX_BROWSER_TIMEOUT="${2:-}"
        shift 2
        ;;
      --workspace)
        RAPID_APEX_WORKSPACE="${2:-}"
        shift 2
        ;;
      --username)
        RAPID_APEX_WORKSPACE_USER="${2:-}"
        shift 2
        ;;
      --password)
        RAPID_APEX_WORKSPACE_PASSWORD="${2:-}"
        shift 2
        ;;
      --app-name)
        RAPID_APEX_APP_NAME="${2:-}"
        shift 2
        ;;
      --app-id)
        RAPID_APEX_APP_ID="${2:-}"
        shift 2
        ;;
      --dry-run)
        RAPID_APEX_DRY_RUN="Y"
        shift
        ;;
      --destroy-after)
        RAPID_APEX_DESTROY_AFTER="Y"
        shift
        ;;
      --purge-data)
        RAPID_APEX_PURGE_DATA="Y"
        shift
        ;;
      -h|--help)
        rapid_apex_usage
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        rapid_apex_usage >&2
        return 1
        ;;
    esac
  done
}

rapid_apex_validate_config() {
  rapid_apex_validate_versions "$RAPID_APEX_DB_VERSION" "$RAPID_APEX_APEX_VERSION" "$RAPID_APEX_ORDS_VERSION"

  case "$RAPID_APEX_LICENSE_POLICY" in
    demo)
      if ! rapid_apex_is_license_safe_db_version "$RAPID_APEX_DB_VERSION"; then
        printf 'Database version %s requires --license-policy byol.\n' "$RAPID_APEX_DB_VERSION" >&2
        printf 'Default demo policy only allows XE or Free editions.\n' >&2
        return 2
      fi
      ;;
    byol)
      if [[ "$(rapid_apex_db_license_family "$RAPID_APEX_DB_VERSION")" != "byol" ]] && ! rapid_apex_is_license_safe_db_version "$RAPID_APEX_DB_VERSION"; then
        printf 'Database version %s is not supported by license policy %s.\n' "$RAPID_APEX_DB_VERSION" "$RAPID_APEX_LICENSE_POLICY" >&2
        return 2
      fi
      ;;
    *)
      printf 'Unsupported license policy: %s\n' "$RAPID_APEX_LICENSE_POLICY" >&2
      printf 'Supported license policies: demo, byol\n' >&2
      return 2
      ;;
  esac
}

rapid_apex_apex_media_file() {
  rapid_apex_apex_file_name "$RAPID_APEX_APEX_VERSION"
}

rapid_apex_apex_download_url() {
  case "$RAPID_APEX_APEX_VERSION" in
    23.1|23.2|24.1|24.2|26.1)
      printf 'https://download.oracle.com/otn_software/apex/apex_%s.zip\n' "$RAPID_APEX_APEX_VERSION"
      ;;
    *)
      printf '%s/%s\n' "${RAPID_APEX_MEDIA_BASE_URL%/}" "$(rapid_apex_apex_media_file)"
      ;;
  esac
}

rapid_apex_ords_media_file() {
  case "$RAPID_APEX_ORDS_VERSION" in
    3.0.12) printf '%s\n' ords-3.0.12.263.15.32.zip ;;
    18.1) printf '%s\n' ords-18.1.1.95.1251.zip ;;
    18.2) printf '%s\n' ords-18.2.0.183.1748.zip ;;
    18.4) printf '%s\n' ords-18.4.0.354.1002.zip ;;
    19.2|19.2.0) printf '%s\n' ords-19.2.0.199.1647.zip ;;
    20|20.x) printf '%s\n' ords-20.4.3.050.1904.zip ;;
    21|21.x) printf '%s\n' ords-21.4.2.062.1806.zip ;;
    22|22.x) printf '%s\n' ords-22.x.zip ;;
    23|23.x) printf '%s\n' ords-23.x.zip ;;
    24|24.x) printf '%s\n' ords-24.x.zip ;;
    25|25.x) printf '%s\n' ords-25.x.zip ;;
    26|26.x) printf '%s\n' ords-26.x.zip ;;
    *) return 1 ;;
  esac
}

rapid_apex_db_official_image() {
  if [[ -n "$RAPID_APEX_DB_IMAGE" ]]; then
    printf '%s\n' "$RAPID_APEX_DB_IMAGE"
    return 0
  fi

  case "$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")" in
    oracle-express-container) printf '%s\n' container-registry.oracle.com/database/express:latest ;;
    oracle-enterprise-ru-container)
      case "$RAPID_APEX_DB_VERSION" in
        19c) printf '%s\n' container-registry.oracle.com/database/enterprise:19.3.0.0 ;;
        26ai-ee) printf '%s\n' container-registry.oracle.com/database/enterprise:latest ;;
        *) return 1 ;;
      esac
      ;;
    oracle-free-container) printf '%s\n' container-registry.oracle.com/database/free:latest ;;
    *) return 1 ;;
  esac
}

rapid_apex_db_fallback_media() {
  case "$RAPID_APEX_DB_VERSION" in
    18c) printf '%s\n' oracle-database-xe-18c-1.0-1.x86_64.rpm ;;
    *) printf '%s\n' none ;;
  esac
}

rapid_apex_ords_official_image() {
  local tag

  case "$(rapid_apex_ords_image_strategy "$RAPID_APEX_ORDS_VERSION")" in
    official-oracle-image-preferred)
      if [[ -n "$RAPID_APEX_ORDS_IMAGE_TAG" ]]; then
        tag="$RAPID_APEX_ORDS_IMAGE_TAG"
      else
        case "$(rapid_apex_ords_major "$RAPID_APEX_ORDS_VERSION")" in
          22) tag="22.4.0" ;;
          23) tag="23.4.0" ;;
          24) tag="24.2.3" ;;
          25) tag="25.4.0" ;;
          26) tag="26.1.1" ;;
          *) return 1 ;;
        esac
      fi
      printf 'container-registry.oracle.com/database/ords:%s\n' "$tag"
      ;;
    *) printf '%s\n' none ;;
  esac
}

rapid_apex_print_plan() {
  local db_family db_strategy ords_family ords_strategy ords_java
  db_family="$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")"
  db_strategy="$(rapid_apex_db_image_strategy "$RAPID_APEX_DB_VERSION")"
  ords_family="$(rapid_apex_ords_install_family "$RAPID_APEX_ORDS_VERSION")"
  ords_strategy="$(rapid_apex_ords_image_strategy "$RAPID_APEX_ORDS_VERSION")"
  ords_java="$(rapid_apex_ords_java_base_image "$RAPID_APEX_ORDS_VERSION")"

  cat <<EOF
Rapid-APEX installation plan

Name: ${RAPID_APEX_NAME}
Database: ${RAPID_APEX_DB_VERSION} (${db_family}, $(rapid_apex_db_license_family "$RAPID_APEX_DB_VERSION"), ${db_strategy})
APEX: ${RAPID_APEX_APEX_VERSION} ($(rapid_apex_apex_media_file))
ORDS: ${RAPID_APEX_ORDS_VERSION} (${ords_family}, ${ords_strategy}, Java base: ${ords_java})
License policy: ${RAPID_APEX_LICENSE_POLICY}
Media base URL: ${RAPID_APEX_MEDIA_BASE_URL}

Ports:
  Database listener: ${RAPID_APEX_DB_PORT}
  EM Express: ${RAPID_APEX_EM_PORT}
  ORDS HTTP: ${RAPID_APEX_ORDS_PORT}

Docker resources:
  Network: ${RAPID_APEX_NAME}_network
  Database container: ${RAPID_APEX_NAME}_db
  ORDS container: ${RAPID_APEX_NAME}_ords
  Database official image: $(rapid_apex_db_official_image)
  Database fallback media: $(rapid_apex_db_fallback_media)
  APEX media: $(rapid_apex_apex_download_url)
  ORDS official image: $(rapid_apex_ords_official_image)
  ORDS media: ${RAPID_APEX_MEDIA_BASE_URL%/}/$(rapid_apex_ords_media_file)

Execution status:
  Full install execution is implemented for legacy XE and official Database/ORDS profiles.
EOF
}

rapid_apex_default_lab_name() {
  local apex_slug
  apex_slug="${RAPID_APEX_APEX_VERSION//./}"
  case "$RAPID_APEX_DB_VERSION" in
    18c) printf 'apex%s-xe18c-lab\n' "$apex_slug" ;;
    *) printf 'apex%s-%s-lab\n' "$apex_slug" "$RAPID_APEX_DB_VERSION" ;;
  esac
}

rapid_apex_apply_generated_profile_defaults() {
  if [[ "$RAPID_APEX_NAME_SET" == "N" ]]; then
    RAPID_APEX_NAME="$(rapid_apex_default_lab_name)"
  fi

  if [[ "$RAPID_APEX_DB_PORT_SET" == "N" ]] &&
     [[ "$RAPID_APEX_EM_PORT_SET" == "N" ]] &&
     [[ "$RAPID_APEX_ORDS_PORT_SET" == "N" ]]; then
    case "$RAPID_APEX_DB_VERSION" in
      18c)
        RAPID_APEX_DB_PORT="31521"
        RAPID_APEX_EM_PORT="35500"
        RAPID_APEX_ORDS_PORT="32513"
        ;;
      19c)
        RAPID_APEX_DB_PORT="31523"
        RAPID_APEX_EM_PORT="35502"
        RAPID_APEX_ORDS_PORT="32515"
        ;;
      26ai)
        RAPID_APEX_DB_PORT="31522"
        RAPID_APEX_EM_PORT="35501"
        RAPID_APEX_ORDS_PORT="32514"
        ;;
      26ai-ee)
        RAPID_APEX_DB_PORT="31525"
        RAPID_APEX_EM_PORT="35504"
        RAPID_APEX_ORDS_PORT="32517"
        ;;
    esac
  fi
}

rapid_apex_print_generated_profile() {
  printf 'RAPID_APEX_NAME=%s\n' "$RAPID_APEX_NAME"
  printf 'RAPID_APEX_DB_VERSION=%s\n' "$RAPID_APEX_DB_VERSION"
  printf 'RAPID_APEX_APEX_VERSION=%s\n' "$RAPID_APEX_APEX_VERSION"
  printf 'RAPID_APEX_ORDS_VERSION=%s\n' "$RAPID_APEX_ORDS_VERSION"
  printf 'RAPID_APEX_LICENSE_POLICY=%s\n' "$RAPID_APEX_LICENSE_POLICY"
  if [[ "$(rapid_apex_db_license_family "$RAPID_APEX_DB_VERSION")" == "byol" ]] || [[ -n "$RAPID_APEX_DB_IMAGE" ]]; then
    printf 'RAPID_APEX_DB_IMAGE=%s\n' "$(rapid_apex_db_official_image)"
  fi
  if [[ -n "$RAPID_APEX_ORDS_IMAGE_TAG" ]]; then
    printf 'RAPID_APEX_ORDS_IMAGE_TAG=%s\n' "$RAPID_APEX_ORDS_IMAGE_TAG"
  fi
  printf 'RAPID_APEX_DB_PORT=%s\n' "$RAPID_APEX_DB_PORT"
  printf 'RAPID_APEX_EM_PORT=%s\n' "$RAPID_APEX_EM_PORT"
  printf 'RAPID_APEX_ORDS_PORT=%s\n' "$RAPID_APEX_ORDS_PORT"
}

rapid_apex_db_service_name() {
  case "$RAPID_APEX_DB_VERSION" in
    26ai) printf '%s\n' FREEPDB1 ;;
    19c|26ai-ee) printf '%s\n' ORCLPDB1 ;;
    *) printf '%s\n' XEPDB1 ;;
  esac
}

rapid_apex_apex_schema_name() {
  local major minor

  major="${RAPID_APEX_APEX_VERSION%%.*}"
  minor="${RAPID_APEX_APEX_VERSION#*.}"
  minor="${minor%%.*}"
  printf 'APEX_%02d%02d00\n' "$major" "$minor"
}

rapid_apex_wait_for_health() {
  local container="$1"
  local timeout_seconds="${2:-1800}"
  local start_epoch
  local state
  local status

  start_epoch="$(date +%s)"
  while :; do
    state="$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || true)"
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container" 2>/dev/null || true)"
    if [[ -z "$status" ]]; then
      status="$state"
    fi

    case "$state" in
      exited|dead)
        printf 'Container stopped before becoming healthy: %s\n' "$container" >&2
        docker logs --tail 80 "$container" >&2 || true
        return 1
        ;;
    esac

    case "$status" in
      healthy)
        printf 'Container is healthy: %s\n' "$container"
        return 0
        ;;
    esac

    if (( "$(date +%s)" - start_epoch > timeout_seconds )); then
      printf 'Timed out waiting for container health: %s\n' "$container" >&2
      docker logs --tail 80 "$container" >&2 || true
      return 1
    fi
    printf 'Waiting for container health: %s (%s/%s)\n' "$container" "${state:-unknown}" "${status:-unknown}"
    sleep 15
  done
}

rapid_apex_download_file() {
  local url="$1"
  local target="$2"
  local attempts="${RAPID_APEX_DOWNLOAD_ATTEMPTS:-3}"
  local sleep_seconds="${RAPID_APEX_RETRY_SLEEP_SECONDS:-5}"
  local attempt=1

  mkdir -p "$(dirname "$target")"
  if [[ -f "$target" ]]; then
    printf 'Media already exists: %s\n' "$target" >&2
    return 0
  fi

  while (( attempt <= attempts )); do
    printf 'Downloading media: %s (attempt %s/%s)\n' "$url" "$attempt" "$attempts" >&2
    if curl --fail --location --show-error --output "$target" "$url"; then
      return 0
    fi
    rm -f "$target"
    if (( attempt < attempts )); then
      printf 'Download failed; retrying in %s seconds.\n' "$sleep_seconds" >&2
      sleep "$sleep_seconds"
    fi
    attempt=$((attempt + 1))
  done

  printf 'Download failed after %s attempts: %s\n' "$attempts" "$url" >&2
  printf 'Retry the command after checking network access or provide --media-base with a reachable mirror.\n' >&2
  return 1
}

rapid_apex_pull_image_if_needed() {
  local image="$1"

  if [[ "$image" == "none" ]]; then
    return 0
  fi

  if docker image inspect "$image" >/dev/null 2>&1; then
    printf 'Docker image already exists locally: %s\n' "$image"
    return 0
  fi

  docker pull "$image"
}

rapid_apex_prepare_apex_home() {
  local lab_dir="$1"
  local media_dir="$RAPID_APEX_ROOT_DIR/.rapid-apex/media"
  local media_file
  local apex_home="$lab_dir/apex"

  media_file="$media_dir/$(basename "$(rapid_apex_apex_download_url)")"

  if [[ ! -f "$apex_home/apxsilentins.sql" ]]; then
    rm -rf "$lab_dir/apex-src" "$apex_home"
    rapid_apex_download_file "$(rapid_apex_apex_download_url)" "$media_file"
    mkdir -p "$lab_dir/apex-src"
    unzip -oq "$media_file" -d "$lab_dir/apex-src"
    if [[ ! -d "$lab_dir/apex-src/apex" ]]; then
      printf 'APEX archive did not contain an apex directory: %s\n' "$media_file" >&2
      return 1
    fi
    mv "$lab_dir/apex-src/apex" "$apex_home"
    rm -rf "$lab_dir/apex-src"
    rm -f "$media_file"
  fi

  printf '%s\n' "$apex_home"
}

rapid_apex_check_db_image_access() {
  local image

  image="$(rapid_apex_db_official_image)"
  if [[ "$image" == "none" ]]; then
    return 0
  fi

  if docker image inspect "$image" >/dev/null 2>&1; then
    printf 'PASS Database official image is available locally: %s\n' "$image"
    return 0
  fi

  if docker manifest inspect "$image" >/dev/null 2>&1; then
    printf 'PASS Database official image is reachable from registry: %s\n' "$image"
    return 0
  fi

  printf 'FAIL Database official image is not reachable: %s\n' "$image"
  if [[ "$(rapid_apex_db_license_family "$RAPID_APEX_DB_VERSION")" == "byol" ]]; then
    printf '     Log in to Oracle Container Registry and accept the required BYOL image terms, then retry.\n'
  fi
  return 1
}

rapid_apex_check_ords_image_access() {
  local image

  image="$(rapid_apex_ords_official_image)"
  if [[ "$image" == "none" ]]; then
    return 0
  fi

  if docker image inspect "$image" >/dev/null 2>&1; then
    printf 'PASS ORDS official image is available locally: %s\n' "$image"
    return 0
  fi

  if docker manifest inspect "$image" >/dev/null 2>&1; then
    printf 'PASS ORDS official image is reachable from registry: %s\n' "$image"
    return 0
  fi

  printf 'FAIL ORDS official image is not reachable: %s\n' "$image"
  printf '     Provide --ords-image-tag TAG if this ORDS major requires a different official image tag.\n'
  return 1
}

rapid_apex_check_official_install_disk() {
  local required_kb=$((10 * 1024 * 1024))
  local available_kb

  available_kb="$(df -Pk "$RAPID_APEX_ROOT_DIR" | awk 'NR == 2 {print $4}')"
  if [[ -z "$available_kb" ]]; then
    printf 'WARN Disk free space could not be checked for %s\n' "$RAPID_APEX_ROOT_DIR"
    return 0
  fi

  if (( available_kb < required_kb )); then
    printf 'FAIL Disk free space is %.1f GiB; official Database/ORDS profiles require at least 10.0 GiB free under %s\n' \
      "$(awk "BEGIN {printf \"%.1f\", $available_kb / 1024 / 1024}")" \
      "$RAPID_APEX_ROOT_DIR"
    return 1
  fi

  printf 'PASS Disk free space is %.1f GiB for official Database/ORDS profile\n' \
    "$(awk "BEGIN {printf \"%.1f\", $available_kb / 1024 / 1024}")"
}

rapid_apex_install_official_db_ords() {
  local lab_dir="$RAPID_APEX_ROOT_DIR/.rapid-apex/labs/$RAPID_APEX_NAME"
  local db_container="${RAPID_APEX_NAME}_db"
  local ords_container="${RAPID_APEX_NAME}_ords"
  local db_service
  local apex_home

  db_service="$(rapid_apex_db_service_name)"
  rapid_apex_require_docker

  if docker container inspect "$db_container" >/dev/null 2>&1 || docker container inspect "$ords_container" >/dev/null 2>&1; then
    printf 'Containers already exist for lab %s. Run destroy first.\n' "$RAPID_APEX_NAME" >&2
    return 2
  fi

  mkdir -p "$lab_dir/db" "$lab_dir/ords-config" "$lab_dir/variables"
  chmod 777 "$lab_dir/db" "$lab_dir/ords-config" "$lab_dir/variables"

  if ! docker network inspect "${RAPID_APEX_NAME}_network" >/dev/null 2>&1; then
    docker network create -d bridge "${RAPID_APEX_NAME}_network"
  fi

  rapid_apex_pull_image_if_needed "$(rapid_apex_db_official_image)"
  rapid_apex_pull_image_if_needed "$(rapid_apex_ords_official_image)"

  docker run -d \
    --name "$db_container" \
    --network "${RAPID_APEX_NAME}_network" \
    -p "${RAPID_APEX_DB_PORT}:1521" \
    -p "${RAPID_APEX_EM_PORT}:5500" \
    -e ORACLE_PWD=oracle \
    -v "$lab_dir:/rapid-apex-lab" \
    -v "$RAPID_APEX_ROOT_DIR/docker-xe/scripts/apex-install-demo-workspace.sql:/rapid-apex-lab/apex-install-demo-workspace.sql:ro" \
    -v "$lab_dir/db:/opt/oracle/oradata" \
    "$(rapid_apex_db_official_image)"

  rapid_apex_wait_for_health "$db_container" 2400
  apex_home="$(rapid_apex_prepare_apex_home "$lab_dir")" || return "$?"
  printf 'CONN_STRING="%s"\n' "sys/oracle@${db_container}:1521/${db_service}" >"$lab_dir/variables/conn_string.txt"
  chmod 644 "$lab_dir/variables/conn_string.txt"

  if [[ "$(rapid_apex_ords_major "$RAPID_APEX_ORDS_VERSION")" -ge 24 ]]; then
    rapid_apex_install_apex_in_db_container "$db_container" "$db_service"

    docker run -d \
      --name "$ords_container" \
      --network "${RAPID_APEX_NAME}_network" \
      --entrypoint /bin/bash \
      -p "${RAPID_APEX_ORDS_PORT}:8181" \
      -e DBHOST="$db_container" \
      -e DBPORT=1521 \
      -e DBSERVICENAME="$db_service" \
      -e ORACLE_USER_PWD=oracle \
      -e APEX_VER="${RAPID_APEX_APEX_VERSION}.0" \
      -v "$lab_dir/ords-config:/etc/ords/config" \
      -v "$apex_home:/opt/oracle/apex/${RAPID_APEX_APEX_VERSION}.0:ro" \
      -v "$RAPID_APEX_ROOT_DIR/docker-ords/scripts/run-ords-official.sh:/ords-entrypoint.d/run-ords-official.sh:ro" \
      "$(rapid_apex_ords_official_image)" \
      /ords-entrypoint.d/run-ords-official.sh

    rapid_apex_wait_for_http "http://localhost:${RAPID_APEX_ORDS_PORT}/ords/" "$ords_container" 2400
    return 0
  fi

  docker run -d \
    --name "$ords_container" \
    --network "${RAPID_APEX_NAME}_network" \
    -p "${RAPID_APEX_ORDS_PORT}:8181" \
    -e DBHOST="$db_container" \
    -e DBPORT=1521 \
    -e DBSERVICENAME="$db_service" \
    -e ORACLE_PWD=oracle \
    -e ORACLE_USER_PWD=oracle \
    -e APEX_PWD=oracle \
    -e APEX_VER="${RAPID_APEX_APEX_VERSION}.0" \
    -e DEMO_WORKSPACE_NAME=demo \
    -e DEMO_WORKSPACE_USER=demo \
    -e DEMO_WORKSPACE_PWD=demo \
    -v "$lab_dir/ords-config:/etc/ords/config" \
    -v "$lab_dir/variables:/opt/oracle/variables" \
    -v "$apex_home:/opt/oracle/apex/${RAPID_APEX_APEX_VERSION}.0:ro" \
    -v "$RAPID_APEX_ROOT_DIR/docker-ords/scripts/create-demo-workspace-official.sh:/ords-entrypoint.d/10-create-demo-workspace.sh:ro" \
    -v "$RAPID_APEX_ROOT_DIR/docker-xe/scripts/apex-install-demo-workspace.sql:/ords-entrypoint.d/apex-install-demo-workspace.sql:ro" \
    "$(rapid_apex_ords_official_image)"

  rapid_apex_wait_for_http "http://localhost:${RAPID_APEX_ORDS_PORT}/ords/" "$ords_container" 2400
}

rapid_apex_install_apex_in_db_container() {
  local db_container="$1"
  local db_service="$2"
  local apex_schema
  local sqlplus_cmd

  apex_schema="$(rapid_apex_apex_schema_name)"
  sqlplus_cmd='SQLPLUS_BIN="$(command -v sqlplus || true)"; if [ -z "$SQLPLUS_BIN" ]; then SQLPLUS_BIN="$ORACLE_HOME/bin/sqlplus"; fi; cd /rapid-apex-lab/apex && "$SQLPLUS_BIN" -S "sys/oracle@localhost:1521/'"$db_service"' as sysdba"'
  docker exec -i "$db_container" bash -lc "$sqlplus_cmd" <<'SQL'
whenever sqlerror exit failure
@apexins.sql SYSAUX SYSAUX TEMP /i/
@apex_rest_config_core.sql /rapid-apex-lab/apex/ oracle oracle
alter profile default limit password_life_time UNLIMITED;
alter user APEX_PUBLIC_USER account unlock;
alter user APEX_PUBLIC_USER identified by oracle;
alter user APEX_LISTENER account unlock;
alter user APEX_LISTENER identified by oracle;
alter user APEX_REST_PUBLIC_USER account unlock;
alter user APEX_REST_PUBLIC_USER identified by oracle;
exit
SQL

  sqlplus_cmd='SQLPLUS_BIN="$(command -v sqlplus || true)"; if [ -z "$SQLPLUS_BIN" ]; then SQLPLUS_BIN="$ORACLE_HOME/bin/sqlplus"; fi; cd /rapid-apex-lab/apex/core && "$SQLPLUS_BIN" -S "sys/oracle@localhost:1521/'"$db_service"' as sysdba"'
  docker exec -i "$db_container" bash -lc "$sqlplus_cmd" <<SQL
whenever sqlerror exit failure
set define off
declare
  l_count number;
begin
  select count(*)
    into l_count
    from sys.dba_objects
   where owner = 'SYS'
     and object_name = 'RESOLVE_SYNONYM'
     and object_type in ('FUNCTION', 'PROCEDURE');

  if l_count > 0 then
    execute immediate 'grant execute on sys.resolve_synonym to ${apex_schema}';
  end if;
end;
/
declare
  l_count number;
begin
  select count(*)
    into l_count
    from sys.product_component_version
   where product like 'Oracle AI Database%';

  if l_count > 0 and '${RAPID_APEX_ORDS_VERSION}' in ('24', '24.x') then
    execute immediate 'alter session set "_ORACLE_SCRIPT"=true';
    execute immediate q'[
      create or replace view sys.product_component_version as
      select regexp_replace(regexp_substr(banner_full, '^(.*) Release', 1, 1, null, 1), '^Oracle AI Database', 'Oracle Database') product,
             regexp_replace(regexp_substr(banner_full, 'Version ([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)', 1, 1, null, 1), '^([0-9]+)\\..*', '\\1.0.0.0.0') version,
             regexp_substr(banner_full, 'Version ([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)', 1, 1, null, 1) version_full,
             regexp_substr(banner_full, ' - (.*)$', 1, 1, null, 1) status
        from sys.v_\$version
       where banner_full like 'Oracle%Database%'
    ]';
    execute immediate 'grant select on sys.product_component_version to public';
  end if;
end;
/
@validate_apex.sql x x ${apex_schema}
exec validate_apex;
exit
SQL

  sqlplus_cmd='SQLPLUS_BIN="$(command -v sqlplus || true)"; if [ -z "$SQLPLUS_BIN" ]; then SQLPLUS_BIN="$ORACLE_HOME/bin/sqlplus"; fi; "$SQLPLUS_BIN" -S "sys/oracle@localhost:1521/'"$db_service"' as sysdba"'
  docker exec -i "$db_container" bash -lc "$sqlplus_cmd" <<'SQL'
whenever sqlerror exit failure
@/rapid-apex-lab/apex-install-demo-workspace.sql demo demo demo
exit
SQL
}

rapid_apex_wait_for_http() {
  local url="$1"
  local container="$2"
  local timeout_seconds="${3:-600}"
  local start_epoch
  local http_code

  start_epoch="$(date +%s)"
  while :; do
    http_code="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 20 "$url" || true)"
    case "$http_code" in
      200|302|303)
        printf 'HTTP endpoint is ready: %s (HTTP %s)\n' "$url" "$http_code"
        return 0
        ;;
    esac

    if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
      printf 'Container stopped before HTTP endpoint became ready: %s\n' "$container" >&2
      docker logs --tail 120 "$container" >&2 || true
      return 1
    fi

    if (( "$(date +%s)" - start_epoch > timeout_seconds )); then
      printf 'Timed out waiting for HTTP endpoint: %s\n' "$url" >&2
      docker logs --tail 120 "$container" >&2 || true
      return 1
    fi
    printf 'Waiting for HTTP endpoint: %s (HTTP %s)\n' "$url" "${http_code:-000}"
    sleep 15
  done
}

rapid_apex_require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker CLI is not installed or not on PATH.\n' >&2
    return 2
  fi

  if ! docker info >/dev/null 2>&1; then
    printf 'Docker daemon is not reachable. Start Docker Desktop or Colima, then retry.\n' >&2
    return 2
  fi
}

rapid_apex_port_in_use() {
  local port="$1"

  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    return 0
  fi

  if command -v ss >/dev/null 2>&1 && ss -ltn | awk '{print $4}' | grep -Eq "(^|:)$port$"; then
    return 0
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Ports}}' | grep -Eq "(^|[,:])$port->"; then
    return 0
  fi

  return 1
}

rapid_apex_port_owner() {
  local port="$1"
  local owner=""

  if command -v lsof >/dev/null 2>&1; then
    owner="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR == 2 {print $1 " pid=" $2}')"
    if [[ -n "$owner" ]]; then
      printf '%s\n' "$owner"
      return 0
    fi
  fi

  if command -v docker >/dev/null 2>&1; then
    owner="$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | awk -v port="$port" '$0 ~ "(^|[,:])" port "->" {print $0; exit}')"
    if [[ -n "$owner" ]]; then
      printf '%s\n' "$owner"
      return 0
    fi
  fi

  printf 'owner unavailable\n'
}

rapid_apex_print_port_check() {
  local label="$1"
  local port="$2"
  local status
  local owner

  if rapid_apex_port_in_use "$port"; then
    status="0"
  else
    status="$?"
  fi
  case "$status" in
    0)
      owner="$(rapid_apex_port_owner "$port")"
      printf 'FAIL %-18s port %s is already in use (%s)\n' "$label" "$port" "$owner"
      return 1
      ;;
    1)
      printf 'PASS %-18s port %s is available\n' "$label" "$port"
      ;;
    2)
      printf 'WARN %-18s port %s was not checked because lsof is unavailable\n' "$label" "$port"
      ;;
  esac
}

rapid_apex_cmd_list_versions() {
  rapid_apex_print_matrix
}

rapid_apex_cmd_validate() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config
  printf 'Rapid-APEX profile is valid: db=%s apex=%s ords=%s name=%s\n' \
    "$RAPID_APEX_DB_VERSION" "$RAPID_APEX_APEX_VERSION" "$RAPID_APEX_ORDS_VERSION" "$RAPID_APEX_NAME"
}

rapid_apex_cmd_plan() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config
  rapid_apex_print_plan
}

rapid_apex_cmd_generate_profile() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config
  rapid_apex_apply_generated_profile_defaults

  if [[ -n "$RAPID_APEX_PROFILE_OUTPUT" ]]; then
    mkdir -p "$(dirname "$RAPID_APEX_PROFILE_OUTPUT")"
    rapid_apex_print_generated_profile >"$RAPID_APEX_PROFILE_OUTPUT"
    printf 'Generated profile: %s\n' "$RAPID_APEX_PROFILE_OUTPUT"
  else
    rapid_apex_print_generated_profile
  fi
}

rapid_apex_cmd_install() {
  local db_family ords_family

  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config

  if [[ "$RAPID_APEX_DRY_RUN" == "Y" ]]; then
    rapid_apex_print_plan
    return 0
  fi

  db_family="$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")"
  ords_family="$(rapid_apex_ords_install_family "$RAPID_APEX_ORDS_VERSION")"

  if [[ "$ords_family" == "official-oracle-image" ]] && {
    [[ "$db_family" == "oracle-free-container" ]] || [[ "$db_family" == "oracle-enterprise-ru-container" ]]
  }; then
    rapid_apex_install_official_db_ords
    return 0
  fi

  if [[ "$db_family" != "oracle-express-container" ]] || [[ "$ords_family" != "legacy-simple" ]]; then
    printf 'Installer execution is currently implemented for legacy 18c XE or official Database/ORDS profiles only.\n' >&2
    printf 'Requested: db=%s (%s), ords=%s (%s).\n' "$RAPID_APEX_DB_VERSION" "$db_family" "$RAPID_APEX_ORDS_VERSION" "$ords_family" >&2
    printf 'Re-run with --dry-run to inspect the validated plan.\n' >&2
    return 2
  fi

  rapid_apex_require_docker

  if ! docker network inspect "${RAPID_APEX_NAME}_network" >/dev/null 2>&1; then
    docker network create -d bridge "${RAPID_APEX_NAME}_network"
  fi

  RAPID_APEX_DB_CONTAINER="${RAPID_APEX_NAME}_db" \
  RAPID_APEX_ORDS_CONTAINER="${RAPID_APEX_NAME}_ords" \
  RAPID_APEX_MEDIA_BASE_URL="$RAPID_APEX_MEDIA_BASE_URL" \
    "$RAPID_APEX_ROOT_DIR/install.sh" \
      N \
      "${RAPID_APEX_NAME}_network" \
      "$(rapid_apex_db_fallback_media)" \
      "$RAPID_APEX_DB_VERSION" \
      oracle \
      "$RAPID_APEX_DB_PORT" \
      "$RAPID_APEX_EM_PORT" \
      "$(rapid_apex_apex_media_file)" \
      "$RAPID_APEX_APEX_VERSION" \
      ADMIN \
      'Welc0me@1' \
      'admin@example.com' \
      "$(rapid_apex_ords_media_file)" \
      "$RAPID_APEX_ORDS_VERSION" \
      "$RAPID_APEX_ORDS_PORT" \
      localhost
}

rapid_apex_cmd_preflight() {
  local failed="N"

  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config

  printf 'Rapid-APEX preflight\n\n'
  printf 'Name: %s\n' "$RAPID_APEX_NAME"
  printf 'Database/APEX/ORDS: %s / %s / %s\n' "$RAPID_APEX_DB_VERSION" "$RAPID_APEX_APEX_VERSION" "$RAPID_APEX_ORDS_VERSION"
  printf 'License policy: %s\n\n' "$RAPID_APEX_LICENSE_POLICY"

  if command -v docker >/dev/null 2>&1; then
    printf 'PASS Docker CLI is installed\n'
    if docker info >/dev/null 2>&1; then
      printf 'PASS Docker daemon is reachable\n'
      if [[ "$(rapid_apex_db_license_family "$RAPID_APEX_DB_VERSION")" == "byol" ]]; then
        rapid_apex_check_db_image_access || failed="Y"
      fi
      rapid_apex_check_ords_image_access || failed="Y"
      if [[ "$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")" != "oracle-express-container" ]] &&
         [[ "$(rapid_apex_ords_install_family "$RAPID_APEX_ORDS_VERSION")" == "official-oracle-image" ]]; then
        rapid_apex_check_official_install_disk || failed="Y"
      fi
    else
      printf 'FAIL Docker daemon is not reachable; start Docker Desktop or Colima\n'
      failed="Y"
    fi
  else
    printf 'FAIL Docker CLI is not installed or not on PATH\n'
    failed="Y"
  fi

  rapid_apex_print_port_check "Database listener" "$RAPID_APEX_DB_PORT" || failed="Y"
  rapid_apex_print_port_check "EM Express" "$RAPID_APEX_EM_PORT" || failed="Y"
  rapid_apex_print_port_check "ORDS HTTP" "$RAPID_APEX_ORDS_PORT" || failed="Y"

  if [[ "$failed" == "Y" ]]; then
    return 2
  fi

  printf '\nPreflight passed.\n'
}

rapid_apex_cmd_status() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_require_docker

  local output
  output="$(docker ps -a \
    --filter "name=^/${RAPID_APEX_NAME}_(db|ords)$" \
    --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}')"

  if [[ -n "$output" ]]; then
    printf 'NAMES\tIMAGE\tSTATUS\tPORTS\n'
    printf '%s\n' "$output"
  else
    printf 'No Rapid-APEX containers found for name: %s\n' "$RAPID_APEX_NAME"
  fi
}

rapid_apex_cmd_logs() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_require_docker

  local container
  for container in "${RAPID_APEX_NAME}_db" "${RAPID_APEX_NAME}_ords"; do
    if docker container inspect "$container" >/dev/null 2>&1; then
      printf '\n==> %s <==\n' "$container"
      docker logs --tail 200 "$container"
    else
      printf '\n==> %s <==\nContainer not found.\n' "$container"
    fi
  done
}

rapid_apex_cmd_smoke() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config

  if ! command -v curl >/dev/null 2>&1; then
    printf 'curl is required for smoke checks.\n' >&2
    return 2
  fi

  local url="http://localhost:${RAPID_APEX_ORDS_PORT}/ords/"
  local http_code
  printf 'Checking ORDS endpoint: %s\n' "$url"
  if ! http_code="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 20 "$url")"; then
    printf 'Smoke check failed: %s\n' "$url" >&2
    return 1
  fi

  case "$http_code" in
    200|302|303)
      printf 'Smoke check passed: %s (HTTP %s)\n' "$url" "$http_code"
      ;;
    *)
      printf 'Smoke check failed: %s returned HTTP %s\n' "$url" "$http_code" >&2
      return 1
      ;;
  esac
}

rapid_apex_ords_url() {
  if [[ -n "$RAPID_APEX_ORDS_URL" ]]; then
    printf '%s\n' "${RAPID_APEX_ORDS_URL%/}"
  else
    printf 'http://localhost:%s/ords\n' "$RAPID_APEX_ORDS_PORT"
  fi
}

rapid_apex_evidence_dir() {
  if [[ -n "$RAPID_APEX_EVIDENCE_DIR" ]]; then
    printf '%s\n' "$RAPID_APEX_EVIDENCE_DIR"
  else
    printf '%s/.rapid-apex/evidence/%s\n' "$RAPID_APEX_ROOT_DIR" "$RAPID_APEX_NAME"
  fi
}

rapid_apex_e2e_summary_path() {
  printf '%s/e2e-summary.json\n' "$(rapid_apex_evidence_dir)"
}

rapid_apex_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

rapid_apex_json_value() {
  local json="$1"
  local key="$2"
  printf '%s\n' "$json" |
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    tail -n 1
}

rapid_apex_json_string_or_null() {
  local value="$1"
  if [[ -n "$value" ]]; then
    printf '"%s"' "$(rapid_apex_json_escape "$value")"
  else
    printf 'null'
  fi
}

rapid_apex_write_e2e_summary() {
  local summary_path="$1"
  local status="$2"
  local exit_status="$3"
  local cleanup_status="$4"
  local started_at="$5"
  local ended_at="$6"
  local browser_output="${7:-}"
  local app_id app_name app_alias final_url workspace_home application_home failure_html failure_url

  app_id="$(rapid_apex_json_value "$browser_output" appId)"
  app_name="$(rapid_apex_json_value "$browser_output" appName)"
  app_alias="$(rapid_apex_json_value "$browser_output" appAlias)"
  final_url="$(rapid_apex_json_value "$browser_output" finalUrl)"
  workspace_home="$(rapid_apex_json_value "$browser_output" workspaceHome)"
  application_home="$(rapid_apex_json_value "$browser_output" applicationHome)"
  failure_html="$(rapid_apex_evidence_dir)/failure.html"
  failure_url="$(rapid_apex_evidence_dir)/failure-url.txt"

  mkdir -p "$(dirname "$summary_path")"
  cat >"$summary_path" <<EOF
{
  "status": "$(rapid_apex_json_escape "$status")",
  "exitStatus": ${exit_status},
  "startedAt": "$(rapid_apex_json_escape "$started_at")",
  "endedAt": "$(rapid_apex_json_escape "$ended_at")",
  "profile": $(rapid_apex_json_string_or_null "$RAPID_APEX_PROFILE"),
  "name": "$(rapid_apex_json_escape "$RAPID_APEX_NAME")",
  "versions": {
    "database": "$(rapid_apex_json_escape "$RAPID_APEX_DB_VERSION")",
    "apex": "$(rapid_apex_json_escape "$RAPID_APEX_APEX_VERSION")",
    "ords": "$(rapid_apex_json_escape "$RAPID_APEX_ORDS_VERSION")"
  },
  "licensePolicy": "$(rapid_apex_json_escape "$RAPID_APEX_LICENSE_POLICY")",
  "ports": {
    "database": ${RAPID_APEX_DB_PORT},
    "em": ${RAPID_APEX_EM_PORT},
    "ords": ${RAPID_APEX_ORDS_PORT}
  },
  "images": {
    "database": "$(rapid_apex_json_escape "$(rapid_apex_db_official_image)")",
    "ords": "$(rapid_apex_json_escape "$(rapid_apex_ords_official_image)")"
  },
  "ordsUrl": "$(rapid_apex_json_escape "$(rapid_apex_ords_url)")",
  "workspace": "$(rapid_apex_json_escape "$RAPID_APEX_WORKSPACE")",
  "username": "$(rapid_apex_json_escape "$RAPID_APEX_WORKSPACE_USER")",
  "appName": $(rapid_apex_json_string_or_null "$app_name"),
  "appId": $(rapid_apex_json_string_or_null "$app_id"),
  "appAlias": $(rapid_apex_json_string_or_null "$app_alias"),
  "finalUrl": $(rapid_apex_json_string_or_null "$final_url"),
  "evidence": {
    "directory": "$(rapid_apex_json_escape "$(rapid_apex_evidence_dir)")",
    "workspaceHome": $(rapid_apex_json_string_or_null "$workspace_home"),
    "applicationHome": $(rapid_apex_json_string_or_null "$application_home"),
    "failureHtml": $(rapid_apex_json_string_or_null "$([[ -f "$failure_html" ]] && printf '%s' "$failure_html")"),
    "failureUrl": $(rapid_apex_json_string_or_null "$([[ -f "$failure_url" ]] && printf '%s' "$failure_url")")
  },
  "cleanupStatus": "$(rapid_apex_json_escape "$cleanup_status")"
}
EOF
  printf 'E2E summary: %s\n' "$summary_path"
}

rapid_apex_prepare_playwright() {
  local tool_dir="$RAPID_APEX_ROOT_DIR/.rapid-apex/playwright"

  if ! command -v node >/dev/null 2>&1; then
    printf 'Node.js is required for browser-smoke.\n' >&2
    return 2
  fi
  if ! command -v npm >/dev/null 2>&1; then
    printf 'npm is required for browser-smoke.\n' >&2
    return 2
  fi

  mkdir -p "$tool_dir"
  if [[ ! -f "$tool_dir/package.json" ]]; then
    (cd "$tool_dir" && npm init -y >/dev/null)
  fi
  if [[ ! -d "$tool_dir/node_modules/playwright" ]]; then
    printf 'Installing Playwright into %s\n' "$tool_dir" >&2
    (cd "$tool_dir" && npm install playwright >/dev/null)
  fi
  if ! (cd "$tool_dir" && npx playwright install chromium >/dev/null); then
    printf 'Failed to install the Playwright Chromium browser.\n' >&2
    printf 'Retry manually with: cd %s && npx playwright install chromium\n' "$tool_dir" >&2
    return 2
  fi

  printf '%s/package.json\n' "$tool_dir"
}

rapid_apex_run_browser_smoke() {
  local evidence_dir="$1"
  local ords_url="$2"
  local runner="${RAPID_APEX_BROWSER_SMOKE_RUNNER:-}"
  local require_path
  local -a args

  mkdir -p "$evidence_dir"

  args=(
    --ords-url "$ords_url"
    --workspace "$RAPID_APEX_WORKSPACE"
    --username "$RAPID_APEX_WORKSPACE_USER"
    --password "$RAPID_APEX_WORKSPACE_PASSWORD"
    --evidence-dir "$evidence_dir"
    --timeout "$RAPID_APEX_BROWSER_TIMEOUT"
  )
  if [[ -n "$RAPID_APEX_APP_NAME" ]]; then
    args+=(--app-name "$RAPID_APEX_APP_NAME")
  fi
  if [[ -n "$RAPID_APEX_APP_ID" ]]; then
    args+=(--app-id "$RAPID_APEX_APP_ID")
  fi

  if [[ -n "$runner" ]]; then
    "$runner" "${args[@]}"
    return
  fi

  require_path="$(rapid_apex_prepare_playwright)"
  RAPID_APEX_PLAYWRIGHT_REQUIRE="$require_path" \
    node "$RAPID_APEX_ROOT_DIR/tools/browser-smoke.mjs" "${args[@]}"
}

rapid_apex_cmd_browser_smoke() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config

  local ords_url
  local evidence_dir

  ords_url="$(rapid_apex_ords_url)"
  evidence_dir="$(rapid_apex_evidence_dir)"

  if [[ "$RAPID_APEX_DRY_RUN" == "Y" ]]; then
    printf 'Browser smoke plan\n'
    printf '  ORDS URL: %s\n' "$ords_url"
    printf '  Workspace: %s\n' "$RAPID_APEX_WORKSPACE"
    printf '  User: %s\n' "$RAPID_APEX_WORKSPACE_USER"
    printf '  Evidence directory: %s\n' "$evidence_dir"
    return 0
  fi

  rapid_apex_run_browser_smoke "$evidence_dir" "$ords_url"
}

rapid_apex_grant_runtime_proxy_users() {
  local db_container="${RAPID_APEX_NAME}_db"
  local schema_name="$RAPID_APEX_WORKSPACE_USER"
  local db_family
  local db_service
  local ords_family
  local sqlplus_conn

  db_family="$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")"
  ords_family="$(rapid_apex_ords_install_family "$RAPID_APEX_ORDS_VERSION")"

  if [[ "$db_family" == "oracle-express-container" ]] &&
     [[ "$ords_family" == "legacy-simple" ]]; then
    sqlplus_conn='sys/oracle@localhost/XEPDB1 as sysdba'
  elif [[ "$ords_family" == "official-oracle-image" ]] && {
       [[ "$db_family" == "oracle-free-container" ]] || [[ "$db_family" == "oracle-enterprise-ru-container" ]]
     }; then
    db_service="$(rapid_apex_db_service_name)"
    sqlplus_conn="sys/oracle@localhost:1521/${db_service} as sysdba"
  else
    return 0
  fi

  if ! docker container inspect "$db_container" >/dev/null 2>&1; then
    printf 'Database container not found for proxy grant: %s\n' "$db_container" >&2
    return 2
  fi

  docker exec -i "$db_container" bash -lc 'SQLPLUS_BIN="$(command -v sqlplus || true)"; if [ -z "$SQLPLUS_BIN" ]; then SQLPLUS_BIN="$ORACLE_HOME/bin/sqlplus"; fi; "$SQLPLUS_BIN" -S "$1"' _ "$sqlplus_conn" <<SQL
whenever sqlerror exit sql.sqlcode
set define off
declare
  l_schema_name varchar2(128) := dbms_assert.simple_sql_name(upper('${schema_name}'));
begin
  for proxy_user in (
    select username
     from sys.dba_users
     where username in (
       'APEX_LISTENER',
       'APEX_PUBLIC_USER',
       'APEX_REST_PUBLIC_USER',
       'ORDS_PUBLIC_USER'
     )
  ) loop
    execute immediate 'alter user ' || l_schema_name ||
      ' grant connect through ' || dbms_assert.simple_sql_name(proxy_user.username);
  end loop;
end;
/
exit
SQL
}

rapid_apex_restart_ords_after_proxy_grant() {
  local ords_container="${RAPID_APEX_NAME}_ords"
  local db_family
  local ords_family

  db_family="$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")"
  ords_family="$(rapid_apex_ords_install_family "$RAPID_APEX_ORDS_VERSION")"

  if [[ "$ords_family" != "official-oracle-image" ]] ||
     { [[ "$db_family" != "oracle-free-container" ]] && [[ "$db_family" != "oracle-enterprise-ru-container" ]]; } ||
     [[ "$(rapid_apex_ords_major "$RAPID_APEX_ORDS_VERSION")" -lt 24 ]]; then
    return 0
  fi

  if ! docker container inspect "$ords_container" >/dev/null 2>&1; then
    printf 'ORDS container not found for restart: %s\n' "$ords_container" >&2
    return 2
  fi

  docker restart "$ords_container" >/dev/null
  rapid_apex_wait_for_http "$(rapid_apex_ords_url)/" "$ords_container" 900
}

rapid_apex_cmd_e2e() {
  local e2e_status=0
  local cleanup_status="skipped"
  local started_at ended_at summary_path browser_output

  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_validate_config
  summary_path="$(rapid_apex_e2e_summary_path)"

  if [[ "$RAPID_APEX_DRY_RUN" == "Y" ]]; then
    printf 'Rapid-APEX e2e plan\n'
    printf '  1. preflight\n'
    printf '  2. install\n'
    printf '  3. status\n'
    printf '  4. smoke\n'
    printf '  5. browser-smoke\n'
    if [[ "$RAPID_APEX_DESTROY_AFTER" == "Y" ]]; then
      printf '  6. destroy\n'
      if [[ "$RAPID_APEX_PURGE_DATA" == "Y" ]]; then
        printf '     purge generated lab data\n'
      fi
    fi
    printf '  Summary path: %s\n' "$summary_path"
    printf '\n'
    rapid_apex_print_plan
    return 0
  fi

  started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  rapid_apex_cmd_preflight "$@" || e2e_status="$?"
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_cmd_install "$@" || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_cmd_status "$@" || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_wait_for_http "$(rapid_apex_ords_url)/" "${RAPID_APEX_NAME}_ords" 900 || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_grant_runtime_proxy_users || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_restart_ords_after_proxy_grant || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_cmd_smoke "$@" || e2e_status="$?"
  fi
  if [[ "$e2e_status" == "0" ]]; then
    if browser_output="$(rapid_apex_cmd_browser_smoke "$@" 2>&1)"; then
      printf '%s\n' "$browser_output"
    else
      e2e_status="$?"
      printf '%s\n' "$browser_output" >&2
    fi
  fi
  if [[ "$RAPID_APEX_DESTROY_AFTER" == "Y" ]]; then
    if rapid_apex_cmd_destroy "$@"; then
      cleanup_status="passed"
    else
      cleanup_status="failed"
    fi
  fi
  ended_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  if [[ "$e2e_status" == "0" ]]; then
    rapid_apex_write_e2e_summary "$summary_path" "passed" "$e2e_status" "$cleanup_status" "$started_at" "$ended_at" "$browser_output"
  else
    rapid_apex_write_e2e_summary "$summary_path" "failed" "$e2e_status" "$cleanup_status" "$started_at" "$ended_at" "$browser_output"
  fi
  return "$e2e_status"
}

rapid_apex_cmd_destroy() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  rapid_apex_require_docker

  local failed="N"
  local container
  for container in "${RAPID_APEX_NAME}_ords" "${RAPID_APEX_NAME}_db"; do
    if docker container inspect "$container" >/dev/null 2>&1; then
      if docker rm -f "$container"; then
        printf 'Removed container: %s\n' "$container"
      else
        printf 'Failed to remove container: %s\n' "$container" >&2
        failed="Y"
      fi
    else
      printf 'Container not found: %s\n' "$container"
    fi
  done

  if docker network inspect "${RAPID_APEX_NAME}_network" >/dev/null 2>&1; then
    if docker network rm "${RAPID_APEX_NAME}_network"; then
      printf 'Removed network: %s_network\n' "$RAPID_APEX_NAME"
    else
      printf 'Failed to remove network: %s_network\n' "$RAPID_APEX_NAME" >&2
      failed="Y"
    fi
  else
    printf 'Network not found: %s_network\n' "$RAPID_APEX_NAME"
  fi

  if [[ "$RAPID_APEX_PURGE_DATA" == "Y" ]]; then
    local lab_dir="$RAPID_APEX_ROOT_DIR/.rapid-apex/labs/$RAPID_APEX_NAME"
    local legacy_dir
    local -a purge_dirs=("$lab_dir")
    if [[ "$RAPID_APEX_DB_VERSION" == "18c" || "$(rapid_apex_db_family "$RAPID_APEX_DB_VERSION")" == "legacy-xe-rpm" ]]; then
      purge_dirs+=("$RAPID_APEX_ROOT_DIR/oradata" "$RAPID_APEX_ROOT_DIR/oracle-ords")
    fi

    for legacy_dir in "${purge_dirs[@]}"; do
      if [[ -d "$legacy_dir" ]]; then
        if ! rm -rf "$legacy_dir" 2>/dev/null; then
          if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            sudo rm -rf "$legacy_dir"
          else
            printf 'Unable to remove lab data without sudo: %s\n' "$legacy_dir" >&2
            printf 'Retry with sudo or remove the directory manually after stopping containers.\n' >&2
            return 2
          fi
        fi
        printf 'Removed lab data: %s\n' "$legacy_dir"
      else
        printf 'Lab data not found: %s\n' "$legacy_dir"
      fi
    done
  fi

  if [[ "$failed" == "Y" ]]; then
    rapid_apex_report_residual_resources
    return 2
  fi
}

rapid_apex_report_residual_resources() {
  local printed="N"
  local container

  for container in "${RAPID_APEX_NAME}_ords" "${RAPID_APEX_NAME}_db"; do
    if docker container inspect "$container" >/dev/null 2>&1; then
      if [[ "$printed" == "N" ]]; then
        printf 'Residual Rapid-APEX resources for %s:\n' "$RAPID_APEX_NAME" >&2
        printed="Y"
      fi
      printf '  container: %s\n' "$container" >&2
    fi
  done

  if docker network inspect "${RAPID_APEX_NAME}_network" >/dev/null 2>&1; then
    if [[ "$printed" == "N" ]]; then
      printf 'Residual Rapid-APEX resources for %s:\n' "$RAPID_APEX_NAME" >&2
      printed="Y"
    fi
    printf '  network: %s_network\n' "$RAPID_APEX_NAME" >&2
  fi

  if [[ "$RAPID_APEX_PURGE_DATA" == "Y" ]]; then
    local lab_dir="$RAPID_APEX_ROOT_DIR/.rapid-apex/labs/$RAPID_APEX_NAME"
    if [[ -d "$lab_dir" ]]; then
      if [[ "$printed" == "N" ]]; then
        printf 'Residual Rapid-APEX resources for %s:\n' "$RAPID_APEX_NAME" >&2
      fi
      printf '  data: %s\n' "$lab_dir" >&2
    fi
  fi
}

rapid_apex_cmd_recover() {
  rapid_apex_default_config
  rapid_apex_parse_options "$@"
  printf 'Recovering selected lab resources: %s\n' "$RAPID_APEX_NAME"
  rapid_apex_cmd_destroy "$@"
}

rapid_apex_main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    rapid_apex_usage
    return 1
  fi
  shift || true

  case "$command" in
    list-versions) rapid_apex_cmd_list_versions "$@" ;;
    validate) rapid_apex_cmd_validate "$@" ;;
    plan) rapid_apex_cmd_plan "$@" ;;
    generate-profile) rapid_apex_cmd_generate_profile "$@" ;;
    preflight) rapid_apex_cmd_preflight "$@" ;;
    install) rapid_apex_cmd_install "$@" ;;
    status) rapid_apex_cmd_status "$@" ;;
    logs) rapid_apex_cmd_logs "$@" ;;
    smoke) rapid_apex_cmd_smoke "$@" ;;
    browser-smoke) rapid_apex_cmd_browser_smoke "$@" ;;
    e2e) rapid_apex_cmd_e2e "$@" ;;
    destroy) rapid_apex_cmd_destroy "$@" ;;
    recover) rapid_apex_cmd_recover "$@" ;;
    -h|--help|help) rapid_apex_usage ;;
    *)
      printf 'Unknown command: %s\n' "$command" >&2
      rapid_apex_usage >&2
      return 1
      ;;
  esac
}

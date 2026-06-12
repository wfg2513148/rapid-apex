#!/usr/bin/env bash

# This file is sourced by legacy installers, so it must not change shell options
# for the caller. Test scripts should enable strict mode before sourcing it.

rapid_apex_supported_db_versions() {
  printf '%s\n' 18c 19c 26ai 26ai-ee
}

rapid_apex_supported_apex_versions() {
  printf '%s\n' \
    5.0.4 5.1.4 \
    18.1 18.2 \
    19.1 19.2 \
    20.1 20.2 \
    21.1 21.2 \
    22.1 22.2 \
    23.1 23.2 \
    24.1 24.2 \
    26.1
}

rapid_apex_supported_ords_versions() {
  printf '%s\n' \
    21 21.x \
    22 22.x \
    23 23.x \
    24 24.x \
    25 25.x \
    26 26.x
}

rapid_apex_is_supported_db_version() {
  local version="$1"
  local supported_version
  while IFS= read -r supported_version; do
    if [[ "$supported_version" == "$version" ]]; then
      return 0
    fi
  done < <(rapid_apex_supported_db_versions)
  return 1
}

rapid_apex_is_supported_apex_version() {
  local version="$1"
  local supported_version
  while IFS= read -r supported_version; do
    if [[ "$supported_version" == "$version" ]]; then
      return 0
    fi
  done < <(rapid_apex_supported_apex_versions)
  return 1
}

rapid_apex_is_supported_ords_version() {
  local version="$1"
  local supported_version
  while IFS= read -r supported_version; do
    if [[ "$supported_version" == "$version" ]]; then
      return 0
    fi
  done < <(rapid_apex_supported_ords_versions)
  return 1
}

rapid_apex_db_family() {
  local version="$1"
  case "$version" in
    18c) printf '%s\n' oracle-express-container ;;
    19c|26ai-ee) printf '%s\n' oracle-enterprise-ru-container ;;
    26ai) printf '%s\n' oracle-free-container ;;
    *) return 1 ;;
  esac
}

rapid_apex_db_image_strategy() {
  local version="$1"
  case "$version" in
    18c) printf '%s\n' official-oracle-image-preferred ;;
    19c|26ai-ee) printf '%s\n' official-oracle-image-byol ;;
    26ai) printf '%s\n' official-oracle-image ;;
    *) return 1 ;;
  esac
}

rapid_apex_db_license_family() {
  local version="$1"
  case "$version" in
    18c) printf '%s\n' xe ;;
    19c|26ai-ee) printf '%s\n' byol ;;
    26ai) printf '%s\n' free ;;
    *) return 1 ;;
  esac
}

rapid_apex_is_license_safe_db_version() {
  local version="$1"
  case "$(rapid_apex_db_license_family "$version")" in
    xe|free) return 0 ;;
    *) return 1 ;;
  esac
}

rapid_apex_ords_major() {
  local version="$1"
  case "$version" in
    21|21.*) printf '%s\n' 21 ;;
    22|22.*) printf '%s\n' 22 ;;
    23|23.*) printf '%s\n' 23 ;;
    24|24.*) printf '%s\n' 24 ;;
    25|25.*) printf '%s\n' 25 ;;
    26|26.*) printf '%s\n' 26 ;;
    *) return 1 ;;
  esac
}

rapid_apex_ords_install_family() {
  local major
  major="$(rapid_apex_ords_major "$1")"
  case "$major" in
    21) printf '%s\n' legacy-simple ;;
    22|23|24|25|26) printf '%s\n' official-oracle-image ;;
    *) return 1 ;;
  esac
}

rapid_apex_ords_image_strategy() {
  local major
  major="$(rapid_apex_ords_major "$1")"
  case "$major" in
    21) printf '%s\n' build-from-official-oracle-media ;;
    22|23|24|25|26) printf '%s\n' official-oracle-image-preferred ;;
    *) return 1 ;;
  esac
}

rapid_apex_ords_java_base_image() {
  local major
  major="$(rapid_apex_ords_major "$1")"
  case "$major" in
    21) printf '%s\n' eclipse-temurin:8-jre-alpine ;;
    22|23|24|25|26) printf '%s\n' eclipse-temurin:17-jre-alpine ;;
    *) return 1 ;;
  esac
}

rapid_apex_apex_file_name() {
  local version="$1"
  printf 'apex_%s.zip\n' "$version"
}

rapid_apex_validate_versions() {
  local db_version="$1"
  local apex_version="$2"
  local ords_version="$3"
  local failed="N"

  if ! rapid_apex_is_supported_db_version "$db_version"; then
    printf 'Unsupported Oracle Database version: %s\n' "$db_version" >&2
    printf 'Supported database versions: %s\n' "$(rapid_apex_supported_db_versions | tr '\n' ' ')" >&2
    failed="Y"
  fi

  if ! rapid_apex_is_supported_apex_version "$apex_version"; then
    printf 'Unsupported Oracle APEX version: %s\n' "$apex_version" >&2
    printf 'Supported APEX versions: %s\n' "$(rapid_apex_supported_apex_versions | tr '\n' ' ')" >&2
    failed="Y"
  fi

  if ! rapid_apex_is_supported_ords_version "$ords_version"; then
    printf 'Unsupported ORDS version: %s\n' "$ords_version" >&2
    printf 'Supported ORDS versions: %s\n' "$(rapid_apex_supported_ords_versions | tr '\n' ' ')" >&2
    failed="Y"
  fi

  [[ "$failed" == "N" ]]
}

rapid_apex_print_matrix() {
  printf 'Oracle Database: %s\n' "$(rapid_apex_supported_db_versions | tr '\n' ' ')"
  printf 'Oracle APEX: %s\n' "$(rapid_apex_supported_apex_versions | tr '\n' ' ')"
  printf 'Oracle ORDS: %s\n' "$(rapid_apex_supported_ords_versions | tr '\n' ' ')"
}

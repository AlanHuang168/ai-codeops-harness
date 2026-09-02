#!/usr/bin/env bash

set -u

LC_ALL=C
export LC_ALL

SUCCESS=0
GENERAL_ERROR=1
INVALID_MANIFEST=2
CONFLICT_ABORTED=3
PARTIAL_FAILURE=4
UNSUPPORTED_ADAPTER=5
INVALID_TARGET=6

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || exit "$GENERAL_ERROR"
SOURCE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." 2>/dev/null && pwd -P) || exit "$GENERAL_ERROR"
MANIFEST="$SOURCE_ROOT/manifest/harness.yaml"
TARGET=$(pwd -P)
ADAPTERS_FILE=""
TMP_DIR=""
HASH_TOOL=""

cleanup() {
  [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
  [ -n "$ADAPTERS_FILE" ] && [ -f "$ADAPTERS_FILE" ] && rm -f "$ADAPTERS_FILE"
}
trap cleanup EXIT HUP INT TERM

error() { printf 'error: %s\n' "$*" >&2; }

usage() {
  printf '%s\n' 'Usage: install.sh [--target PATH] [--adapter NAME...]'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { error "--target requires a path"; exit "$GENERAL_ERROR"; }
      TARGET=$2
      shift 2
      ;;
    --adapter)
      shift
      if [ -z "$ADAPTERS_FILE" ]; then
        ADAPTERS_FILE="${TMPDIR:-/tmp}/ai-codeops-adapters.$$.tmp"
        : > "$ADAPTERS_FILE" || { error "cannot create temporary adapter list"; exit "$GENERAL_ERROR"; }
      fi
      adapter_count=0
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -*) break ;;
        esac
        printf '%s\n' "$1" >> "$ADAPTERS_FILE"
        adapter_count=$((adapter_count + 1))
        shift
      done
      [ "$adapter_count" -gt 0 ] || { error "--adapter requires at least one name"; exit "$GENERAL_ERROR"; }
      ;;
    --help|-h)
      usage
      exit "$SUCCESS"
      ;;
    *)
      error "unknown option: $1"
      usage >&2
      exit "$GENERAL_ERROR"
      ;;
  esac
done

[ -f "$MANIFEST" ] || { error "manifest not found"; exit "$INVALID_MANIFEST"; }
[ -d "$TARGET" ] || { error "target is not a directory: $TARGET"; exit "$INVALID_TARGET"; }
TARGET=$(CDPATH= cd -- "$TARGET" 2>/dev/null && pwd -P) || exit "$INVALID_TARGET"

if [ "$TARGET" = "$SOURCE_ROOT" ]; then
  error "refusing to install into the Harness source repository"
  exit "$INVALID_TARGET"
fi

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ai-codeops-install.XXXXXX") || {
  error "cannot create temporary directory"
  exit "$GENERAL_ERROR"
}

top_field() {
  awk -v field="$1" '$1 == field ":" && $0 !~ /^[[:space:]]/ { print $2; exit }' "$MANIFEST"
}

version_field() {
  awk -v field="$1" '$1 == field ":" { print $2; exit }' "$VERSION_FILE"
}

runtime_field() {
  awk -v field="$1" '
    $0 == "runtime:" { active=1; next }
    active && /^  [^ ]/ { if ($1 == field ":") { print $2; exit } }
  ' "$MANIFEST"
}

bootstrap_field() {
  awk -v field="$1" '
    $0 == "bootstrap:" { active=1; next }
    active && /^[^ ]/ { exit }
    active && $1 == field ":" { print $2; exit }
  ' "$MANIFEST"
}

manifest_name=$(top_field name)
manifest_version=$(top_field version)
manifest_source_root=$(runtime_field source_root)
manifest_target_root=$(runtime_field target_root)
bootstrap_source=$(bootstrap_field source)
bootstrap_target=$(bootstrap_field target)
bootstrap_owner=$(bootstrap_field owner)
bootstrap_update_policy=$(bootstrap_field update_policy)
bootstrap_conflict_policy=$(bootstrap_field conflict_policy)

[ -n "$manifest_name" ] && [ -n "$manifest_version" ] || {
  error "manifest name or version is missing"
  exit "$INVALID_MANIFEST"
}
[ -n "$manifest_source_root" ] && [ -n "$manifest_target_root" ] || {
  error "manifest runtime roots are missing"
  exit "$INVALID_MANIFEST"
}
[ -n "$bootstrap_source" ] && [ -n "$bootstrap_target" ] || {
  error "manifest bootstrap source or target is missing"
  exit "$INVALID_MANIFEST"
}
[ "$bootstrap_owner" = "harness" ] &&
  [ "$bootstrap_update_policy" = "managed" ] &&
  [ "$bootstrap_conflict_policy" = "abort_on_user_change" ] || {
    error "manifest bootstrap policy is invalid"
    exit "$INVALID_MANIFEST"
  }
case "$bootstrap_source" in
  /*|..|../*|*/../*)
    error "invalid bootstrap source path: $bootstrap_source"
    exit "$INVALID_MANIFEST"
    ;;
esac
case "$bootstrap_target" in
  /*|..|../*|*/../*)
    error "invalid bootstrap target path: $bootstrap_target"
    exit "$INVALID_MANIFEST"
    ;;
esac
[ -f "$SOURCE_ROOT/$bootstrap_source" ] || {
  error "bootstrap source not found: $bootstrap_source"
  exit "$INVALID_MANIFEST"
}

awk '
  /^[[:space:]]*-[[:space:]]+source:/ { source=$3; waiting=1; next }
  waiting && /^[[:space:]]+target:/ { print source "\t" $2; waiting=0 }
' "$MANIFEST" > "$TMP_DIR/mappings"

[ -s "$TMP_DIR/mappings" ] || {
  error "manifest contains no runtime mappings"
  exit "$INVALID_MANIFEST"
}

while IFS="$(printf '\t')" read -r source target; do
  case "$source" in
    "$manifest_source_root"|"$manifest_source_root"/*) ;;
    *)
      error "mapping source is outside manifest source_root: $source"
      exit "$INVALID_MANIFEST"
      ;;
  esac
  case "$source:$target" in
    /*:*|*:/../*|*:/..|../*:*)
      error "invalid relative mapping path: $source -> $target"
      exit "$INVALID_MANIFEST"
      ;;
  esac
  [ -d "$SOURCE_ROOT/$source" ] || {
    error "mapped source directory not found: $source"
    exit "$INVALID_MANIFEST"
  }
  case "$target" in
    /*|..|../*|*/../*)
      error "invalid target mapping path: $target"
      exit "$INVALID_MANIFEST"
      ;;
  esac
done < "$TMP_DIR/mappings"

if command -v shasum >/dev/null 2>&1; then
  HASH_TOOL=shasum
elif command -v sha256sum >/dev/null 2>&1; then
  HASH_TOOL=sha256sum
else
  error "no SHA-256 tool found; expected shasum or sha256sum"
  exit "$GENERAL_ERROR"
fi

hash_file() {
  if [ "$HASH_TOOL" = "shasum" ]; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

adapter_field() {
  awk -v adapter="$1" -v field="$2" '
    $0 == "  " adapter ":" { active=1; next }
    active && /^  [^ ]/ { exit }
    active && $1 == field ":" { print $2; exit }
  ' "$MANIFEST"
}

if [ -n "$ADAPTERS_FILE" ]; then
  sort -u "$ADAPTERS_FILE" > "$TMP_DIR/adapters"
else
  : > "$TMP_DIR/adapters"
fi

while IFS= read -r adapter; do
  [ -n "$adapter" ] || continue
  status=$(adapter_field "$adapter" status)
  source=$(adapter_field "$adapter" source)
  target=$(adapter_field "$adapter" target)

  [ "$status" = "stable" ] || {
    error "unsupported Adapter: $adapter"
    exit "$UNSUPPORTED_ADAPTER"
  }
  if { [ -n "$source" ] && [ -z "$target" ]; } || { [ -z "$source" ] && [ -n "$target" ]; }; then
    error "stable Adapter entry point is incomplete in Manifest: $adapter"
    exit "$INVALID_MANIFEST"
  fi
  [ -n "$source" ] || continue
  case "$source:$target" in
    /*:*|*:/../*|*:/..|../*:*)
      error "invalid Adapter path: $adapter"
      exit "$INVALID_MANIFEST"
      ;;
  esac
  [ -f "$SOURCE_ROOT/$source" ] || {
    error "Adapter source not found: $source"
    exit "$INVALID_MANIFEST"
  }
  case "$target" in
    /*|..|../*|*/../*)
      error "invalid Adapter target: $target"
      exit "$INVALID_MANIFEST"
      ;;
  esac
  printf '%s\t%s\n' "$source" "$target" >> "$TMP_DIR/adapter-mappings"
done < "$TMP_DIR/adapters"

managed_hash() {
  [ -f "$1" ] || return 1
  awk -v path="$2" '$1 == "-" && $2 == "path:" && $3 == path { getline; if ($1 == "sha256:") print $2; exit }' "$1"
}

VERSION_FILE="$TARGET/$manifest_target_root/VERSION"
OLD_VERSION_OK=0
if [ -f "$VERSION_FILE" ]; then
  old_name=$(version_field name)
  old_version=$(version_field version)
  if [ "$old_name" = "$manifest_name" ] && [ "$old_version" = "$manifest_version" ]; then
    OLD_VERSION_OK=1
  else
    error "conflict: existing unknown VERSION file"
    exit "$CONFLICT_ABORTED"
  fi
fi

add_tree() {
  source_dir=$1
  target_dir=$2
  find "$source_dir" -type f -print > "$TMP_DIR/find-files"
  while IFS= read -r source_file; do
    relative=${source_file#"$source_dir"/}
    printf '%s\t%s\n' "$source_file" "$target_dir/$relative" >> "$TMP_DIR/managed-files"
  done < "$TMP_DIR/find-files"
}

: > "$TMP_DIR/managed-files"
printf '%s\t%s\n' "$SOURCE_ROOT/$bootstrap_source" "$bootstrap_target" >> "$TMP_DIR/managed-files"
while IFS="$(printf '\t')" read -r source target; do
  add_tree "$SOURCE_ROOT/$source" "$target"
done < "$TMP_DIR/mappings"

if [ -f "$TMP_DIR/adapter-mappings" ]; then
  while IFS="$(printf '\t')" read -r source target; do
    printf '%s\t%s\n' "$SOURCE_ROOT/$source" "$target" >> "$TMP_DIR/managed-files"
  done < "$TMP_DIR/adapter-mappings"
fi

while IFS="$(printf '\t')" read -r source_file relative_target; do
  destination="$TARGET/$relative_target"
  if [ -e "$destination" ]; then
    recorded_hash=""
    [ "$OLD_VERSION_OK" -eq 1 ] && recorded_hash=$(managed_hash "$VERSION_FILE" "$relative_target")
    if [ -z "$recorded_hash" ] || [ "$(hash_file "$destination")" != "$recorded_hash" ]; then
      error "conflict: existing user-owned or modified file: $relative_target"
      exit "$CONFLICT_ABORTED"
    fi
  fi
done < "$TMP_DIR/managed-files"

mkdir -p "$TARGET/$manifest_target_root" || {
  error "cannot create runtime directory"
  exit "$GENERAL_ERROR"
}

for state_relative in state/approvals state/checkpoints/tasks; do
  state_directory="$TARGET/$manifest_target_root/$state_relative"
  if [ -e "$state_directory" ] && [ ! -d "$state_directory" ]; then
    error "runtime state target is a file: $state_relative"
    exit "$INVALID_TARGET"
  fi
  mkdir -p "$state_directory" || {
    error "cannot initialize runtime state directory: $state_relative"
    exit "$PARTIAL_FAILURE"
  }
done

while IFS="$(printf '\t')" read -r source_file relative_target; do
  destination="$TARGET/$relative_target"
  mkdir -p "$(dirname "$destination")" || { error "cannot create target directory"; exit "$PARTIAL_FAILURE"; }
  cp "$source_file" "$destination" || { error "cannot copy: $relative_target"; exit "$PARTIAL_FAILURE"; }
done < "$TMP_DIR/managed-files"

{
  printf 'name: %s\n' "$manifest_name"
  printf 'version: %s\n' "$manifest_version"
  printf '\ninstalled_adapters:\n'
  while IFS= read -r adapter; do
    [ -n "$adapter" ] && printf '  - %s\n' "$adapter"
  done < "$TMP_DIR/adapters"
  printf '\nmanaged_files:\n'
  sort -t "$(printf '\t')" -k2,2 "$TMP_DIR/managed-files" | while IFS="$(printf '\t')" read -r source_file relative_target; do
    printf '  - path: %s\n' "$relative_target"
    printf '    sha256: %s\n' "$(hash_file "$TARGET/$relative_target")"
  done
} > "$TMP_DIR/VERSION"

mv "$TMP_DIR/VERSION" "$VERSION_FILE" || {
  error "cannot write $VERSION_FILE"
  exit "$PARTIAL_FAILURE"
}

printf 'Installed %s %s into %s\n' "$manifest_name" "$manifest_version" "$TARGET"
exit "$SUCCESS"

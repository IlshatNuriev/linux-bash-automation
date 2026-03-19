#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="${PROJECT_NAME:-devops-app}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
LOG_DIR="${LOG_DIR:-./logs}"
LOCK_DIR="${LOCK_DIR:-/tmp/${PROJECT_NAME}-locks}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

DB_CONTAINER="${DB_CONTAINER:-postgres_db}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"

APP_HEALTH_URL="${APP_HEALTH_URL:-http://localhost:8080/health}"

SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$0")}"
LOCK_FILE=""
TMP_FILES=()

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  printf "[%s] [INFO] [%s] %s\n" "$(timestamp)" "$SCRIPT_NAME" "$*"
}

warn() {
  printf "[%s] [WARN] [%s] %s\n" "$(timestamp)" "$SCRIPT_NAME" "$*" >&2
}

err() {
  printf "[%s] [ERROR] [%s] %s\n" "$(timestamp)" "$SCRIPT_NAME" "$*" >&2
}

die() {
  err "$*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_file() {
  [[ -f "$1" ]] || die "Required file not found: $1"
}

ensure_dirs() {
  mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$LOCK_DIR"
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -Fxq "$1"
}

add_tmp_file() {
  TMP_FILES+=("$1")
}

cleanup_tmp_files() {
  local f
  for f in "${TMP_FILES[@]:-}"; do
    [[ -n "${f:-}" && -e "$f" ]] && rm -f "$f" || true
  done
}

acquire_lock() {
  local lock_name="${1:?lock_name is required}"
  ensure_dirs
  LOCK_FILE="${LOCK_DIR}/${lock_name}.lock"

  if [[ -e "$LOCK_FILE" ]]; then
    local existing_pid
    existing_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
      die "Lock already acquired by PID $existing_pid: $LOCK_FILE"
    fi
    warn "Stale lock found, removing: $LOCK_FILE"
    rm -f "$LOCK_FILE"
  fi

  echo "$$" > "$LOCK_FILE"
  log "Lock acquired: $LOCK_FILE"
}

release_lock() {
  if [[ -n "${LOCK_FILE:-}" && -e "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE" || true
    log "Lock released: $LOCK_FILE"
  fi
}

on_error() {
  local exit_code=$?
  local line_no="${1:-unknown}"
  err "Command failed at line ${line_no} with exit code ${exit_code}"
  cleanup_tmp_files
  release_lock
  exit "$exit_code"
}

on_exit() {
  local exit_code=$?
  cleanup_tmp_files
  release_lock
  exit "$exit_code"
}

setup_traps() {
  trap 'on_error $LINENO' ERR
  trap 'on_exit' EXIT INT TERM
}
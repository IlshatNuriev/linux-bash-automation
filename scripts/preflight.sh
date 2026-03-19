#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "preflight"

log "Running preflight checks"

require_command docker
require_command curl
require_command awk
require_command grep
require_command find

require_file "$COMPOSE_FILE"

if ! docker info >/dev/null 2>&1; then
  die "Docker daemon is not available"
fi

if ! docker compose version >/dev/null 2>&1; then
  die "Docker Compose plugin is not available"
fi

ensure_dirs

[[ -w "$BACKUP_DIR" ]] || die "Backup directory is not writable: $BACKUP_DIR"
[[ -w "$LOG_DIR" ]] || die "Log directory is not writable: $LOG_DIR"
[[ -w "$LOCK_DIR" ]] || die "Lock directory is not writable: $LOCK_DIR"

log "Validating docker compose configuration"
compose config >/dev/null

log "Preflight checks passed"
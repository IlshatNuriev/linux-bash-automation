#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "rotate_backups"

RETENTION_DAYS="${RETENTION_DAYS:-7}"
DRY_RUN="${DRY_RUN:-false}"

ensure_dirs

log "Rotating backups older than ${RETENTION_DAYS} days in $BACKUP_DIR"

mapfile -t old_files < <(
  find "$BACKUP_DIR" -type f \( -name "*.sql" -o -name "*.sql.gz" -o -name "*.sha256" \) -mtime +"$RETENTION_DAYS"
)

if [[ "${#old_files[@]}" -eq 0 ]]; then
  log "No old backup files found"
  exit 0
fi

printf '%s\n' "${old_files[@]}"

if [[ "$DRY_RUN" == "true" ]]; then
  log "Dry-run mode enabled, no files deleted"
  exit 0
fi

printf '%s\0' "${old_files[@]}" | xargs -0 rm -f

log "Backup rotation completed"
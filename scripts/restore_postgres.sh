#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "restore_postgres"

[[ $# -eq 1 ]] || die "Usage: $0 <backup.sql.gz|backup.sql>"

backup_input="$1"
require_file "$backup_input"

"$SCRIPT_DIR/preflight.sh"
container_running "$DB_CONTAINER" || die "Database container is not running: $DB_CONTAINER"

if [[ -f "${backup_input}.sha256" ]]; then
  require_command sha256sum
  log "Verifying checksum"
  sha256sum -c "${backup_input}.sha256"
fi

log "Restoring PostgreSQL backup: $backup_input"

if [[ "$backup_input" == *.gz ]]; then
  require_command gunzip
  gunzip -c "$backup_input" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME"
else
  docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$backup_input"
fi

log "Restore completed successfully"
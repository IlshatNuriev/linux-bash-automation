#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "backup_postgres"

"$SCRIPT_DIR/preflight.sh"

container_running "$DB_CONTAINER" || die "Database container is not running: $DB_CONTAINER"

require_command gzip
require_command sha256sum

ensure_dirs

backup_ts="$(date +%Y-%m-%d_%H-%M-%S)"
tmp_backup="$(mktemp "${BACKUP_DIR}/${DB_NAME}_${backup_ts}.XXXXXX.sql")"
add_tmp_file "$tmp_backup"

archive_file="${BACKUP_DIR}/${DB_NAME}_${backup_ts}.sql.gz"
checksum_file="${archive_file}.sha256"

log "Starting PostgreSQL backup from container: $DB_CONTAINER"
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$tmp_backup"

[[ -s "$tmp_backup" ]] || die "Backup file is empty: $tmp_backup"

log "Compressing backup"
gzip -c "$tmp_backup" > "$archive_file"

[[ -s "$archive_file" ]] || die "Archive file is empty: $archive_file"

log "Generating checksum"
sha256sum "$archive_file" > "$checksum_file"

log "Backup completed successfully"
log "Archive: $archive_file"
log "Checksum: $checksum_file"
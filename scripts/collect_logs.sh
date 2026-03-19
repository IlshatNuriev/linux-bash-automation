#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "collect_logs"

ensure_dirs

ts="$(date +%Y-%m-%d_%H-%M-%S)"
compose_log="${LOG_DIR}/docker_compose_${ts}.log"
ps_log="${LOG_DIR}/docker_ps_${ts}.log"

log "Collecting docker compose logs: $compose_log"
compose logs --no-color > "$compose_log" 2>&1 || true

log "Collecting docker ps output: $ps_log"
docker ps -a > "$ps_log" 2>&1 || true

log "Logs collected successfully"
log "Compose logs: $compose_log"
log "Container list: $ps_log"
#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "healthcheck"

TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-60}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3}"

log "Checking application health: $APP_HEALTH_URL"

deadline=$((SECONDS + TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  if response="$(curl -fsS "$APP_HEALTH_URL" 2>/dev/null)"; then
    log "Healthcheck passed: $response"
    exit 0
  fi
  warn "Application is not ready yet, retrying in ${SLEEP_SECONDS}s"
  sleep "$SLEEP_SECONDS"
done

die "Healthcheck failed after ${TIMEOUT_SECONDS}s"
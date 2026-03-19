#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
source "$SCRIPT_DIR/lib.sh"

setup_traps
acquire_lock "deploy"

BUILD="${BUILD:-true}"
PULL="${PULL:-false}"

"$SCRIPT_DIR/preflight.sh"

log "Starting deployment"

if [[ "$PULL" == "true" ]]; then
  log "Pulling latest images"
  compose pull
fi

if [[ "$BUILD" == "true" ]]; then
  log "Building services"
  compose build
fi

log "Starting services"
compose up -d

log "Waiting for service health"
if ! TIMEOUT_SECONDS=90 "$SCRIPT_DIR/healthcheck.sh"; then
  err "Deployment failed during healthcheck"
  "$SCRIPT_DIR/collect_logs.sh" || true
  exit 1
fi

log "Deployment completed successfully"
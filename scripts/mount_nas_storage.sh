#!/usr/bin/env bash
# mount_nas_storage.sh
set -euo pipefail

SCRIPTS_DIR="${HOME}/scripts"
LOG_PREFIX="[mount_nas_storage]"

NAS1_SCRIPT="${SCRIPTS_DIR}/mount_nas1_thdata.sh"
NAS2_SCRIPT="${SCRIPTS_DIR}/mount_nas2.sh"

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

log() {
  echo "$(timestamp) ${LOG_PREFIX} $*"
}

run_script_if_exists() {
  local script_path="$1"
  if [ -x "$script_path" ]; then
    log "Running $script_path"
    if "$script_path"; then
      log "Completed $script_path successfully"
    else
      log "ERROR: $script_path failed"
      return 1
    fi
  else
    log "Skipping $script_path (not found or not executable)"
  fi
}

log "Starting NAS mount sequence"

run_script_if_exists "$NAS1_SCRIPT" || {
  log "Warning: NAS1 mount step failed; continuing to NAS2"
}

run_script_if_exists "$NAS2_SCRIPT" || {
  log "Warning: NAS2 mount step failed"
}

log "NAS mount sequence finished"

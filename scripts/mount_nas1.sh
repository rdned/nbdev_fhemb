#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/mount.sh" ]; then
  echo "mount.sh not found in ${SCRIPT_DIR}"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/config_env.sh" ]; then
  echo "config_env.sh not found in ${SCRIPT_DIR}"
  exit 1
fi

. "${SCRIPT_DIR}/mount.sh"
. "${SCRIPT_DIR}/config_env.sh"

CONFIG_ROOT="$(detect_config_root)"

CONFIG_PATHS="${CONFIG_ROOT}/fhemb/.env.paths"

if [ ! -f "$CONFIG_PATHS" ]; then
  echo "Configuration file not found: $CONFIG_PATHS"
  exit 1
fi

# Variables
MOUNT_POINT="$(normalize_path "$(load_env_value "$CONFIG_PATHS" "MOUNT")")"
REMOTE_PATH=nas1:/NASstorage/radned

if [ -z "$MOUNT_POINT" ]; then
  echo "Could not load MOUNT from $CONFIG_PATHS"
  exit 1
fi

echo "MOUNT is set to: $MOUNT_POINT"
echo "REMOTE_PATH is set to: $REMOTE_PATH"

# Main script
if check_mount_point $MOUNT_POINT; then
  mount_nas $MOUNT_POINT $REMOTE_PATH
else
  unmount_nas $MOUNT_POINT
  sleep 2  # Wait for 2 seconds to ensure unmount operation has completed
  mount_nas $MOUNT_POINT $REMOTE_PATH
fi

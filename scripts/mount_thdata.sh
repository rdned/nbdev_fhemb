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
CONFIG_DB="${CONFIG_ROOT}/fhemb/.env.db"

if [ ! -f "$CONFIG_PATHS" ]; then
  echo "Configuration file not found: $CONFIG_PATHS"
  exit 1
fi

if [ ! -f "$CONFIG_DB" ]; then
  echo "Configuration file not found: $CONFIG_DB"
  exit 1
fi

# Variables
MOUNT_POINT="$(normalize_path "$(load_env_value "$CONFIG_PATHS" "AUDIOFILES")")"
SSH_USERNAME="$(load_env_value "$CONFIG_DB" "SSH_USERNAME")"
REMOTE_HOST="$(load_env_value "$CONFIG_DB" "REMOTE_HOST")"
REMOTE_PATH="${SSH_USERNAME}@${REMOTE_HOST}:/NASstorage/ricardoc/thermal_data"

echo "REMOTE_PATH is set to: $REMOTE_PATH"

if [ -z "$MOUNT_POINT" ]; then
  echo "Could not load AUDIOFILES from $CONFIG_PATHS"
  exit 1
fi

if [ -z "$SSH_USERNAME" ] || [ -z "$REMOTE_HOST" ]; then
  echo "Could not load SSH_USERNAME/REMOTE_HOST from $CONFIG_DB"
  exit 1
fi

# Main script
if check_mount_point $MOUNT_POINT; then
  mount_nas $MOUNT_POINT $REMOTE_PATH
else
  unmount_nas $MOUNT_POINT
  sleep 2  # Wait for 2 seconds to ensure unmount operation has completed
  mount_nas $MOUNT_POINT $REMOTE_PATH
fi

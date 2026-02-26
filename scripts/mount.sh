#!/bin/bash

# Function to run a bind script on a NAS
bind_on_NAS(){
  local NAS_USER=$1
  local NAS_HOST=$2
  local NAS_SCRIPT_PATH=$3

  echo "Running the bind script on the NAS..."
  ssh $NAS_USER@$NAS_HOST "echo 'neurolab' | sudo -S bash $NAS_SCRIPT_PATH"
  if [ $? -eq 0 ]; then
    echo "Bind script executed successfully on the NAS."
    return 0
  elif [ $? -eq 255 ]; then
    echo "Failed to connect to the NAS. Please check the network connection or the NAS host."
    return 1
  else
    echo "Failed to execute the bind script on the NAS. Please check the script or connection."
    return 1
  fi
}

# Function to check if mount point is available
check_mount_point() {
  local MOUNT_POINT=$1
  if diskutil list | grep -q "$MOUNT_POINT"; then
    echo "Mount point $MOUNT_POINT is available."
    return 0
  elif mount | grep -q "$MOUNT_POINT" && ls "$MOUNT_POINT" > /dev/null 2>&1; then
    echo "Already mounted correctly at $MOUNT_POINT"
    exit 0
  else
    echo "Mount point $MOUNT_POINT is not available or not configured."
    return 1
  fi
}

# Function to unmount the NAS
unmount_nas() {
  local MOUNT_POINT=$1
  if mount | grep $MOUNT_POINT > /dev/null; then
    echo "Already mounted at $MOUNT_POINT, but not correctly"
    echo "Unmounting it"
    if ! sudo umount $MOUNT_POINT 2>/dev/null; then
      echo "Unmount failed. Trying to unmount with -f option, but this may cause DATA CORRUPTION!"
      read -p "Are you sure you want to continue? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo umount -f $MOUNT_POINT 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Unmounted successfully"
          return 0
        else
          echo "Unmount failed"
          exit 1
        fi
      else
        echo "Unmount operation cancelled."
        exit 1
      fi
    else
      echo "Unmounted successfully"
      return 0
    fi
  else
    echo "Not mounted or mounted correctly?"
    read -p "Do you want to quit? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "I'm giving up!"
      exit 1
    else
      echo "I will try something else!"
      return 1
    fi
  fi
}

# Function to mount the NAS
mount_nas() {
  local MOUNT_POINT=$1
  local REMOTE_PATH=$2
  echo "Mounting the NAS on macOS..."
  if sshfs -o uid=501,gid=20,umask=077 $REMOTE_PATH $MOUNT_POINT; then
    echo "Mounted successfully at $MOUNT_POINT"
    return 0
  else
    echo "Failed to mount at $MOUNT_POINT. Please check the connection or configuration."
    exit 1
  fi
}

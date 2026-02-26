#!/bin/bash

detect_config_root() {
  if [ -n "${WSL_DISTRO_NAME-}" ]; then
    echo "${XDG_CONFIG_HOME:-$HOME/.config}"
    return
  fi

  case "$(uname -s 2>/dev/null)" in
    CYGWIN*|MINGW*|MSYS*) echo "${APPDATA:-${XDG_CONFIG_HOME:-$HOME/.config}}" ;;
    *) echo "${XDG_CONFIG_HOME:-$HOME/.config}" ;;
  esac
}

load_env_value() {
  local file_path="$1"
  local key="$2"

  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*['\"]?([^'\"#]+)['\"]?[[:space:]]*(#.*)?$/\1/p" "$file_path" | head -n 1
}

normalize_path() {
  local value="$1"
  echo "$value" | sed 's:[[:space:]]*$::; s:/*$::'
}

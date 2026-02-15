#!/bin/bash
set -eE -ex

export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/install-fhemb.sh
source /usr/local/bin/configure-ssh.sh
source /usr/local/bin/setup-env.sh

nbdev-prepare
nbdev-test --flags ""

if [ -n "$(git status --porcelain -uno)" ]; then
  echo "::error::Notebooks and library are not in sync."
  exit 1
fi

echo "=== SYNC OK ==="

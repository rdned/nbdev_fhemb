#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

echo "=== QUARTO VERSION ===" >&2
quarto --version 2>&1 || echo "Quarto not found" >&2

source /usr/local/bin/ci-prepare.sh test

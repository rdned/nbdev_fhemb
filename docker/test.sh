#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/ci-prepare.sh test

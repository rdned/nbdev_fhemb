#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill "$SSH_PID" 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/ci-prepare.sh test

echo "=== BUILD DOCS ===" >&2
nbdev-docs

echo "=== LOCATE SITE ===" >&2
if [ -f "_docs/index.html" ]; then SITE_DIR="_docs"
elif [ -f "_proc/_docs/index.html" ]; then SITE_DIR="_proc/_docs"
else echo "ERROR: No rendered site found"; exit 1; fi

echo "SITE_DIR detected at ${SITE_DIR}" >&2

# Copy docs to mounted artifact directory for GitHub Actions
mkdir -p /artifacts/docs
cp -a "${SITE_DIR}/." /artifacts/docs/

echo "=== DOCS READY FOR DEPLOYMENT ===" >&2

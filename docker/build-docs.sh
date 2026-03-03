#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/ci-prepare.sh build

echo "=== QUARTO VERSION ===" >&2
quarto --version 2>&1 || echo "Quarto not found" >&2

echo "=== BUILD DOCS ===" >&2
nbdev-docs

echo "=== LOCATE SITE ===" >&2
if [ -f "_docs/index.html" ]; then SITE_DIR="_docs"
elif [ -f "_proc/_docs/index.html" ]; then SITE_DIR="_proc/_docs"
else echo "ERROR: No rendered site found"; exit 1; fi

echo "SITE_DIR detected at ${SITE_DIR}" >&2

DOCS_OUT_DIR="${DOCS_OUT_DIR:-/ci_artifacts/site-docs}"
mkdir -p "$DOCS_OUT_DIR"
cp -a "${SITE_DIR}/." "$DOCS_OUT_DIR/"

echo "=== DOCS EXPORTED TO ${DOCS_OUT_DIR} ===" >&2

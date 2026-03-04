#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill "$SSH_PID" 2>/dev/null || true; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/ci-prepare.sh build

echo "=== NBDEV TEST ===" >&2
PYTHONWARNINGS="ignore:resource_tracker:UserWarning:joblib.externals.loky.backend.resource_tracker" \
  nbdev-test --flags ""

echo "=== CHECK SYNC ===" >&2
if [ -n "$(git status --porcelain -uno)" ]; then
    echo "=== DIFF START ===" >&2
    git --no-pager diff --color=always >&2
    echo "=== DIFF END ===" >&2
    echo "::error::Notebooks and library are not in sync."
    exit 1
fi

echo "=== SYNC OK ===" >&2

echo "=== QUARTO VERSION ===" >&2
quarto --version 2>&1 || echo "Quarto not found" >&2

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

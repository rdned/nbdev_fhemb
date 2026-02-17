#!/bin/bash
set -eE -ex
export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/ci-prepare.sh build

echo "=== QUARTO VERSION ===" >&2
quarto --version 2>&1 || echo "Quarto not found" >&2

nbdev-docs

echo "=== DEPLOY TO GH-PAGES ===" >&2
git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
git remote set-url origin https://x-access-token:${GH_PAGES_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

if [ -f "_docs/index.html" ]; then SITE_DIR="_docs"
elif [ -f "_proc/_docs/index.html" ]; then SITE_DIR="_proc/_docs"
else echo "ERROR: No rendered site found"; exit 1; fi

echo "SITE_DIR detected at ${SITE_DIR}"

git checkout --orphan gh-pages
git rm -rf .
cp -a "${SITE_DIR}/." .
touch .nojekyll
git add .
git commit -m "docs: auto-generated documentation" || true
git push origin gh-pages -f

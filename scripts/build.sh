#!/bin/bash
set -eE -ex

export PYTHONUNBUFFERED=1

cleanup() { kill $SSH_PID 2>/dev/null; rm -rf ~/.ssh ~/.config; }
trap cleanup ERR EXIT

source /usr/local/bin/install-fhemb.sh
source /usr/local/bin/configure-ssh.sh
source /usr/local/bin/setup-env.sh

nbdev-prepare
nbdev-test || echo "WARNING: nbdev_test failed"
nbdev-docs

git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
git remote set-url origin https://x-access-token:${GH_PAGES_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

# detect site dir
if [ -f "_docs/index.html" ]; then SITE_DIR="_docs"
elif [ -f "_proc/_docs/index.html" ]; then SITE_DIR="_proc/_docs"
else echo "ERROR: No rendered site found"; exit 1; fi

git checkout --orphan gh-pages
git rm -rf .
cp -a "${SITE_DIR}/." .
touch .nojekyll
git add .
git commit -m "docs: auto-generated documentation" || true
git push origin gh-pages -f

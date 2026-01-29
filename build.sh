#!/bin/bash
set -e

echo "=== INSTALL FHEMB ==="
pip install --no-cache-dir --force-reinstall \
  "fhemb @ git+https://${FHEMB_CI}@github.com/rdned/fhemb#egg=fhemb"

echo "=== CONFIGURE SSH ==="
mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${FHEMB_SSH_HOST} 2>/dev/null >> ~/.ssh/known_hosts

echo "=== CONFIGURE FHEMB ==="
mkdir -p ~/.config/fhemb
echo "$FHEMB_ENV_DB" > ~/.config/fhemb/.env.db
echo "$FHEMB_ENV_PATHS" > ~/.config/fhemb/.env.paths

echo "=== SSH TUNNEL ==="
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
  -L 6543:localhost:5432 \
  ${FHEMB_SSH_USER}@${FHEMB_SSH_HOST} \
  -N &
SSH_PID=$!
sleep 2

for i in {1..30}; do
  nc -z localhost 6543 && break
  sleep 0.5
done

echo "=== NBDEV TEST ==="
nbdev_test

echo "=== NBDEV DOCS ==="
nbdev_docs

echo "=== DEPLOY TO GH-PAGES ==="
git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
git config --global --add safe.directory /workspace
git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

git checkout --orphan gh-pages
git rm -rf .
cp -r _docs/* .
rm -rf _docs
git add .
git commit -m "docs: update documentation" || true
git push origin gh-pages -f

echo "=== CLEANUP ==="
kill $SSH_PID || true
rm -rf ~/.ssh ~/.config


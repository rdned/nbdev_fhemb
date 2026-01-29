#!/bin/bash
set -e

echo "=== CHECKOUT ==="
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

echo "=== INSTALL FHEMB ==="
pip install --no-cache-dir --force-reinstall \
  "fhemb @ git+https://${FHEMB_CI}@github.com/rdned/fhemb#egg=fhemb"

echo "=== CONFIGURE SSH ==="
mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

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

echo "=== NBDEV TEST ==="
nbdev_test

echo "=== NBDEV DOCS ==="
nbdev_docs

echo "=== DEPLOY ==="
cd _docs
git init
git checkout -b gh-pages
git add .
git commit -m "update docs"
git remote add origin https://github.com/${GITHUB_REPOSITORY}.git
git push -f origin gh-pages

kill $SSH_PID || true


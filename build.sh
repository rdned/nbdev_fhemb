#!/bin/bash
set -ex
set -eE

echo "=== RUNNING BUILD.SH ===" >&2
echo "Script: $0" >&2

export PYTHONUNBUFFERED=1

cleanup() {
  echo "=== CLEANUP ===" >&2
  kill $SSH_PID 2>/dev/null || true
  rm -rf ~/.ssh ~/.config
}
trap cleanup ERR EXIT

echo "=== CLONE REPOSITORY ===" >&2
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

echo "=== INSTALL FHEMB ===" >&2
FHEMB_VERSION="0.1.0"
FHEMB_WHEEL="fhemb-${FHEMB_VERSION}-py3-none-any.whl"
FHEMB_URL="https://github.com/rdned/fhemb/releases/download/v${FHEMB_VERSION}/${FHEMB_WHEEL}"

curl -L \
  -H "Authorization: token ${FHEMB_CI_CLASSIC}" \
  -H "Accept: application/octet-stream" \
  -o /tmp/${FHEMB_WHEEL} \
  ${FHEMB_URL}

ls -lh /tmp/${FHEMB_WHEEL}

python3 -m pip install --no-cache-dir --force-reinstall /tmp/${FHEMB_WHEEL} >&2
python3 -m pip install -U kaleido

echo "=== VERIFY KALEIDO INSTALLATION ===" >&2
python3 - <<'EOF'
import sys
print("Python:", sys.executable)
try:
    import kaleido
    print("Kaleido OK:", kaleido.__file__)
except Exception as e:
    print("Kaleido import FAILED:", e)
EOF

echo "=== CONFIGURE SSH ===" >&2
mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${FHEMB_SSH_HOST} 2>/dev/null >> ~/.ssh/known_hosts

echo "=== CONFIGURE FHEMB ===" >&2
mkdir -p ~/.config/fhemb
echo "$FHEMB_ENV_DB" > ~/.config/fhemb/.env.db
echo "$FHEMB_ENV_PATHS" > ~/.config/fhemb/.env.paths

echo "=== SSH TUNNEL ===" >&2
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

echo "=== CLEAR CACHES ===" >&2
rm -rf .nbdev_cache .quarto

echo "=== FORCE PLOTLY TO PNG (CI ONLY) ===" >&2
python3 - <<'EOF'
import os, plotly.io as pio
pio.renderers.default = "png"
EOF

echo "=== NBDEV PREPARE ===" >&2
nbdev_prepare 2>&1

echo "=== NBDEV TEST ===" >&2
nbdev_test 2>&1 || echo "WARNING: nbdev_test failed" >&2

echo "=== NBDEV DOCS ===" >&2
nbdev_docs 2>&1

echo "=== DEPLOY TO GH-PAGES ===" >&2
git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
git config --global --add safe.directory $(pwd)
git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

git checkout --orphan gh-pages
git rm -rf .
cp -r _docs/* .
touch .nojekyll
rm -rf _docs
git add .
git commit -m "docs: auto-generated documentation" || true
git push origin gh-pages -f

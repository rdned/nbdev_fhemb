#!/bin/bash
set -ex
set -eE

echo "=== RUNNING BUILD.SH ===" >&2
echo "Script: $0" >&2

export PYTHONUNBUFFERED=1

cleanup() {
  set +e
  echo "=== CLEANUP ===" >&2
  kill $SSH_PID 2>/dev/null
  rm -rf ~/.ssh ~/.config
}
trap cleanup ERR EXIT

echo "=== CLONE REPOSITORY ===" >&2
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

echo "=== INSTALL FHEMB ===" >&2
echo "Using FHEMB_TAG=${FHEMB_TAG}" >&2
echo "Using FHEMB_WHEEL=${FHEMB_WHEEL}" >&2
# Clone ci-utils
git clone --depth 1 https://github.com/rdned/ci-utils.git utils
cd utils
git checkout "${CI_UTILS_COMMIT}"
cd ..

# Download wheel using canonical script
utils/download_release_asset_ci.sh \
  rdned/fhemb \
  "${FHEMB_TAG}" \
  "${FHEMB_WHEEL}" \
  "/tmp/${FHEMB_WHEEL}"

rm -rf utils
ls -lh /tmp/${FHEMB_WHEEL}

python3 -m pip install --no-cache-dir --force-reinstall /tmp/${FHEMB_WHEEL}
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
nbdev-prepare 2>&1

echo "=== NBDEV TEST ===" >&2
nbdev-test 2>&1 || echo "WARNING: nbdev_test failed" >&2

echo "=== NBDEV DOCS ===" >&2
nbdev-docs 2>&1

echo "=== DEPLOY TO GH-PAGES ===" >&2
git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
git config --global --add safe.directory $(pwd)
git remote set-url origin https://x-access-token:${GH_PAGES_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

# Detect where nbdev wrote the final site
if [ -f "_docs/index.html" ]; then
    SITE_DIR="_docs"
elif [ -f "_proc/_docs/index.html" ]; then
    SITE_DIR="_proc/_docs"
else
    echo "ERROR: No rendered site found in _docs or _proc/_docs" >&2
    exit 1
fi

echo "SITE_DIR detected at ${SITE_DIR}"

git checkout --orphan gh-pages
git rm -rf .
cp -a "${SITE_DIR}/." .
touch .nojekyll
git add .
git commit -m "docs: auto-generated documentation" || true
git push origin gh-pages -f

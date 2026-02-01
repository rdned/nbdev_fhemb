#!/bin/bash
set -ex

export PYTHONUNBUFFERED=1

cleanup() {
  echo "=== CLEANUP ===" >&2
  kill $SSH_PID 2>/dev/null || true
  rm -rf ~/.ssh ~/.config
}
trap cleanup EXIT

echo "=== CLONE REPOSITORY ===" >&2
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

echo "=== INSTALL FHEMB ===" >&2
pip install --no-cache-dir --force-reinstall \
  "fhemb @ git+https://${FHEMB_CI}@github.com/rdned/fhemb#egg=fhemb" >&2

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

echo "=== NBDEV CLEAN ===" >&2
nbdev_clean

echo "=== NBDEV EXPORT ===" >&2
nbdev_export

echo "=== NBDEV TEST ===" >&2
nbdev_test --flags ""

echo "=== CHECK GIT STATUS ===" >&2
git status

echo "=== ENFORCE SYNC ===" >&2
git config --global --add safe.directory $(pwd)
if [ -n "$(git status --porcelain -uno)" ]; then
  echo "::error::Notebooks and library are not in sync."
  git status -uno
  exit 1
fi


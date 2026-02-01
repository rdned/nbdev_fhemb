#!/bin/bash
set -euo pipefail
export PYTHONUNBUFFERED=1

cleanup() {
  kill $SSH_PID 2>/dev/null || true
  rm -rf ~/.ssh ~/.config
}
trap cleanup EXIT

echo "=== INSTALL FHEMB ===" >&2
pip install --no-cache-dir --force-reinstall \
  "fhemb @ git+https://${FHEMB_CI}@github.com/rdned/fhemb#egg=fhemb" >&2

echo "=== CONFIGURE SSH ===" >&2
mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

echo "=== START SSH TUNNEL ===" >&2
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
  -L 6543:localhost:5432 \
  ${FHEMB_SSH_USER}@${FHEMB_SSH_HOST} \
  -N &
SSH_PID=$!

for i in {1..30}; do
  nc -z localhost 6543 && break
  sleep 0.5
done

echo "=== CONFIGURE FHEMB ENV (CI MODE) ===" >&2
mkdir -p ~/.config/fhemb

cat <<EOF > ~/.config/fhemb/.env.db
DB_NAME=${FHEMB_DB_NAME}
DB_USERNAME=${FHEMB_DB_USER}
DB_PASSWORD=${FHEMB_DB_PASS}
DB_HOST=localhost
DB_PORT=6543
EOF

cat <<EOF > ~/.config/fhemb/.env.paths
NODENAME=${NODENAME}
LOCALROOT=${FHEMB_LOCALROOT}
MOUNT=${FHEMB_MOUNT}
AUDIOFILES=${FHEMB_AUDIOFILES}
EOF

chmod 600 ~/.config/fhemb/.env.*

echo "=== CLONE REPOSITORY ===" >&2
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

echo "=== NBDEV CLEAN ===" >&2
nbdev_clean

echo "=== NBDEV EXPORT ===" >&2
nbdev_export

echo "=== NBDEV TEST ===" >&2
nbdev_test --flags ""

echo "=== ENFORCE SYNC ===" >&2
git config --global --add safe.directory $(pwd)
if [ -n "$(git status --porcelain -uno)" ]; then
  echo "::error::Notebooks and library are not in sync."
  git status -uno
  exit 1
fi


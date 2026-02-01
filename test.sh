#!/bin/bash
set -euo pipefail
export PYTHONUNBUFFERED=1

cleanup() {
  kill $SSH_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "=== INSTALL FHEMB ==="
pip install --no-cache-dir --force-reinstall \
  "fhemb @ git+https://${FHEMB_CI}@github.com/rdned/fhemb#egg=fhemb"

echo "=== CONFIGURE SSH ==="
mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${FHEMB_SSH_HOST} >> ~/.ssh/known_hosts 2>/dev/null

echo "=== CONFIGURE FHEMB ENV ==="
mkdir -p ~/.config/fhemb

cat <<EOF > ~/.config/fhemb/.env.db
DB_NAME=${FHEMB_DB_NAME}
DB_USERNAME=${FHEMB_DB_USER}
DB_PASSWORD=${FHEMB_DB_PASS}
DB_HOST=${FHEMB_DB_HOST}
DB_PORT=${FHEMB_DB_PORT}

REMOTE_HOST=${FHEMB_SSH_HOST}
REMOTE_PORT=${FHEMB_REMOTE_PORT}
SSH_USERNAME=${FHEMB_SSH_USER}
SSH_PKEY=/root/.ssh/id_rsa
REMOTE_BIND_HOST=${FHEMB_DB_HOST}
REMOTE_BIND_PORT=${FHEMB_DB_PORT}
EOF

cat <<EOF > ~/.config/fhemb/.env.paths
NODENAME=${NODENAME}
LOCALROOT=${FHEMB_LOCALROOT}
MOUNT=${FHEMB_MOUNT}
AUDIOFILES=${FHEMB_AUDIOFILES}
EOF

chmod 600 ~/.config/fhemb/.env.*

echo "=== SSH TUNNEL ==="
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
  -L 6543:localhost:5432 \
  ${FHEMB_SSH_USER}@${FHEMB_SSH_HOST} \
  -N &
SSH_PID=$!

for i in {1..30}; do
  nc -z localhost 6543 && break
  sleep 0.5
done

# Force fhemb to use the CI tunnel
export FHEMB_DB_HOST=localhost
export FHEMB_DB_PORT=6543

echo "=== NBDEV CLEAN ==="
nbdev_clean

echo "=== NBDEV EXPORT ==="
nbdev_export

echo "=== NBDEV TEST ==="
nbdev_test --flags ""

echo "=== ENFORCE SYNC ==="
git config --global --add safe.directory $(pwd)
if [ -n "$(git status --porcelain -uno)" ]; then
  echo "::error::Notebooks and library are not in sync."
  git status -uno
  exit 1
fi


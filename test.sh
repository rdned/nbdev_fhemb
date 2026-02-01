#!/bin/bash
set -euo pipefail
export PYTHONUNBUFFIXED=1

cleanup() {
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

echo "=== CONFIGURE FHEMB ENV ===" >&2
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


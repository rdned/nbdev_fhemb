#!/bin/bash
set -eE -ex

echo "=== CONFIGURE SSH ===" >&2

mkdir -p ~/.ssh
echo "${FHEMB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${FHEMB_SSH_HOST} 2>/dev/null >> ~/.ssh/known_hosts

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

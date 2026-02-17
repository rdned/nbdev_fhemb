#!/bin/bash
set -eE -ex

echo "=== CONFIGURE FHEMB ENV ===" >&2

mkdir -p ~/.config/fhemb
echo "$FHEMB_ENV_DB" > ~/.config/fhemb/.env.db
echo "$FHEMB_ENV_PATHS" > ~/.config/fhemb/.env.paths

echo "=== CLEAR CACHES ===" >&2
rm -rf .nbdev_cache .quarto

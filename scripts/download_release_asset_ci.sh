#!/usr/bin/env bash
set -euo pipefail

# CI-friendly script to download a release asset (by tag + asset name) from GitHub.
# Usage: scripts/download_release_asset_ci.sh OWNER/REPO TAG ASSET_NAME [OUT_PATH]
# Example: scripts/download_release_asset_ci.sh rdned/fhemb v0.1.0 fhemb-0.1.0-py3-none-any.whl dist/fhemb.whl

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 OWNER/REPO TAG ASSET_NAME [OUT_PATH]"
  exit 0
fi

REPO="${1:-rdned/fhemb}"
TAG="${2:-v0.1.0}"
ASSET_NAME="${3:-fhemb-0.1.0-py3-none-any.whl}"
OUT="${4:-$ASSET_NAME}"
TOKEN="${GITHUB_TOKEN:-${FHEMB_TOKEN:-}}"  # CI: prefer FHEMB_TOKEN secret or GITHUB_TOKEN if allowed

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 2; }
command -v shasum >/dev/null 2>&1 || { echo "ERROR: shasum is required" >&2; exit 2; }

if [ -z "$TOKEN" ]; then
  echo "ERROR: No token provided. Set GITHUB_TOKEN or FHEMB_TOKEN in environment." >&2
  exit 1
fi

# Get release JSON
release_json="$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/${REPO}/releases/tags/${TAG}")"
if [ -z "$release_json" ] || [ "$(printf '%s' "$release_json" | jq -r '.message // empty')" = "Not Found" ]; then
  echo "ERROR: Release ${REPO}@${TAG} not found or inaccessible" >&2
  echo "Release API output:" >&2
  printf '%s
' "$release_json" | jq -r '.' >&2 || true
  exit 3
fi

# Find asset by name (extract fields directly)
asset_id="$(printf '%s' "$release_json" | jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name==$name) | .id // empty' | head -n1)"
if [ -z "$asset_id" ]; then
  echo "ERROR: Asset '$ASSET_NAME' not found in ${REPO}@${TAG}" >&2
  echo "Available assets:" >&2
  printf '%s
' "$release_json" | jq -r '.assets[] | " - " + .name' >&2
  exit 4
fi

expected_size="$(printf '%s' "$release_json" | jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name==$name) | .size // empty' | head -n1)"
digest="$(printf '%s' "$release_json" | jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name==$name) | .digest // empty' | head -n1)"

echo "Found asset id=${asset_id} size=${expected_size}"

# Download raw asset via API (works with private repos when using token)
curl -L -H "Authorization: Bearer $TOKEN" -H "Accept: application/octet-stream" -o "$OUT" "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}"

# Verify size
actual_size="$(wc -c <"$OUT" | tr -d '[:space:]')"
if [ -n "$expected_size" ] && [ "$actual_size" -ne "$expected_size" ]; then
  echo "Warning: size mismatch (expected ${expected_size}, got ${actual_size})" >&2
fi

# Verify digest if available
if [ -n "$digest" ]; then
  expected_sha="${digest#sha256:}"
  actual_sha="$(shasum -a 256 "$OUT" | awk '{print $1}')"
  if [ "$actual_sha" != "$expected_sha" ]; then
    echo "ERROR: SHA256 mismatch! expected ${expected_sha} got ${actual_sha}" >&2
    exit 5
  fi
  echo "OK: SHA256 verified"
else
  echo "No digest in release metadata — consider adding digest to the release assets (or verify manually)"
fi

echo "Downloaded: $OUT"
exit 0

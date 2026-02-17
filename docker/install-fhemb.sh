#!/bin/bash
set -eE -ex

echo "=== INSTALL FHEMB ===" >&2
echo "Using FHEMB_TAG=${FHEMB_TAG}" >&2
echo "Using FHEMB_WHEEL=${FHEMB_WHEEL}" >&2

git clone --depth 1 https://github.com/rdned/ci-utils.git utils
cd utils
git checkout "${CI_UTILS_COMMIT}"
cd ..

utils/download_release_asset_ci.sh \
  rdned/fhemb \
  "${FHEMB_TAG}" \
  "${FHEMB_WHEEL}" \
  "/tmp/${FHEMB_WHEEL}"

rm -rf utils
ls -lh /tmp/${FHEMB_WHEEL}

python3 -m pip install --no-cache-dir --force-reinstall /tmp/${FHEMB_WHEEL}

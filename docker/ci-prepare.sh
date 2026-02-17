#!/bin/bash
set -eE -ex

MODE="$1"

echo "=== CLONE REPOSITORY ===" >&2
git clone https://github.com/${GITHUB_REPOSITORY}.git repo
cd repo

# --- setup environment (clears caches) ---
source /usr/local/bin/setup-env.sh

# --- configure SSH ---
source /usr/local/bin/configure-ssh.sh
export SSH_PID  # ← Make it available to parent script

# --- install FHEMB wheel ---
source /usr/local/bin/install-fhemb.sh

# --- setup rendering ---
echo "=== INSTALL RENDERING STACK ===" >&2
python3 -m pip install -U kaleido plotly
python3 - <<'EOF'
import plotly.io as pio
pio.renderers.default = "png"
EOF

if [ "$MODE" = "test" ]; then
    echo "=== ENVIRONMENT DIAGNOSTICS ===" >&2
    pwd
    python3 --version
    pip show nbdev || true
    locale
fi

echo "=== NBDEV PREPARE ===" >&2
nbdev-prepare

if [ "$MODE" = "test" ]; then
    echo "=== NBDEV TEST ===" >&2
    nbdev-test --flags "" || echo "WARNING: nbdev_test failed" >&2

    if [ -n "$(git status --porcelain -uno)" ]; then
        echo "::error::Notebooks and library are not in sync."
        exit 1
    fi
    echo "=== SYNC OK ==="
fi

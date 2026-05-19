#!/bin/bash

# Exit immediately if any command fails
set -e

# =========================
# Full Docker Reset Script
# =========================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  COMPOSE="docker compose"
fi

echo "[1/5] Bringing down stack (including volumes)..."
# The config is stored in a named volume mounted at /etc/hlquery/conf. Keeping
# that volume across upgrades can preserve old/invalid links.conf files (e.g.,
# multi-value role=) and prevent hlquery from starting.
$COMPOSE down -v --remove-orphans || true

echo "[2/5] Rebuilding image (no cache)..."
$COMPOSE build --no-cache

echo "[3/5] Starting services on port 9200..."
export HOST_PORT=9200
$COMPOSE up -d

echo "[4/5] Running in-container bootstrap (optional)..."
$COMPOSE exec -T hlquery ./bootstrap.sh || true

echo "[5/5] Attaching to logs..."
$COMPOSE logs -f

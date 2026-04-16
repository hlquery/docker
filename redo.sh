#!/bin/bash

# Exit immediately if any command fails
set -e

# =========================
# Full Docker Reset Script
# =========================

echo "[1/6] Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "[2/6] Bringing down docker-compose stack..."
docker-compose down || true

echo "[3/6] Removing hlquery image..."
docker rmi hlquery:latest 2>/dev/null || true

echo "[4/6] Rebuilding images (no cache)..."
docker-compose build --no-cache

echo "[5/6] Starting services on port 9200..."
export HOST_PORT=9200
docker-compose up -d

echo "[6/6] Attaching to logs..."
docker-compose logs -f

echo "[6/7] Running bootstrap (compile)..."
docker-compose exec hlquery ./bootstrap.sh || true

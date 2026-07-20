#!/bin/bash
# Entrypoint script for hlquery Docker container
# This script runs when the container starts and handles:
# - Environment variable configuration
# - Directory creation and permissions
# - Passing commands to the hlquery binary

# Exit immediately if any command fails
set -e

# ----------------------------------------------------------------====================================
# Environment Variable Configuration
# ----------------------------------------------------------------====================================
# Set default values for configuration directories and port
# These can be overridden by environment variables passed to the container
# Syntax: ${VAR:-default} uses default if VAR is unset or empty

# Data directory: Where hlquery stores collection data and indexes
HLQUERY_DATA_DIR="${HLQUERY_DATA_DIR:-/var/lib/hlquery}"

# Log directory: Where hlquery writes log files
HLQUERY_LOG_DIR="${HLQUERY_LOG_DIR:-/var/log/hlquery}"

# Configuration directory: Where hlquery reads configuration files
HLQUERY_CONF_DIR="${HLQUERY_CONF_DIR:-/etc/hlquery/conf}"

# Port: HTTP API port that hlquery listens on
HLQUERY_PORT="${HLQUERY_PORT:-9200}"

# Default configuration seed directory inside the image. This exists so we can
# repopulate a config volume after breaking config changes across versions.
HLQUERY_CONF_SEED_DIR="${HLQUERY_CONF_SEED_DIR:-/usr/share/hlquery/conf-default}"
HLQUERY_CONFIG_FILE="${HLQUERY_CONFIG_FILE:-$HLQUERY_CONF_DIR/hlquery.conf}"

# ----------------------------------------------------------------====================================
# Directory Setup
# ----------------------------------------------------------------====================================
# Create directories if they don't exist
# -p: Create parent directories as needed, don't error if directory exists
mkdir -p "$HLQUERY_DATA_DIR" "$HLQUERY_LOG_DIR" "$HLQUERY_CONF_DIR"

# Set ownership of data and log directories
# chown: Change ownership to hlquery user and group
# 2>/dev/null: Suppress error messages (may fail if running as non-root)
# || true: Ensure script continues even if chown fails
# Note: This may fail in some Docker setups, but that's okay if volumes
# are already properly configured
chown -R hlquery:hlquery "$HLQUERY_DATA_DIR" "$HLQUERY_LOG_DIR" 2>/dev/null || true

# ----------------------------------------------------------------====================================
# Export Environment Variables
# ----------------------------------------------------------------====================================
# Export the environment variables so they're available to child processes
# This allows hlquery to read these values at runtime
export HLQUERY_DATA_DIR
export HLQUERY_LOG_DIR
export HLQUERY_CONF_DIR
export HLQUERY_PORT
export HLQUERY_CONFIG_FILE

# ----------------------------------------------------------------====================================
# Seed default configuration (if needed)
# ----------------------------------------------------------------====================================
# Docker named volumes copy the image contents on first use, but users often
# keep a persistent `hlquery_conf` volume across upgrades. If the persisted
# configuration is incomplete, seed it from the current image defaults.
if [ -d "$HLQUERY_CONF_SEED_DIR" ] && [ ! -f "$HLQUERY_CONF_DIR/hlquery.conf" ]; then
    echo "[INFO] No hlquery.conf found in $HLQUERY_CONF_DIR; seeding defaults from $HLQUERY_CONF_SEED_DIR"
    cp -a "$HLQUERY_CONF_SEED_DIR/." "$HLQUERY_CONF_DIR/"
fi

# Production mode intentionally fails closed. Secrets may be passed directly
# or through Docker/Kubernetes secret files using the *_FILE variables.
if [ "${HLQUERY_PRODUCTION:-0}" = "1" ]; then
    case "$HLQUERY_CONFIG_FILE" in
        /*) ;;
        *) echo "[ERROR] HLQUERY_CONFIG_FILE must be an absolute path in production mode"; exit 1 ;;
    esac

    if [ -z "${HLQUERY_ADMIN_TOKEN:-}" ] && [ -z "${HLQUERY_ADMIN_TOKEN_FILE:-}" ]; then
        echo "[ERROR] Production mode requires HLQUERY_ADMIN_TOKEN or HLQUERY_ADMIN_TOKEN_FILE"
        exit 1
    fi

    if [ -z "${HLQUERY_USERS_ENCRYPTION_KEY:-}" ] && [ -z "${HLQUERY_USERS_ENCRYPTION_KEY_FILE:-}" ]; then
        echo "[ERROR] Production mode requires HLQUERY_USERS_ENCRYPTION_KEY or HLQUERY_USERS_ENCRYPTION_KEY_FILE"
        exit 1
    fi
fi

# Quick preflight hint for a common links.conf failure: role= must be a single
# value (no whitespace, comma, or pipe). hlquery will validate too, but this
# prints a more actionable hint in container logs before restart loops.
if [ -f "$HLQUERY_CONF_DIR/links.conf" ]; then
    if grep -Eq 'role="[^"]*[,|[:space:]][^"]*"' "$HLQUERY_CONF_DIR/links.conf"; then
        echo "[ERROR] Invalid role= value detected in $HLQUERY_CONF_DIR/links.conf"
        echo "[ERROR] role= must be a single value: distributed/search/master OR slave/replica"
        echo "[ERROR] If you need both purposes, add two separate <node ...> entries (one per role)."
        echo "[ERROR] Example:"
        echo "[ERROR]   <node host=\"1.2.3.4\" port=\"9200\" role=\"distributed\" token=\"...\">"
        echo "[ERROR]   <node host=\"1.2.3.4\" port=\"9200\" role=\"slave\" token=\"...\">"
        exit 1
    fi
fi

# ----------------------------------------------------------------====================================
# Execute Command
# ----------------------------------------------------------------====================================
# Docker should launch the real daemon binary directly in foreground mode. The
# legacy `start --nofork` form is still accepted and translated here.
if [ $# -gt 0 ]; then
    case "$1" in
        start)
            shift
            set -- /usr/local/bin/hlqueryd "$@" --config "$HLQUERY_CONFIG_FILE"
            ;;
        hlqueryd|/usr/local/bin/hlqueryd)
            set -- "$@" --config "$HLQUERY_CONFIG_FILE"
            ;;
        hlquery|/usr/local/bin/hlquery|hlquery-cli|/usr/local/bin/hlquery-cli|sh|/bin/sh|bash|/bin/bash)
            ;;
        *)
            set -- /usr/local/bin/hlqueryd "$@" --config "$HLQUERY_CONFIG_FILE"
            ;;
    esac
else
    set -- /usr/local/bin/hlqueryd --nofork --config "$HLQUERY_CONFIG_FILE"
fi

# Execute the command passed to the container (from CMD or docker run)
# exec replaces the shell process with the command, allowing proper signal handling
# "$@" expands to all arguments passed to this script
exec "$@"

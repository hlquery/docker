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

# ----------------------------------------------------------------====================================
# Execute Command
# ----------------------------------------------------------------====================================
# Docker should launch the real daemon binary directly in foreground mode. The
# legacy `start --nofork` form is still accepted and translated here.
if [ $# -gt 0 ]; then
    case "$1" in
        start)
            shift
            set -- /usr/local/bin/hlqueryd "$@" --config "$HLQUERY_CONF_DIR/hlquery.conf"
            ;;
        hlqueryd|/usr/local/bin/hlqueryd)
            set -- "$@" --config "$HLQUERY_CONF_DIR/hlquery.conf"
            ;;
        hlquery|/usr/local/bin/hlquery|hlquery-cli|/usr/local/bin/hlquery-cli|sh|/bin/sh|bash|/bin/bash)
            ;;
        *)
            set -- /usr/local/bin/hlqueryd "$@" --config "$HLQUERY_CONF_DIR/hlquery.conf"
            ;;
    esac
else
    set -- /usr/local/bin/hlqueryd --nofork --config "$HLQUERY_CONF_DIR/hlquery.conf"
fi

# Execute the command passed to the container (from CMD or docker run)
# exec replaces the shell process with the command, allowing proper signal handling
# "$@" expands to all arguments passed to this script
exec "$@"

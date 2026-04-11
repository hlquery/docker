#!/bin/bash
# Health check test script for hlquery Docker container
# This script verifies that the hlquery container is running and responding
#
# Usage:
#   ./test_health.sh
#
# Exit codes:
#   0: Health check passed
#   1: Health check failed

set -e

# ----------------------------------------------------------------====================================
# Configuration
# ----------------------------------------------------------------====================================
# Container name (must match docker-compose.yml or docker run --name)
CONTAINER_NAME="hlquery"

# Health endpoint URL
# This is the endpoint that hlquery exposes for health checks
HEALTH_URL="http://localhost:9200/health"

# ----------------------------------------------------------------====================================
# Container Status Check
# ----------------------------------------------------------------====================================
echo "Testing hlquery health endpoint..."

# Check if the container is running
# docker ps: List running containers
# grep -q: Quietly search for container name (returns 0 if found, 1 if not)
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Container $CONTAINER_NAME is not running"
    echo ""
    echo "To start the container:"
    echo "  docker-compose up -d"
    echo "  or"
    echo "  docker start $CONTAINER_NAME"
    exit 1
fi

# ----------------------------------------------------------------====================================
# Health Endpoint Test
# ----------------------------------------------------------------====================================
# Test the health endpoint using curl
# -f: Fail silently on HTTP errors (return non-zero exit code)
# -s: Silent mode (don't show progress)
# > /dev/null: Discard output (we only care about exit code)
if curl -f -s "$HEALTH_URL" > /dev/null; then
    echo " Health check passed"
    echo ""
    echo "hlquery is running and responding at $HEALTH_URL"
    exit 0
else
    echo "❌ Health check failed"
    echo ""
    echo "The container is running but not responding to health checks."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check container logs: docker logs $CONTAINER_NAME"
    echo "  2. Verify port mapping: docker port $CONTAINER_NAME"
    echo "  3. Test from inside container: docker exec $CONTAINER_NAME curl http://localhost:9200/health"
    exit 1
fi

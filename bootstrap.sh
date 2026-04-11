#!/bin/bash
# Bootstrap script for hlquery Docker setup
# This script automates the setup process by:
# 1. Checking if Docker and Docker Compose are installed
# 2. Verifying Docker daemon is running
# 3. Building and starting the hlquery container
#
# Usage:
#   ./bootstrap.sh
#   or
#   wget -qO- https://raw.githubusercontent.com/hlquery/hlquery/unstable/etc/docker/bootstrap.sh | sh

set -e

# ----------------------------------------------------------------====================================
# Color Definitions
# ----------------------------------------------------------------====================================
# ANSI color codes for terminal output
# These make the output more readable and user-friendly
RED='\033[0;31m'      # Error messages
GREEN='\033[0;32m'    # Success messages
YELLOW='\033[1;33m'   # Warning messages
NC='\033[0m'          # No Color (reset)

# ----------------------------------------------------------------====================================
# Banner
# ----------------------------------------------------------------====================================
echo "🐳 hlquery Docker Bootstrap"
echo "============================"
echo ""

# ----------------------------------------------------------------====================================
# Docker Installation Check
# ----------------------------------------------------------------====================================
# Check if Docker command is available
# command -v: Returns the path to the command if it exists, nothing otherwise
# &> /dev/null: Redirects both stdout and stderr to /dev/null (suppress output)
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo ""
    echo "Please install Docker first:"
    echo "  Linux:   curl -fsSL https://get.docker.com | sudo sh"
    echo "  macOS:   Install Docker Desktop from https://www.docker.com/products/docker-desktop"
    echo "  Windows: Install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# ----------------------------------------------------------------====================================
# Docker Compose Installation Check
# ----------------------------------------------------------------====================================
# Check for Docker Compose (two possible commands)
# docker-compose: Standalone version (older)
# docker compose: Plugin version (newer, integrated into Docker CLI)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo ""
    echo "Please install Docker Compose:"
    echo "  It's usually included with Docker Desktop"
    echo "  Or install separately: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN} Docker is installed${NC}"

# ----------------------------------------------------------------====================================
# Docker Daemon Check
# ----------------------------------------------------------------====================================
# Verify that Docker daemon is running and accessible
# docker info: Returns information about the Docker installation
# If this fails, Docker is installed but not running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    echo ""
    echo "Please start Docker and try again."
    exit 1
fi

echo -e "${GREEN} Docker daemon is running${NC}"

# ----------------------------------------------------------------====================================
# Directory Setup
# ----------------------------------------------------------------====================================
# Get the directory where this script is located
# This allows the script to work regardless of where it's called from
# ${BASH_SOURCE[0]}: Path to this script file
# dirname: Gets the directory containing the script
# cd: Changes to that directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ----------------------------------------------------------------====================================
# Configuration File Check
# ----------------------------------------------------------------====================================
# Verify that docker-compose.yml exists in the script directory
# This ensures we're in the right place and have the necessary files
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Published host port. Override with HOST_PORT if port 9200 is already in use.
HOST_PORT="${HOST_PORT:-9200}"

# ----------------------------------------------------------------====================================
# Build and Start
# ----------------------------------------------------------------====================================
echo ""
echo "📦 Building and starting hlquery..."
echo ""

# Build the Docker image and start the container
# up: Start the containers
# -d: Run in detached mode (background)
# --build: Build images before starting containers
docker-compose up -d --build

echo ""
echo -e "${GREEN} hlquery is starting!${NC}"
echo ""
echo "Waiting for service to be ready..."
# Give the container a few seconds to initialize
sleep 5

# ----------------------------------------------------------------====================================
# Status Check
# ----------------------------------------------------------------====================================
# Check if the container is running
# docker-compose ps: List running containers
# grep -q "Up": Quietly search for "Up" status (returns 0 if found)
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN} Container is running${NC}"
    echo ""
    echo "🌐 hlquery is available at: http://localhost:${HOST_PORT}"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker-compose logs -f"
    echo "  Stop:         docker-compose down"
    echo "  Restart:      docker-compose restart"
    echo "  Status:       docker-compose ps"
    echo ""
    echo "Test the health endpoint:"
    echo "  curl http://localhost:${HOST_PORT}/health"
    echo ""
else
    # Container may still be starting, provide helpful information
    echo -e "${YELLOW} Container may still be starting. Check logs with:${NC}"
    echo "  docker-compose logs -f"
fi

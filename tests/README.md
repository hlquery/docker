<div align="center">
  <img src="../../docs/static/img/hlquery/2.png" alt="hlquery logo" width="200">
</div>

<div align="center">

**Docker validation scripts for hlquery build, startup, and health checks.**

[![Follow hlquery](https://img.shields.io/badge/Follow-%40hlquery-blue?logo=x&logoColor=white)](https://x.com/hlquery)
[![Linux Build](https://github.com/hlquery/hlquery/workflows/Linux%20build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![macOS Build](https://github.com/hlquery/hlquery/workflows/macOS%20Build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![FreeBSD Build](https://github.com/hlquery/hlquery/workflows/FreeBSD%20Build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/hlquery/hlquery)](https://github.com/hlquery/hlquery/pulse)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

</div>

# Docker Tests

This directory contains test scripts for verifying the hlquery Docker setup.

## Purpose

These tests help ensure that:
- The Docker image builds correctly
- The container starts and runs properly
- Health checks are working
- Configuration is loaded correctly
- The API is accessible

## Running Tests

### Run All Tests

```bash
# From the docker directory
cd tests
./run_all_tests.sh
```

### Run Individual Tests

```bash
# Test health endpoint
./test_health.sh

# Test Docker build
./test_build.sh

# Test configuration loading
./test_config.sh
```

## Test Files

### test_health.sh

Tests that the hlquery container is running and responding to health checks.

**What it does:**
- Verifies the container is running
- Tests the health endpoint at `http://localhost:9200/health`
- Provides troubleshooting information if the test fails

**Usage:**
```bash
./test_health.sh
```

**Exit codes:**
- `0`: Health check passed
- `1`: Health check failed

### test_build.sh (to be implemented)

Tests that the Docker image builds successfully.

**What it does:**
- Builds the Docker image
- Verifies the build completes without errors
- Checks that required binaries are present

### test_config.sh (to be implemented)

Tests that configuration files are loaded correctly.

**What it does:**
- Verifies configuration directory is mounted
- Checks that configuration files are readable
- Tests that settings are applied correctly

## Integration with CI/CD

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Test Docker build
  run: ./tests/test_build.sh

- name: Test health endpoint
  run: ./tests/test_health.sh
```

## Writing New Tests

When adding new tests:

1. Make the script executable: `chmod +x test_name.sh`
2. Use `set -e` to exit on errors
3. Provide clear output messages
4. Return appropriate exit codes (0 = success, 1 = failure)
5. Include troubleshooting information in error messages

## Requirements

Tests require:
- Docker and Docker Compose installed
- Container running (for health/config tests)
- `curl` command available (for HTTP tests)

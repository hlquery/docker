<div align="center">
  <img src="https://docs.hlquery.com/img/hlquery/2.png" alt="hlquery logo" width="200">
</div>

<div align="center">

**Docker configuration examples for hlquery runtime deployments.**

[![Follow hlquery](https://img.shields.io/badge/Follow-%40hlquery-blue?logo=x&logoColor=white)](https://x.com/hlquery)
[![Linux Build](https://github.com/hlquery/hlquery/workflows/Linux%20build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![macOS Build](https://github.com/hlquery/hlquery/workflows/macOS%20Build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![FreeBSD Build](https://github.com/hlquery/hlquery/workflows/FreeBSD%20Build/badge.svg)](https://github.com/hlquery/hlquery/actions)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/hlquery/hlquery)](https://github.com/hlquery/hlquery/pulse)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

</div>

# Docker Configuration Examples

This directory contains example configuration files for hlquery.

## Purpose

Configuration files allow you to customize hlquery's behavior without modifying the Docker image. You can override default settings, configure API endpoints, adjust search parameters, and more.

## Using Custom Configuration

### With Docker Compose

Mount this directory or your own configuration directory when running the container:

```yaml
volumes:
  - ./conf:/etc/hlquery/conf
```

This mounts your local `conf` directory to `/etc/hlquery/conf` inside the container.

### With Docker Command

```bash
docker run -v $(pwd)/conf:/etc/hlquery/conf hlquery:latest
```

### Permissions

**Important:** Make sure your configuration directory has the correct permissions. The container runs as user `hlquery` (UID 1000).

If you encounter permission issues:

```bash
# Set ownership to match container user
sudo chown -R 1000:1000 ./conf

# Or make files readable by all
chmod -R 644 ./conf/*
```

## Configuration Files

Place your configuration files in this directory. Common files include:

- `server.conf` - Main server configuration
- `api.conf` - API endpoint configuration  
- `search.conf` - Search engine settings
- `storage.conf` - Data storage configuration

## Example Setup

1. Copy example configuration files to this directory
2. Modify them according to your needs
3. Mount the directory when starting the container
4. Restart the container to apply changes

## Environment Variables vs Configuration Files

You can configure hlquery in two ways:

- **Environment Variables**: Quick setup, good for simple configurations
- **Configuration Files**: More flexible, better for complex setups

You can use both together - environment variables will override configuration file settings.

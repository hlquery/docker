<div align="center">
  <img src="https://docs.hlquery.com/img/hlquery/2.png" alt="hlquery logo" width="200">
</div>

<div align="center">

**Docker packaging and runtime for hlquery.**

[![Follow hlquery](https://img.shields.io/badge/Follow-%40hlquery-blue?logo=x&logoColor=white)](https://x.com/hlquery)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/hlquery/hlquery)](https://github.com/hlquery/docker/pulse)
[![hlquery](https://img.shields.io/badge/GitHub-hlquery-181717?logo=github&logoColor=white)](https://github.com/hlquery/hlquery/stargazers)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

</div>

**Get hlquery running in Docker!**

hlquery is a high-performance search engine written in C++ designed for fast full-text search and semantic search capabilities.

### Prerequisites

- Docker installed and running
- Docker Compose installed (usually included with Docker)
- Port 9200 available, or set `HOST_PORT` to publish on a different host port

### Installation

### Quick Start (Recommended)

The easiest way to install and run hlquery:

```bash
$ cd docker
$ docker-compose up -d
```

This will:
- Clone the hlquery source code from GitHub
- Build the Docker image
- Start hlquery on `http://localhost:9200`

If port `9200` is already in use on the host:

```bash
$ HOST_PORT=9201 docker-compose up -d
```

This keeps hlquery listening on port `9200` inside the container while publishing it as `http://localhost:9201` on the host.

**Verify it's running** (replace `9200` if you set `HOST_PORT`):
```bash
$ curl http://localhost:9200/health
```

### Using the Bootstrap Script

Alternatively, use the automated bootstrap script:

```bash
$ cd docker
$ ./bootstrap.sh
```

The bootstrap script will build and start hlquery automatically.

## Installation Methods

### Method 1: Docker Compose (Recommended)

1. **Navigate to the docker directory:**
   ```bash
   $ cd docker
   ```

2. **Start hlquery:**
   ```bash
   $ docker-compose up -d
   ```

3. **Check status:**
   ```bash
   $ docker-compose ps
   $ docker-compose logs -f
   ```

**Stop hlquery:**
```bash
$ docker-compose down
```

### Method 2: Docker Command

1. **Build the image:**
   ```bash
   $ cd docker
   $ docker build --build-arg VERSION=unstable -t hlquery:latest .
   ```

2. **Run the container:**
   ```bash
   $ docker run -d \
     --name hlquery \
     -p 9200:9200 \
     -v hlquery_data:/var/lib/hlquery \
     -v hlquery_logs:/var/log/hlquery \
     hlquery:latest
   ```

3. **Check status:**
   ```bash
   $ docker ps
   $ docker logs hlquery
   ```

**Stop hlquery:**
```bash
$ docker stop hlquery
$ docker rm hlquery
```

## Configuration

### Environment Variables

Configure hlquery using environment variables:

| Variable            | Default                    | Description                                    |
|---------------------|----------------------------|------------------------------------------------|
| `HLQUERY_PORT`      | `9200`                     | Port to listen on                               |
| `HLQUERY_DATA_DIR`  | `/var/lib/hlquery`         | Directory for data storage                      |
| `HLQUERY_LOG_DIR`   | `/var/log/hlquery`         | Directory for log files                         |
| `HLQUERY_CONF_DIR`  | `/etc/hlquery/conf`        | Directory for configuration files                |

The Docker image builds from `https://github.com/hlquery/hlquery` and defaults to the `unstable` branch. Override `VERSION` if you want a different branch, tag, or commit.

**Example - Change port:**
```bash
$ docker run -d \
  --name hlquery \
  -p 8080:8080 \
  -e HLQUERY_PORT=8080 \
  hlquery:latest
```

### Custom Configuration Files

Mount your configuration directory:

**Docker Compose:**
```yaml
volumes:
  - ./conf:/etc/hlquery/conf
```

**Docker command:**
```bash
$ docker run -d \
  --name hlquery \
  -p 9200:9200 \
  -v /path/to/your/config:/etc/hlquery/conf \
  hlquery:latest
```

*Note: The container runs as user `hlquery` (UID 1000). Ensure your config directory has correct permissions.*

### Change Port in Docker Compose

Set environment variables when starting Compose:
```bash
HOST_PORT=8080 HLQUERY_PORT=9200 docker-compose up -d
```

If you also want the service to listen on a different port inside the container:
```bash
HOST_PORT=8080 HLQUERY_PORT=8080 docker-compose up -d
```

## Building Custom Images

### Build from Source

```bash
$ cd docker
$ docker build -t hlquery:latest .
```

### Build with Custom Options

```bash
$ docker build \
  --build-arg VERSION=latest \
  --build-arg BUILD_MODE=release \
  --build-arg WITH_JEMALLOC=0 \
  -t hlquery:latest .
```

### Build Arguments

| Argument        | Options                                    | Default | Description                    |
|-----------------|--------------------------------------------|---------|--------------------------------|
| `VERSION`       | `latest`, `main`, `1.0.0`, `v1.0.0`, branch/tag | `latest` | Git version to build           |
| `BUILD_MODE`    | `release`, `debug`, `profile`, `sanitize` | `release` | Build configuration           |
| `WITH_JEMALLOC` | `0`, `1`                                   | `0`     | Enable jemalloc allocator      |
| `WITH_TCMALLOC` | `0`, `1`                                   | `0`     | Enable tcmalloc allocator      |

## Data Persistence

### Volumes

hlquery uses Docker volumes for persistent storage:

| Volume          | Mount Point              | Description                |
|-----------------|--------------------------|----------------------------|
| `hlquery_data`  | `/var/lib/hlquery`       | Collection data and indexes|
| `hlquery_logs`  | `/var/log/hlquery`       | Log files                  |
| `hlquery_conf`  | `/etc/hlquery/conf`      | Configuration files        |

### Using Named Volumes (Default)

Docker Compose automatically creates named volumes. Data persists across container restarts.

### Using Bind Mounts

Mount host directories directly:

```bash
$ docker run -d \
  --name hlquery \
  -p 9200:9200 \
  -v /host/data:/var/lib/hlquery \
  -v /host/logs:/var/log/hlquery \
  hlquery:latest
```

## Verifying Installation

### Check Container Status

```bash
# Docker Compose
$ docker-compose ps

# Docker
$ docker ps | grep hlquery
```

### Test Health Endpoint

```bash
$ curl http://localhost:${HOST_PORT:-9200}/health
```

### View Logs

```bash
# Docker Compose
$ docker-compose logs -f

# Docker
$ docker logs -f hlquery
```

## Common Commands

### Start/Stop

```bash
# Start
$ docker-compose up -d

# Stop
$ docker-compose down

# Restart
$ docker-compose restart
```

### Access Container Shell

```bash
# Docker Compose
$ docker-compose exec hlquery /bin/bash

# Docker
$ docker exec -it hlquery /bin/bash
```

### Update hlquery

1. **Pull latest code** (if using a specific version):
   ```bash
   # Edit docker-compose.yml to change VERSION build arg
   ```

2. **Rebuild and restart:**
   ```bash
   $ docker-compose build
   $ docker-compose up -d
   ```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
$ docker-compose logs
# or
$ docker logs hlquery
```

**Common issues:**
- **Port already in use**: Change port in `docker-compose.yml` or use `-p` flag
- **Permission denied**: Ensure volumes have correct permissions (UID 1000)
- **Out of disk space**: Clean up with `docker system prune`

### Can't Connect to API

1. Verify container is running: `docker ps`
2. Check port mapping: `docker port hlquery`
3. Test from inside container: `docker exec hlquery curl http://localhost:9200/health`
4. Check firewall settings

### Health Check Failing

1. Check container logs: `docker logs hlquery`
2. Manually test: `docker exec hlquery hlquery-cli status`
3. Increase startup time in `docker-compose.yml`:
   ```yaml
   healthcheck:
     start_period: 60s
   ```

## Production Deployment

For production, consider:

1. **Use specific image tags** instead of `latest`
2. **Set resource limits** (CPU, memory)
3. **Use external volumes** for better performance
4. **Configure log rotation**
5. **Set up monitoring and alerts**

See the [Production Deployment](#production-deployment) section in the full documentation for detailed examples.

---

**Search beyond keywords** - Happy searching! 

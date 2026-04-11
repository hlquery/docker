# Multi-stage Dockerfile for hlquery
# This Dockerfile uses a two-stage build process:
# Stage 1: Builds hlquery from source
# Stage 2: Creates a minimal runtime image with only the binaries

# ----------------------------------------------------------------====================================
# Stage 1: Build stage
# ----------------------------------------------------------------====================================
FROM ubuntu:22.04 AS builder

# Build arguments that can be customized when building the image
# VERSION: Git branch, tag, or commit to build (default: unstable)
# BUILD_MODE: Build configuration (release, debug, profile, sanitize, coverage)
# WITH_JEMALLOC: Enable jemalloc memory allocator (0 or 1)
# WITH_TCMALLOC: Enable tcmalloc memory allocator (0 or 1)
ARG VERSION=unstable
ARG BUILD_MODE=release
ARG WITH_JEMALLOC=0
ARG WITH_TCMALLOC=0

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies required to compile hlquery
# build-essential: Provides gcc, g++, make, and other build tools
# git: Required to clone the source code
# ca-certificates: Required for HTTPS connections to GitHub
# cmake: Required to build RocksDB from source (if vendor/rocksdb exists)
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    make \
    git \
    ca-certificates \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install SSL/TLS support libraries and RocksDB dependencies
# libssl-dev: Provides OpenSSL development headers
# librocksdb-dev: System RocksDB library (fallback if vendor/rocksdb not present)
# Compression libraries: Required if using system RocksDB
#   zlib1g-dev, libsnappy-dev, liblz4-dev, libzstd-dev, libbz2-dev
# The || true ensures this doesn't fail if packages are unavailable
RUN apt-get update && apt-get install -y \
    libssl-dev \
    librocksdb-dev \
    zlib1g-dev \
    libsnappy-dev \
    liblz4-dev \
    libzstd-dev \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/* || true

# Set working directory for the build process
WORKDIR /build

# Clone the hlquery source code from GitHub
# First attempt: Try to clone the specific branch/tag with --depth 1 (shallow clone)
# Fallback: If that fails (e.g., for commits or non-existent branches), do a full clone and checkout
# This approach supports both branches/tags and specific commit hashes
# If VERSION checkout via shallow clone fails, fall back to a full clone and checkout
RUN git clone --branch ${VERSION} --depth 1 https://github.com/hlquery/hlquery.git hlquery-src 2>/dev/null || \
    (git clone https://github.com/hlquery/hlquery.git hlquery-src && \
     cd hlquery-src && \
     (git checkout ${VERSION} 2>/dev/null || \
      (echo "Error: Cannot checkout '${VERSION}'" && exit 1)) && \
     cd ..)

# Change to the cloned source directory
WORKDIR /build/hlquery-src

# Configure and build hlquery
# ./configure: Runs the configuration script to set up the build
# make: Compiles hlquery with the specified build options
#   BUILD_MODE: Controls optimization and debug symbols
#   WITH_JEMALLOC/WITH_TCMALLOC: Memory allocator options
#   -j$(nproc): Uses all available CPU cores for parallel compilation
# make install: Installs the built binaries to the system paths
RUN ./configure && \
    make vendor/rocksdb/build/librocksdb.a && \
    make BUILD_MODE=${BUILD_MODE} \
         WITH_JEMALLOC=${WITH_JEMALLOC} \
         WITH_TCMALLOC=${WITH_TCMALLOC} \
         -j$(nproc) && \
    make install

# ----------------------------------------------------------------====================================
# Stage 2: Runtime stage
# ----------------------------------------------------------------====================================
# Start with a fresh Ubuntu base image for the runtime
# This keeps the final image small by excluding build dependencies
FROM ubuntu:22.04

# Install only runtime dependencies
# ca-certificates: Required for HTTPS connections in the application
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    zlib1g \
    libbz2-1.0 \
    liblz4-1 \
    libzstd1 \
    libsnappy1v5 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
# -r: Create a system user (no login shell)
# -s /bin/false: No shell access
# -u 1000: Use UID 1000 (matches common host user IDs)
# Create necessary directories and set ownership
RUN useradd -r -s /bin/false -u 1000 hlquery && \
    mkdir -p /var/lib/hlquery /var/lib/hlquery/pid /var/log/hlquery /etc/hlquery /opt/hlquery/modules /build/hlquery-src/run && \
    ln -s /etc/hlquery/conf /build/hlquery-src/run/conf && \
    ln -s /var/lib/hlquery /build/hlquery-src/run/data && \
    ln -s /var/log/hlquery /build/hlquery-src/run/logs && \
    ln -s /var/lib/hlquery/pid /build/hlquery-src/run/pid && \
    ln -s /opt/hlquery/modules /build/hlquery-src/run/modules && \
    chown -R hlquery:hlquery /var/lib/hlquery /var/log/hlquery /etc/hlquery

# Copy the built binaries from the builder stage
# hlquery: Wrapper script (kept for reference/manual use)
# hlqueryd: Main server binary used by Docker
# hlquery-cli: Command-line interface tool
# conf: Default configuration files
COPY --from=builder /build/hlquery-src/run/hlquery /usr/local/bin/hlquery
COPY --from=builder /build/hlquery-src/run/bin/hlquery /usr/local/bin/hlqueryd
COPY --from=builder /build/hlquery-src/run/bin/hlquery-cli /usr/local/bin/hlquery-cli
COPY --from=builder /build/hlquery-src/run/conf /etc/hlquery/conf
COPY --from=builder /build/hlquery-src/run/modules /opt/hlquery/modules

# Copy the entrypoint script from the build context
# This script handles initialization and environment setup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the working directory to the data directory
# This is where hlquery will store its data files
WORKDIR /var/lib/hlquery

# Expose the default HTTP API port
# This port can be overridden with the HLQUERY_PORT environment variable
EXPOSE 9200

# Switch to the non-root user for security
# All processes will run as the hlquery user (UID 1000)
USER hlquery

# Health check configuration
# Docker will periodically run this command to verify the container is healthy
# interval: Check every 30 seconds
# timeout: Wait up to 3 seconds for the command to complete
# start_period: Allow 5 seconds for the service to start before checking
# retries: Consider unhealthy after 3 consecutive failures
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/hlquery-cli status || exit 1

# Set the entrypoint script
# This script runs before the CMD and handles environment setup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command to start hlquery
# start: Start the server
# --nofork: Run in foreground (required for Docker)
CMD ["--nofork"]

# Nested Docker Sandboxing

A secure containerization solution that provides an additional layer of isolation through nested Docker containers with OverlayFS support. This solution is specifically designed for Ubuntu host systems, ensuring that the container environment matches the host setup to avoid environment reproduction issues.

## Overview

This project implements a parent container that can safely run Docker containers with enhanced isolation. It uses OverlayFS to provide a read-only lower filesystem layer while maintaining a writable upper layer, ensuring that host system binaries and libraries are accessible but protected. By matching the container environment with the host system, it eliminates the need to reproduce complex environments within containers.

## Features

- Secure nested Docker container execution
- OverlayFS-based filesystem isolation
- Automatic library dependency handling
- Read-only mounting of system binaries and libraries
- Dynamic binary dependency resolution
- Cleanup on container exit

## Prerequisites

- Docker installed on the host system
- Ubuntu 22.04 or later
- Sufficient permissions to run privileged containers

## Building

Build the parent container image:

```bash
docker build -t parent-container:latest .
```

## Usage

Use the `start_parent_container.sh` script to run commands within the parent container:

```bash
./start_parent_container.sh [command] [arguments]
```

The script automatically:
- Mounts necessary system directories
- Handles file dependencies
- Sets up the proper environment for nested container execution

### Example

```bash
./start_parent_container.sh docker run -it ubuntu:latest bash
```

## How it Works

1. The parent container is initialized with necessary system mounts and privileges
2. OverlayFS is used to create isolated filesystem layers:
   - Lower layer: Read-only system binaries and libraries
   - Upper layer: Writable container space
3. Binary dependencies are automatically resolved and mounted
4. File system events are monitored for proper cleanup
5. Cleanup is performed on container exit

## Directory Structure

```
/docker-overlay/
├── lower/          # Read-only system binaries and libraries
├── upper/          # Writable layer
├── work/           # OverlayFS work directory
└── merged/         # Final merged view

/sandbox-output/    # Output directory for sandbox operations
```

## Security Considerations

- The parent container runs with privileged access
- Host system binaries are mounted read-only
- Automatic cleanup of container resources
- Isolated network namespace

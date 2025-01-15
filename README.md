# Nested Docker Sandboxing

A secure containerization solution that provides an additional layer of isolation through Docker containers with OverlayFS support. This solution maintains host system binary and library compatibility while providing a secure, isolated execution environment.

## Overview

This project implements a containerized environment that can safely run commands with enhanced isolation. It uses OverlayFS to provide a read-only lower filesystem layer containing system binaries and libraries, while maintaining a writable upper layer for runtime modifications. The system ensures host compatibility by properly mapping user permissions and maintaining access to necessary system resources.

## Features

- Secure container execution with user permission mapping
- OverlayFS-based filesystem isolation
- Automatic system binary and library mounting
- Dynamic library dependency resolution
- File creation monitoring and dependency handling
- Proper user and group ID mapping from host
- Automatic cleanup on container exit

## Prerequisites

- Docker installed on the host system
- `fuse-overlayfs` support
- Sufficient permissions to run containers with SYS_ADMIN capability

## Usage

Use the `run_sandboxed_command.sh` script to execute commands within the sandboxed environment:

```bash
./run_sandboxed_command.sh [command] [arguments]
```

The script automatically:
- Maps the current user's home directory
- Sets up proper user/group permissions
- Mounts necessary system directories
- Handles library dependencies

### Example

```bash
./run_sandboxed_command.sh ls -la
```

## How it Works

1. The container environment is initialized with:
   - Current user's UID/GID mapping
   - Read-only mount of user's home directory
   - SYS_ADMIN capability for OverlayFS operations

2. The entrypoint script:
   - Sets up OverlayFS directory structure
   - Mounts system directories (usr/bin, lib, etc.)
   - Monitors file creation for dynamic dependency handling
   - Manages library dependencies through symlinks
   - Performs cleanup on exit

## Directory Structure

```
/docker-overlay/
├── lower/          # Read-only system binaries and libraries
│   ├── home/      # Read-only user home directory
│   ├── usr/bin    # System binaries
│   ├── usr/lib    # System libraries
│   └── lib        # Additional libraries
├── upper/         # Writable layer
├── work/          # OverlayFS work directory
└── merged/        # Final merged view
```

## Security Considerations

- Container runs with minimal required capabilities (SYS_ADMIN for OverlayFS)
- Host system files are mounted read-only
- User home directory is mounted read-only
- Automatic cleanup of resources on exit
- Proper user permission mapping

## Environment Variables

- `DEBUG`: Enable debug logging when set to true
- `CONTAINER_USER`: Username for the container (defaults to current user)
- `CONTAINER_UID`: User ID for the container (defaults to current UID)
- `CONTAINER_GID`: Group ID for the container (defaults to current GID)

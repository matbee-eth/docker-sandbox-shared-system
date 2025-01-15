# Nested Docker Sandboxing

A secure containerization solution that provides enhanced isolation through nested Docker containers with OverlayFS support. This system allows for secure execution of Docker containers while maintaining host system compatibility and protecting system resources.

## Overview

This project implements a secure container execution environment using a parent container architecture. It utilizes OverlayFS to create an isolated filesystem environment where host system binaries and libraries are accessible in read-only mode, while maintaining a separate writable layer for container operations. The system preserves user permissions and provides dynamic library dependency resolution.

## Features

- Secure nested Docker container execution with proper isolation
- OverlayFS-based filesystem layering with read-only lower layer
- Automatic user permission mapping between host and container
- Dynamic binary dependency resolution and linking
- Real-time monitoring of file creation events
- Automatic cleanup on container exit
- Support for non-root user execution
- Preservation of host user context inside containers

## Prerequisites

- Docker installed on the host system
- Ubuntu-based host system
- `fuse-overlayfs` support
- SYS_ADMIN capability for container operations

## Installation

Build the parent container image:

```bash
docker build -t parent-container:latest .
```

## Usage

Use the `run_sandboxed_command.sh` script to execute commands within the sandboxed environment:

```bash
./run_sandboxed_command.sh [command] [arguments]
```

The script automatically:
- Maps the current user's UID and GID to the container
- Mounts necessary host directories in read-only mode
- Sets up proper environment variables
- Handles container user creation and permissions

### Example

```bash
./run_sandboxed_command.sh python3 -c "import os; print(os.environ.get('USER', 'Unknown'))"
```

## Architecture

### Component Overview

1. **run_sandboxed_command.sh**
   - Entry point for running sandboxed commands
   - Handles user mapping and base mount setup
   - Manages container execution with proper capabilities

2. **entrypoint.sh**
   - Manages binary dependencies
   - Sets up OverlayFS mounts
   - Handles file monitoring and dynamic library linking
   - Manages cleanup operations

3. **docker-entrypoint-wrapper.sh**
   - Creates and configures container users
   - Sets up container home directories
   - Manages user switching and permission handling
   - Initializes the container environment

### Security Features

- Read-only mounting of host system directories
- Isolated writable layer using OverlayFS
- Proper user namespace mapping
- Dynamic dependency handling without modifying host system
- Automatic cleanup of temporary resources

## Environment Variables

- `DEBUG`: Enable debug logging (default: false)
- `CONTAINER_USER`: Username for container execution
- `CONTAINER_UID`: User ID for container user
- `CONTAINER_GID`: Group ID for container user

## Limitations

- Requires SYS_ADMIN capability for OverlayFS operations
- Host system must support fuse-overlayfs
- Designed for Ubuntu-based host systems

## Best Practices

1. Always run containers with the least privileged access necessary
2. Use non-root users when possible
3. Monitor container resource usage
4. Regularly update base images and dependencies

## Troubleshooting

If you encounter issues:
1. Enable debug mode by setting `DEBUG=true`
2. Check system logs for OverlayFS-related errors
3. Verify user permissions and mappings
4. Ensure all required capabilities are available

## Contributing

Contributions are welcome! Please ensure that any pull requests:
1. Maintain the security model
2. Include appropriate documentation
3. Add relevant tests
4. Follow the existing code style

## License

[Add appropriate license information]

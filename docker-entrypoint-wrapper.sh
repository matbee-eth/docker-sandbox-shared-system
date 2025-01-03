#!/bin/bash
set -e  # Exit on error
set -x  # Enable debug mode

# Debug info
echo "Debug: Starting docker-entrypoint-wrapper.sh"
echo "Debug: Current directory: $(pwd)"
echo "Debug: Script location: $0"
echo "Debug: Args: $@"
echo "Debug: Environment:"
env | sort

# Set default values
USERNAME=${CONTAINER_USER:-root}
USER_UID=${CONTAINER_UID:-0}
USER_GID=${CONTAINER_GID:-0}

if [ "$USERNAME" != "root" ]; then
    echo "Setting up non-root user $USERNAME"
    groupadd -g "$USER_GID" "$USERNAME" || true
    useradd -u "$USER_UID" -g "$USER_GID" -s /bin/bash "$USERNAME"
    usermod -aG docker "$USERNAME"
    
    # Create a new home directory inside the container
    echo "Setting up container home directory"
    mkdir -p "/container_home/$USERNAME"
    chown -R "$USERNAME:$USERNAME" "/container_home/$USERNAME"
    
    # Set HOME to the container home directory
    export HOME="/container_home/$USERNAME"
    
    echo "Running entrypoint.sh to set up environment"
    /opt/scripts/entrypoint.sh --setup-only
    
    echo "Switching to user $USERNAME with HOME=$HOME"
    # Stay in current directory (Docker's -w option sets this)
    exec gosu "$USERNAME" "$@"
else
    echo "Running as root"
    /opt/scripts/entrypoint.sh --setup-only
    exec "$@"
fi

#!/bin/bash
set -x  # Enable debug mode

# Initialize an array to store mount arguments
declare -a mount_args=()
declare -a cmd_args=()
declare -a overlay_dirs=()

# Get current user details
CURRENT_USER=$(id -un)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# Get current working directory
CWD=$(pwd)
cmd_args=("$@")

# Define base mounts
base_mounts=(
    "-v" "/home/$CURRENT_USER:/docker-overlay/lower/home/$CURRENT_USER:ro"
)

# Run the container with user mapping
docker run --rm \
    "${base_mounts[@]}" \
    "${mount_args[@]}" \
    -e CONTAINER_USER="$CURRENT_USER" \
    -e CONTAINER_UID="$CURRENT_UID" \
    -e CONTAINER_GID="$CURRENT_GID" \
    --cap-add SYS_ADMIN \
    parent-container:latest "${cmd_args[@]}"

rm -f "$SETUP_SCRIPT"

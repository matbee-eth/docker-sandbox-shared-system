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
# # Process arguments
# for arg in "$@"; do
#     # Clean up any quotes from the argument
#     arg_clean=$(echo "$arg" | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
    
#     # If the argument starts with a slash or ./
#     if [[ "$arg_clean" == /* || "$arg_clean" == ./* ]]; then
#         # Convert relative paths to absolute
#         if [[ "$arg_clean" == ./* ]]; then
#             arg_clean="$CWD/${arg_clean#./}"
#         fi
        
#         # If it's under /home, remap to overlay
#         if [[ "$arg_clean" == /home/* ]]; then
#             overlay_path="/docker-overlay/merged${arg_clean}"
#             overlay_dir=$(dirname "$overlay_path")
#             overlay_dirs+=("$overlay_dir")
#             cmd_args+=("$overlay_path")
#         else
#             # For other absolute paths, keep as is
#             cmd_args+=("$arg_clean")
#         fi
#     else
#         # For relative paths not starting with ./, remap to overlay under current directory
#         if [[ "$arg_clean" == */* || "$arg_clean" == *.* ]]; then
#             overlay_path="/docker-overlay/merged$CWD/${arg_clean}"
#             overlay_dir=$(dirname "$overlay_path")
#             overlay_dirs+=("$overlay_dir")
#             cmd_args+=("$overlay_path")
#         else
#             # For command arguments without path separators, keep as is
#             cmd_args+=("$arg_clean")
#         fi
#     fi
# done

# Define base mounts
base_mounts=(
    "-v" "/home/$CURRENT_USER:/docker-overlay/lower/home/$CURRENT_USER:ro"
)

# Run the container with user mapping
docker run --rm \
    --privileged \
    "${base_mounts[@]}" \
    "${mount_args[@]}" \
    -e CONTAINER_USER="$CURRENT_USER" \
    -e CONTAINER_UID="$CURRENT_UID" \
    -e CONTAINER_GID="$CURRENT_GID" \
    parent-container:latest "${cmd_args[@]}"

rm -f "$SETUP_SCRIPT"
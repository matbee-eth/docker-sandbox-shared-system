#!/bin/bash

# Initialize an array to store mount arguments
declare -a mount_args=()
# Initialize an array for modified command arguments
declare -a cmd_args=()

# Process each argument to check for existing files
for arg in "$@"; do
    # Remove any quotes from the argument
    arg_clean=$(echo "$arg" | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
    
    # Check if the argument is an existing file
    if [ -f "$arg_clean" ]; then
        # Get absolute paths for both host and container
        if [[ "$arg_clean" = /* ]]; then
            mount_path="$arg_clean"
        else
            mount_path="$(pwd)/$arg_clean"
        fi
        # Add mount argument
        mount_args+=("-v" "$mount_path:$mount_path:ro")
        # Use the mounted path in the command
        cmd_args+=("$mount_path")
        # echo "Mounting file: $mount_path"
    else
        # Keep original argument if it's not a file
        cmd_args+=("$arg")
    fi
done

# Base mounts for system directories
base_mounts=(
    "-v" "/usr/bin:/docker-overlay/lower/usr/bin:ro"
    "-v" "/usr/local/bin:/docker-overlay/lower/usr/local/bin:ro"
    "-v" "/usr/lib:/docker-overlay/lower/usr/lib:ro"
    "-v" "/lib:/docker-overlay/lower/lib:ro"
    "-v" "/usr/lib64:/docker-overlay/lower/usr/lib64:ro"
    "-v" "/lib64:/docker-overlay/lower/lib64:ro"
    "-v" "/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib/x86_64-linux-gnu:ro"
    "-v" "/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:ro"
)

# Run the container with all mounts
docker run --rm --privileged \
    --name parent-container \
    --cap-add=ALL \
    -w "$(pwd)" \
    "${base_mounts[@]}" \
    "${mount_args[@]}" \
    parent-container \
    "${cmd_args[@]}"
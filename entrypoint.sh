#!/bin/bash

set -x

DEBUG=${DEBUG:-false}

log_msg() {
    if [ "$DEBUG" != true ]; then
        return
    fi
    echo "$1"
}

handle_binary_deps() {
    local binary=$1
    log_msg "Handling dependencies for: $binary"
    ldd "$binary" | while read -r line; do
        if [[ $line =~ ([^[:space:]]+)[[:space:]]+'=>'[[:space:]]+([^[:space:]]+|not[[:space:]]+found) ]]; then
            local lib_name="${BASH_REMATCH[1]}"
            local lib_path="${BASH_REMATCH[2]}"
            if [[ $lib_path != "not found" ]]; then
                local target_dir="/docker-overlay/lower$(dirname "$lib_path")"
                mkdir -p "$target_dir"
                ln -sf "$lib_path" "$target_dir/$(basename "$lib_path")"
                log_msg "Created symlink: $lib_path -> $target_dir/$(basename "$lib_path")"
            fi
        fi
    done
}

cleanup() {
    log_msg "Cleaning up"
    kill $(jobs -p) 2>/dev/null
}

monitor_file_creation() {
    log_msg "Starting file creation monitor"
    inotifywait -m -r -e create,moved_to /usr/lib /lib | while read -r directory event filename; do
        local binary=$(command -v "$filename")
        if [ -n "$binary" ]; then
            handle_binary_deps "$binary"
        fi
    done &
}

USERNAME=${CONTAINER_USER:-root}
USER_UID=${CONTAINER_UID:-0}
USER_GID=${CONTAINER_GID:-0}

# Ensure PATH and LD_LIBRARY_PATH include our overlay directories
export PATH=/docker-overlay/lower/usr/bin:/docker-overlay/lower/usr/local/bin:/docker-overlay/lower/bin:$PATH
export LD_LIBRARY_PATH=/docker-overlay/lower/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib:/docker-overlay/lower/lib:/docker-overlay/lower/usr/lib64:/docker-overlay/lower/lib64:$LD_LIBRARY_PATH

# Set up signal handling
trap cleanup EXIT INT TERM

# Start monitoring file creation
monitor_file_creation

# Handle dependencies for the command
binary=$(command -v "$1")
if [ -n "$binary" ]; then
    handle_binary_deps "$binary"
fi

ldconfig

# Execute the command directly since we're already running as the correct user
exec "$@"

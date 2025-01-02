#!/bin/bash
# DO NOT FORGET TO BUILD THE IMAGE, WHEN MODIFYING THIS FILE, WITH THE FOLLOWING COMMAND:
# docker build -t parent-container:latest .

set -e
DEBUG=false

# Function to get current timestamp
log_msg() {
    if [ "$DEBUG" != true ]; then
        return
    fi
    local msg="$1"
    # Replace any timestamp patterns in the message with actual timestamp
    msg=$(echo "$msg" | sed 's/\[.*\]//')
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$msg"
}

log_cli_msg() {
    local msg="$1"
    printf "%b" "$msg"
}

# Create log pipes
exec 3> >(cat)
exec 4> >(sed 's/^/ERROR: /' >&2)

# Redirect stdout and stderr through our logging pipes
exec 1>&3
exec 2>&4

log_msg "Starting entrypoint script"

# Add mounted binary paths to PATH
export PATH="/docker-overlay/lower/usr/bin:/docker-overlay/lower/usr/local/bin:/docker-overlay/lower/bin:$PATH"
export LD_LIBRARY_PATH="/docker-overlay/lower/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib:/docker-overlay/lower/lib:$LD_LIBRARY_PATH"

# Function to handle library dependencies for a binary
handle_binary_deps() {
    local binary="$1"
    log_msg "Handling dependencies for: $binary"

    # Get all library dependencies using ldd
    ldd "$binary" 2>/dev/null | while read -r line; do
        # Extract library name and path/status
        if [[ $line =~ ([^[:space:]]+)[[:space:]]+'=>'[[:space:]]+([^[:space:]]+|not[[:space:]]+found) ]]; then
            local lib_name="${BASH_REMATCH[1]}"
            local lib_status="${BASH_REMATCH[2]}"

            if [[ "$lib_status" == "not found" ]]; then
                log_msg "Looking for missing library: $lib_name"

                # Find the library in the overlay
                local found_lib=$(find /docker-overlay/lower/usr/lib/x86_64-linux-gnu /docker-overlay/lower/lib/x86_64-linux-gnu -name "$lib_name" 2>/dev/null | head -n 1)
                if [[ -n "$found_lib" ]]; then
                    log_msg "Found library at $found_lib"
                    # Get the relative path from the overlay root
                    local rel_path=${found_lib#/docker-overlay/lower}
                    local target_path="$rel_path"
                    mkdir -p "$(dirname "$target_path")"
                    ln -sf "$found_lib" "$target_path"
                    log_msg "Created symlink: $found_lib -> $target_path"

                    # Also create a symlink in the standard library path
                    local std_path="/usr/lib/x86_64-linux-gnu/$lib_name"
                    mkdir -p "$(dirname "$std_path")"
                    ln -sf "$found_lib" "$std_path"
                    log_msg "Created additional symlink: $found_lib -> $std_path"
                fi
            else
                # Handle existing libraries
                local host_path="/docker-overlay/lower$lib_status"
                if [[ -f "$host_path" ]]; then
                    log_msg "Found library: $lib_name at $host_path"
                    local target_dir=$(dirname "$lib_status")
                    mkdir -p "$target_dir"
                    ln -sf "$host_path" "$lib_status"
                    log_msg "Created symlink: $host_path -> $lib_status"
                fi
            fi
        fi
    done
}

# Function to monitor file creation events
monitor_file_creation() {
    local monitor_dir="/tmp/binary_outputs"
    mkdir -p "$monitor_dir"

    # Create and switch to a working directory
    local work_dir="/sandbox-output/workspace"
    mkdir -p "$work_dir"
    cd "$work_dir"

    log_msg "Starting file monitoring for PID $cmd_pid in $work_dir"

    # Start monitoring in background
    ( 
        # Monitor process termination in background
        (
            while kill -0 $cmd_pid 2>/dev/null; do
                # Run inotifywait with a short timeout
                timeout 1s inotifywait -q -r "$work_dir" \
                    -e create -e moved_to -e modify -e delete -e moved_from \
                    --format '%w%f:%e' 2>/dev/null | while IFS=: read -r filepath event; do
                    # Skip if empty
                    [ -z "$filepath" ] && continue

                    # Get the filename from the path
                    local filename=$(basename "$filepath")

                    # Log and handle the event
                    case "$event" in
                    "CREATE" | "MOVED_TO")
                        log_msg "File created: $filepath"
                        if [ -f "$filepath" ]; then
                            cp -p "$filepath" "$monitor_dir/" 2>/dev/null || true
                            log_msg "Copied to monitor dir: $filename"
                        fi
                        ;;
                    "MODIFY")
                        log_msg "File modified: $filepath"
                        if [ -f "$filepath" ]; then
                            cp -p "$filepath" "$monitor_dir/" 2>/dev/null || true
                            log_msg "Updated in monitor dir: $filename"
                        fi
                        ;;
                    "DELETE" | "MOVED_FROM")
                        log_msg "File removed: $filepath"
                        if [ -f "$monitor_dir/$filename" ]; then
                            rm -f "$monitor_dir/$filename" 2>/dev/null || true
                            log_msg "Removed from monitor dir: $filename"
                        fi
                        ;;
                    esac
                done

                # Small sleep to prevent CPU spinning
                sleep 0.1
            done

            log_msg "Command process terminated, stopping file monitor"
        ) &
        monitor_pid=$!

        # Wait for the monitoring process
        wait $monitor_pid 2>/dev/null || true

        log_msg "File monitor exiting"
        exit 0
    ) &

    local background_pid=$!

    # Give the monitor a moment to initialize
    sleep 0.1

    # Store the monitor PID
    MONITOR_PID=$background_pid
    log_msg "File monitor initialized (PID: $MONITOR_PID)"

    # Return the monitor PID
    # echo "$background_pid"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log_msg "Starting cleanup process (exit code: $exit_code)"

    # List any captured files before cleanup
    log_msg "Listing captured output files:"
    if [ -d "/tmp/binary_outputs" ]; then
        find "/tmp/binary_outputs" -type f -exec ls -l {} \; 2>/dev/null | while read -r line; do
            log_msg "Captured file: $line"
        done
    fi

    # Kill the entire process group of the command
    if [ -n "$cmd_pid" ]; then
        log_msg "Killing command process group (PID: $cmd_pid)"
        pkill -TERM -P $cmd_pid 2>/dev/null || true
        kill -TERM -$cmd_pid 2>/dev/null || true
    fi

    # Kill the monitor process if it's still running
    if [ -n "$MONITOR_PID" ]; then
        log_msg "Terminating monitor process (PID: $MONITOR_PID)"
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
    fi

    # Final process cleanup
    log_msg "Final process cleanup"
    jobs -p | xargs -r kill 2>/dev/null || true

    # Close file descriptors
    exec 3>&-
    exec 4>&-
    exec 5>&-
    exec 6>&-

    log_msg "Cleanup complete"
    exit $exit_code
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Get the command to execute
if [ $# -eq 0 ]; then
    log_msg "No command provided"
    exit 1
fi

# Get the binary path
command_path=$(command -v "$1")
if [ -n "$command_path" ]; then
    log_msg "Setting up dependencies for command: $1"
    handle_binary_deps "$command_path"
fi

log_msg "Updating library cache..."
ldconfig

log_msg "Executing command: $@"

# Create and switch to workspace directory
work_dir="/sandbox-output/workspace"
mkdir -p "$work_dir"
cd "$work_dir"

# Start the command in a new process group and preserve color output
setsid "$@" >&3 2>&4 &
cmd_pid=$!
log_msg "Command started with PID $cmd_pid"

# Start file monitoring after command is started
log_msg "Starting file monitoring"
monitor_info=$(monitor_file_creation)
monitor_pid=$monitor_info
log_msg "File monitoring initialized with PID $monitor_pid"

# Wait for the command to complete
log_msg "Waiting for command PID $cmd_pid to complete"
if ! wait $cmd_pid; then
    cmd_exit_code=$?
    log_msg "Command failed with exit code $cmd_exit_code"
else
    cmd_exit_code=0
    log_msg "Command completed successfully"
fi

log_msg "Exiting with code $cmd_exit_code"
exit $cmd_exit_code

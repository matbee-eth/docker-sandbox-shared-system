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

# Process arguments
for arg in "$@"; do
    # Clean up any quotes from the argument
    arg_clean=$(echo "$arg" | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
    
    # If the argument starts with a slash or ./
    if [[ "$arg_clean" == /* || "$arg_clean" == ./* ]]; then
        # Convert relative paths to absolute
        if [[ "$arg_clean" == ./* ]]; then
            arg_clean="$CWD/${arg_clean#./}"
        fi
        
        # If it's under /home, remap to overlay
        if [[ "$arg_clean" == /home/* ]]; then
            overlay_path="/docker-overlay/upper${arg_clean#/home}"
            overlay_dir=$(dirname "$overlay_path")
            overlay_dirs+=("$overlay_dir")
            cmd_args+=("$overlay_path")
        else
            # For other absolute paths, keep as is
            cmd_args+=("$arg_clean")
        fi
    else
        # For relative paths not starting with ./, remap to overlay under current directory
        if [[ "$arg_clean" == */* || "$arg_clean" == *.* ]]; then
            overlay_path="/docker-overlay/upper$CWD/${arg_clean}"
            overlay_dir=$(dirname "$overlay_path")
            overlay_dirs+=("$overlay_dir")
            cmd_args+=("$overlay_path")
        else
            # For command arguments without path separators, keep as is
            cmd_args+=("$arg_clean")
        fi
    fi
done

# Define base mounts
base_mounts=(
    "-v" "/usr/bin:/usr/bin:ro"
    "-v" "/usr/local/bin:/usr/local/bin:ro"
    "-v" "/usr/lib:/usr/lib:ro"
    "-v" "/lib:/lib:ro"
    "-v" "/usr/lib64:/usr/lib64:ro"
    "-v" "/lib64:/lib64:ro"
    "-v" "/usr/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:ro"
    "-v" "/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:ro"
    "-v" "/home/$CURRENT_USER:/home/$CURRENT_USER:ro"
)

# Create a setup script in the current directory
SETUP_SCRIPT="$CWD/setup_overlay.sh"
echo "#!/bin/bash" > "$SETUP_SCRIPT"
echo "set -e" >> "$SETUP_SCRIPT"

# Add commands to create overlay directories
for dir in "${overlay_dirs[@]}"; do
    echo "mkdir -p '$dir'" >> "$SETUP_SCRIPT"
done

# Add command to copy input file to overlay if it exists in the host
if [[ "${cmd_args[2]}" == /docker-overlay/upper/* ]]; then
    src_file="${cmd_args[2]#/docker-overlay/upper}"
    if [ -f "/home$src_file" ]; then
        echo "mkdir -p $(dirname "${cmd_args[2]}")" >> "$SETUP_SCRIPT"
        echo "cp /home$src_file ${cmd_args[2]}" >> "$SETUP_SCRIPT"
    fi
fi

# Add the actual command
printf "%q " "${cmd_args[@]}" >> "$SETUP_SCRIPT"

chmod +x "$SETUP_SCRIPT"

# Run the container with user mapping
docker run --rm \
    --privileged \
    "${base_mounts[@]}" \
    "${mount_args[@]}" \
    -v "$SETUP_SCRIPT:/setup_overlay.sh:ro" \
    -e CONTAINER_USER="$CURRENT_USER" \
    -e CONTAINER_UID="$CURRENT_UID" \
    -e CONTAINER_GID="$CURRENT_GID" \
    -e HOME="/home/$CURRENT_USER" \
    -w "$CWD" \
    parent-container:latest \
    /setup_overlay.sh

rm -f "$SETUP_SCRIPT"
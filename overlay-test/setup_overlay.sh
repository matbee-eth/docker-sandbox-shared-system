#!/bin/bash
set -e

# Create necessary directories
mkdir -p /lower /upper /work /merged

# Mount the host directory to /lower
mount --bind /test-data /lower

echo "OverlayFS mounted successfully."
echo "Initial merged directory content:"
ls -la /merged

echo -e "\nWriting a new file in the container..."
echo "This file was created inside the container" > /merged/container-file.txt
echo -e "\nUpdated merged directory content:"
ls -la /merged

echo -e "\nContent of the new file:"
cat /merged/container-file.txt

echo -e "\nContent of the original host file:"
cat /merged/host-file.txt

# Trap to unmount on exit
trap 'fusermount -u /merged' EXIT

# Keep the container running for inspection
echo -e "\nContainer is now running. Use Ctrl+C to exit."
tail -f /dev/null

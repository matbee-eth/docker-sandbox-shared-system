#!/bin/bash
set -e

# Create necessary directories
mkdir -p /lower
mkdir -p /upper
mkdir -p /work
mkdir -p /merged

# Populate lower directory with sample files
echo "This is file1 in lower directory." > /lower/file1.txt
echo "This is file2 in lower directory." > /lower/file2.txt

# Mount OverlayFS
mount -t overlay overlay -o lowerdir=/lower,upperdir=/upper,workdir=/work /merged

echo "OverlayFS mounted successfully."
echo "Merged directory content:"
ls -l /merged

# Keep the container running
tail -f /dev/null

# Use the official Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Ensure /tmp is writable
RUN chmod 1777 /tmp

# Update package lists and install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        util-linux \
        procps \
        bash \
        fuse3 \
        && \
    rm -rf /var/lib/apt/lists/*

# Copy the setup script into the container
COPY setup_overlay.sh /setup_overlay.sh

# Make the setup script executable
RUN chmod +x /setup_overlay.sh

# Set the setup script as the entrypoint
ENTRYPOINT ["/setup_overlay.sh"]

ARG UBUNTU_VERSION="22.04"

FROM ubuntu:${UBUNTU_VERSION}

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up library paths
ENV PATH=/docker-overlay/lower/usr/bin:/docker-overlay/lower/usr/local/bin:/docker-overlay/lower/bin:$PATH
ENV LD_LIBRARY_PATH=/docker-overlay/lower/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib:/docker-overlay/lower/lib:/docker-overlay/lower/usr/lib64:/docker-overlay/lower/lib64

# Create necessary directories and set permissions
RUN mkdir -p /tmp && chmod 1777 /tmp

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
        docker.io \
        inotify-tools \
        sudo \
        bash \
        coreutils \
        util-linux \
        kmod \
        linux-modules-extra-$(uname -r) \
        && rm -rf /var/lib/apt/lists/*

# Set up docker group with same GID as host
RUN groupadd -g 999 docker || true && \
    usermod -aG docker root

# Create directories for OverlayFS, sandbox output, and host binary mounts
RUN mkdir -p /docker-overlay/lower \
             /docker-overlay/upper \
             /docker-overlay/work \
             /docker-overlay/merged \
             /sandbox-output/home \
             /docker-overlay/lower/usr/bin \
             /docker-overlay/lower/usr/local/bin \
             /docker-overlay/lower/usr/lib \
             /docker-overlay/lower/usr/lib64 \
             /docker-overlay/lower/lib \
             /docker-overlay/lower/lib64 \
             /usr/local/bin \
             /usr/bin && \
    chmod -R 777 /docker-overlay /sandbox-output /usr/local/bin /usr/bin && \
    chown -R root:root /docker-overlay

# Copy and set permissions for entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose Docker daemon port
EXPOSE 2375

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

ARG UBUNTU_VERSION="22.04"

FROM ubuntu:${UBUNTU_VERSION}

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up overlay paths
ENV PATH=/docker-overlay/lower/usr/bin:/docker-overlay/lower/usr/local/bin:/docker-overlay/lower/bin:$PATH
ENV LD_LIBRARY_PATH=/docker-overlay/lower/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib:/docker-overlay/lower/lib:/docker-overlay/lower/usr/lib64:/docker-overlay/lower/lib64

# Create /tmp directory with proper permissions
RUN mkdir -p /tmp && chmod 1777 /tmp

# Install required packages
RUN apt-get update && \
    apt-get install -y \
        docker.io \
        inotify-tools \
        bash \
        coreutils \
        util-linux \
        kmod \
        linux-modules-extra-$(uname -r) \
        gosu \
        dos2unix \
        ffmpeg \
        libblas3 \
        liblapack3 \
        && rm -rf /var/lib/apt/lists/*

# Add docker group and add root to it
RUN groupadd -g 999 docker || true && \
    usermod -aG docker root

# Create scripts directory and container home directory
RUN mkdir -p /opt/scripts && chmod 755 /opt/scripts && \
    mkdir -p /container_home && chmod 755 /container_home && \
    mkdir -p /host_home && chmod 755 /host_home && \
    mkdir -p /docker-overlay/lower/{usr,lib}{,/bin,/local/bin,/lib/x86_64-linux-gnu,/lib64} && \
    chmod -R 777 /docker-overlay

# Copy entrypoint script
COPY entrypoint.sh /opt/scripts/

# Fix line endings and set permissions
RUN dos2unix /opt/scripts/entrypoint.sh && \
    chmod +x /opt/scripts/entrypoint.sh

# Expose Docker daemon port
EXPOSE 2375

# Set the entrypoint
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]

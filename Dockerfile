ARG UBUNTU_VERSION="22.04"

FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/docker-overlay/lower/usr/bin:/docker-overlay/lower/usr/local/bin:/docker-overlay/lower/bin:$PATH
ENV LD_LIBRARY_PATH=/docker-overlay/lower/usr/lib/x86_64-linux-gnu:/docker-overlay/lower/lib/x86_64-linux-gnu:/docker-overlay/lower/usr/lib:/docker-overlay/lower/lib:/docker-overlay/lower/usr/lib64:/docker-overlay/lower/lib64

RUN mkdir -p /tmp && chmod 1777 /tmp

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
        fuse3 \
        fuse-overlayfs \
        && rm -rf /var/lib/apt/lists/*

RUN fuse-overlayfs --version
RUN groupadd -g 999 docker || true && \
    usermod -aG docker root

RUN mkdir -p /opt/scripts && chmod 755 /opt/scripts && \
    mkdir -p /docker-overlay \
    mkdir -p /docker-overlay/lower/{usr,lib}{,/bin,/local/bin,/lib/x86_64-linux-gnu,/lib64} && \
    chmod -R 777 /docker-overlay

COPY entrypoint.sh /opt/scripts/entrypoint.sh

RUN dos2unix /opt/scripts/entrypoint.sh && \
    chmod +x /opt/scripts/entrypoint.sh

EXPOSE 2375

ENTRYPOINT ["/opt/scripts/entrypoint.sh"]


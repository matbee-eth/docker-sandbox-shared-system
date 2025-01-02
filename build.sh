#!/bin/bash

# Get the Ubuntu version from the host system
HOST_UBUNTU_VERSION=$(lsb_release -rs)

# Build the Docker image with the host Ubuntu version
docker build --build-arg UBUNTU_VERSION=$HOST_UBUNTU_VERSION -t parent-container .

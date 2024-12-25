# Use Ubuntu noble (24.04) as the base image
FROM ubuntu:noble

# Set the environment variable to disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        ca-certificates \
        iproute2 \
        xz-utils \
        bzip2 \
        sudo \
        systemd \
        systemd-sysv \
        dbus \
        udev \
        locales \
        adduser && \
    rm -rf /var/lib/apt/lists/*

# Configure locale
RUN update-locale lang=en_US.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales

# Remove PRoot as we won't need it anymore
RUN rm -f /usr/local/bin/proot

# Create a non-root user with sudo privileges
RUN useradd -m -d /home/container -s /bin/bash container && \
    echo "container ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy scripts
COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./install.sh /install.sh
COPY --chown=container:container ./run.sh /run.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /install.sh /run.sh

# Set working directory
WORKDIR /home/container

# Use systemd as entrypoint
ENTRYPOINT ["/sbin/init"]

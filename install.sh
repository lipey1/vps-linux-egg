#!/bin/bash

# Define color codes
declare -A colors=(
    ["PURPLE"]='\033[0;35m'
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[0;33m'
    ["NC"]='\033[0m'
)

# Configuration variables
readonly ROOTFS_DIR="/home/container"

# Error handling function
error_exit() {
    printf "${colors[RED]}Error: $1${colors[NC]}\n" >&2
    exit 1
}

# Logger function
log() {
    local level=$1
    local message=$2
    local color=${colors[$3]}
    
    if [ -z "$color" ]; then
        color=${colors[NC]}
    fi
    
    printf "${color}[$level] $message${colors[NC]}\n"
}

# Install base system
install_base_system() {
    local distro=$1
    
    # Install debootstrap if not present
    if ! command -v debootstrap >/dev/null; then
        apt-get update
        apt-get install -y debootstrap
    fi
    
    # Install base system
    log "INFO" "Installing base system..." "GREEN"
    debootstrap --include=systemd,systemd-sysv,dbus,udev,sudo,curl,wget,nano \
        stable /home/container http://deb.debian.org/debian/
    
    # Configure system
    log "INFO" "Configuring system..." "GREEN"
    
    # Set root password
    chroot /home/container /bin/bash -c "echo root:vps123 | chpasswd"
    
    # Configure hostname
    echo "vps" > /home/container/etc/hostname
    
    # Configure hosts
    cat > /home/container/etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 vps
EOF
    
    # Configure fstab
    cat > /home/container/etc/fstab <<EOF
proc            /proc           proc    defaults          0       0
sysfs           /sys            sysfs   defaults          0       0
tmpfs           /tmp            tmpfs   defaults          0       0
EOF
}

# Main installation process
main() {
    log "INFO" "Starting installation..." "GREEN"
    
    # Install base system
    install_base_system "debian"
    
    log "INFO" "Installation completed successfully!" "GREEN"
}

main
#!/bin/bash

# Parse port configuration
parse_ports() {
    local config_file="$HOME/vps.config"
    local port_args=""
    
    # Adiciona a porta SSH definida na variável de ambiente
    if [ -n "$SSH_PORT" ]; then
        port_args=" -p $SSH_PORT:$SSH_PORT"
    fi
    
    while read -r line; do
        case "$line" in
            internalip=*) ;;
            port[0-9]*=*)
                port=${line#*=}
                if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi
            ;;
            port=*)
                port=${line#*=}
                if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi
            ;;
        esac
    done <"$config_file"
    echo "$port_args"
}

# Execute PRoot environment
exec_proot() {
    local port_args=$(parse_ports)
    
    # Iniciar SSH se instalado
    if [ -f "${HOME}/.ssh_installed" ]; then
        dropbear -E -F -p ${SSH_PORT:-22} &
    fi

    /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

exec_proot

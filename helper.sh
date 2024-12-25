#!/bin/bash

# Iniciar SSH se estiver instalado
if [ -f "/etc/dropbear/dropbear_rsa_host_key" ]; then
    pkill dropbear >/dev/null 2>&1
    dropbear -E -F -p ${SSH_PORT:-22} &
fi

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
    
    /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

exec_proot

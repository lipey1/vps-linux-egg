#!/bin/bash

# IMPORTANTE: Iniciar SSH se estiver instalado
if [ -f "/etc/dropbear/dropbear_rsa_host_key" ]; then
    pkill dropbear >/dev/null 2>&1
    sleep 1
    dropbear -E -F -p ${SSH_PORT:-22} &
fi

# Resto do script...
exec /usr/local/bin/proot --rootfs=/home/container -w /home/container /bin/bash

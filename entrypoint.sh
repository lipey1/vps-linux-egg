#!/bin/bash

cd /home/container

# IMPORTANTE: Iniciar SSH se estiver instalado
if [ -f "/etc/dropbear/dropbear_rsa_host_key" ]; then
    pkill dropbear >/dev/null 2>&1
    sleep 1
    dropbear -E -F -p ${SSH_PORT:-22} &
fi

# Resto do script...
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
eval ${MODIFIED_STARTUP}
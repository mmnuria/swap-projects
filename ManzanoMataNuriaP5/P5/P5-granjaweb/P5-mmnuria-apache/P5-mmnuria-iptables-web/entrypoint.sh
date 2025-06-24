#!/bin/bash
# Ejecuta el script de iptables
./mmnuria-iptables-web.sh
# Ejecuta el comando principal del contenedor
exec "$@"


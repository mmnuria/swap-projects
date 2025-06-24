#!/bin/bash
set -e

echo "Configurando reglas de red..."

# Instalar las herramientas necesarias (esto es para el host, no para el contenedor)
apk add --no-cache iptables iproute2 iputils-ping net-tools

# Habilitar el reenvío de IP en el host (para permitir el enrutamiento entre las redes)
echo "Habilitando reenvío de IP..."
sysctl -w net.ipv4.ip_forward=1

# Configurar reglas para red_web
echo "Configurando reglas para red_web (192.168.100.0/24)..."

# Permitir que los servidores nginx solo reciban tráfico en puerto 80
iptables -A FORWARD -d 192.168.100.20/32 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.100.20/32 -j DROP
iptables -A FORWARD -d 192.168.100.21/32 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.100.21/32 -j DROP

# Configurar reglas para red_servicios
echo "Configurando reglas para red_servicios (192.168.200.0/24)..."

# Restringir tráfico entre servidores apache y lighttpd
iptables -A FORWARD -s 192.168.200.10/32 -d 192.168.200.30/32 -j DROP
iptables -A FORWARD -s 192.168.200.10/32 -d 192.168.200.31/32 -j DROP
iptables -A FORWARD -s 192.168.200.11/32 -d 192.168.200.30/32 -j DROP
iptables -A FORWARD -s 192.168.200.11/32 -d 192.168.200.31/32 -j DROP

# Asegurarse de que el tráfico entre las redes esté permitido (si es necesario)
# Por ejemplo, permitir tráfico entre las redes red_web y red_servicios en puertos específicos
iptables -A FORWARD -i br_red_web -o br_red_svs -j ACCEPT
iptables -A FORWARD -i br_red_svs -o br_red_web -j ACCEPT

echo "Configuración de red completada."

# Mantener el contenedor ejecutándose
tail -f /dev/null

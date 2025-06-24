#!/bin/bash

# Políticas por defecto: bloquear todo
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Permitir tráfico de loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Conexiones establecidas y relacionadas (entrantes)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Conexiones nuevas, establecidas o relacionadas (salientes)
iptables -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Permitir tráfico HTTP/HTTPS desde balanceador
iptables -A INPUT -p tcp -s 192.168.10.50 --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.10.50 --dport 443 -j ACCEPT

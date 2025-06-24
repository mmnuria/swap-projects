#!/bin/bash
# Script para automatizar el despliegue de contenedores

set -e

# Variables de configuración
PROJECT_DIR="$(pwd)/.."
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
WEB_CONTENT_DIR="$PROJECT_DIR/web_mmnuria"

# Función para mostrar mensajes
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

# Verificar requisitos
check_requirements() {
    log "Verificando requisitos..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Por favor, instálalo primero."
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose no está instalado. Por favor, instálalo primero."
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "No se encuentra el archivo docker-compose.yml en $PROJECT_DIR"
    fi
    
    log "Todos los requisitos cumplidos."
}

# Preparar directorios
prepare_directories() {
    log "Preparando directorios..."
    
    # Crear directorios de contenido web si no existen
    mkdir -p "$WEB_CONTENT_DIR/apache"
    mkdir -p "$WEB_CONTENT_DIR/nginx"
    mkdir -p "$WEB_CONTENT_DIR/lighttpd"

    # Copiar el archivo index.php al directorio de cada servidor
    for dir in apache nginx lighttpd; do
        if [ -f "$WEB_CONTENT_DIR/index.php" ]; then
            cp "$WEB_CONTENT_DIR/index.php" "$WEB_CONTENT_DIR/$dir/index.php"
            log "Archivo index.php copiado a $WEB_CONTENT_DIR/$dir"
        else
            error "No se encontró el archivo index.php en $WEB_CONTENT_DIR"
        fi
    done
    
    log "Directorios y archivos preparados."
}

# Construir y desplegar contenedores
deploy_containers() {
    log "Construyendo y desplegando contenedores..."
    
    # Detener y eliminar contenedores existentes
    if docker-compose -f "$COMPOSE_FILE" ps &> /dev/null; then
        warn "Deteniendo contenedores existentes..."
        docker-compose -f "$COMPOSE_FILE" down
    fi
    
    # Construir imágenes
    log "Construyendo imágenes..."
    docker-compose -f "$COMPOSE_FILE" build
    
    # Iniciar contenedores
    log "Iniciando contenedores..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Verificar que todos los contenedores están en ejecución
    if [ "$(docker-compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | wc -l)" != "$(docker-compose -f "$COMPOSE_FILE" ps --services | wc -l)" ]; then
        error "No todos los contenedores están en ejecución. Verifica los logs."
    fi
    
    log "Contenedores desplegados correctamente."
}

# Verificar conexiones de red
verify_networking() {
    log "Verificando conexiones de red..."
    
    # Obtener nombres de contenedores
    CONTAINERS=$(docker-compose -f "$COMPOSE_FILE" ps --services)
    
    # Verificar asignación de IPs
    log "Verificando asignación de IPs..."
    for container in $CONTAINERS; do
        log "Contenedor $container:"
        docker inspect $container | grep -A 10 "Networks"
    done
    
    # Probar conectividad
    log "Probando conectividad entre contenedores..."
    FIRST_CONTAINER=$(echo $CONTAINERS | awk '{print $1}')
    
    for container in $CONTAINERS; do
        if [ "$container" != "$FIRST_CONTAINER" ]; then
            log "Probando conexión desde $FIRST_CONTAINER a $container..."
            if ! docker exec $FIRST_CONTAINER ping -c 1 $container &> /dev/null; then
                warn "No se puede establecer conexión con $container desde $FIRST_CONTAINER"
            else
                log "Conectividad con $container verificada."
            fi
        fi
    done
    
    log "Verificación de red completada."
}

# Función principal
main() {
    log "Iniciando despliegue automatizado..."
    
    check_requirements
    prepare_directories
    deploy_containers
    verify_networking
    
    log "Despliegue automatizado completado con éxito."
    log "Para acceder a los servicios:"
    
    # Mostrar información de acceso
    for container in $(docker-compose -f "$COMPOSE_FILE" ps --services); do
        IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
        log " - $container: http://$IP"
    done
}

# Ejecutar la función principal
main "$@"
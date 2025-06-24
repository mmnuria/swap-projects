#!/bin/bash
# Script para diagnóstico interno de contenedores Docker

# Variables de configuración
CONTAINER_NAME=$1
# Usar directorio en el HOME del usuario para logs
LOG_DIR="$HOME/docker_diagnostics"
LOG_FILE="$LOG_DIR/${CONTAINER_NAME}_diag.log"
# Por defecto, se instalan las herramientas si no existen
AUTO_INSTALL=${2:-true}  

# Verificar si se proporcionó un nombre de contenedor
if [ -z "$CONTAINER_NAME" ]; then
    echo "ERROR: Debe proporcionar un nombre de contenedor."
    echo "Uso: $0 <nombre_contenedor> [auto_install:true|false]"
    exit 1
fi

# Verificar si el contenedor existe
if ! docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "ERROR: El contenedor '$CONTAINER_NAME' no existe o no está en ejecución."
    exit 1
fi

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Función para registrar eventos
log_event() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $CONTAINER_NAME - $1" | tee -a "$LOG_FILE"
}

# Detectar sistema de paquetes del contenedor
detect_package_system() {
    log_event "Detectando sistema de paquetes del contenedor..."
    
    if docker exec "$CONTAINER_NAME" which apt-get &>/dev/null; then
        PACKAGE_SYSTEM="apt"
        log_event "Sistema de paquetes detectado: APT (Debian/Ubuntu)"
    elif docker exec "$CONTAINER_NAME" which dnf &>/dev/null; then
        PACKAGE_SYSTEM="dnf"
        log_event "Sistema de paquetes detectado: DNF (Fedora/RHEL)"
    elif docker exec "$CONTAINER_NAME" which yum &>/dev/null; then
        PACKAGE_SYSTEM="yum"
        log_event "Sistema de paquetes detectado: YUM (CentOS/RHEL)"
    elif docker exec "$CONTAINER_NAME" which apk &>/dev/null; then
        PACKAGE_SYSTEM="apk"
        log_event "Sistema de paquetes detectado: APK (Alpine)"
    else
        PACKAGE_SYSTEM="unknown"
        log_event "ADVERTENCIA: No se pudo determinar el sistema de paquetes"
    fi
}

# Instalar herramientas necesarias si no están disponibles
install_tools() {
    if [ "$AUTO_INSTALL" != "true" ]; then
        log_event "Instalación automática desactivada. Omitiendo."
        return
    fi
    
    if [ "$PACKAGE_SYSTEM" == "unknown" ]; then
        log_event "ERROR: No se puede instalar herramientas con un sistema de paquetes desconocido."
        return
    fi
    
    log_event "Preparando para instalar herramientas necesarias..."
    
    # Actualizar repositorios
    case $PACKAGE_SYSTEM in
        apt)
            log_event "Actualizando repositorios APT..."
            docker exec "$CONTAINER_NAME" apt-get update
            ;;
        dnf)
            log_event "Actualizando repositorios DNF..."
            # Evitar salir con error si hay actualizaciones
            docker exec "$CONTAINER_NAME" dnf check-update || true  
            ;;
        yum)
            log_event "Actualizando repositorios YUM..."
            # Evitar salir con error si hay actualizaciones
            docker exec "$CONTAINER_NAME" yum check-update || true  
            ;;
        apk)
            log_event "Actualizando repositorios APK..."
            docker exec "$CONTAINER_NAME" apk update
            ;;
    esac
    
    # Instalar htop si no está disponible
    if ! docker exec "$CONTAINER_NAME" which htop &>/dev/null; then
        log_event "Instalando htop..."
        case $PACKAGE_SYSTEM in
            apt)
                docker exec "$CONTAINER_NAME" apt-get install -y htop
                ;;
            dnf)
                docker exec "$CONTAINER_NAME" dnf install -y htop
                ;;
            yum)
                docker exec "$CONTAINER_NAME" yum install -y htop
                ;;
            apk)
                docker exec "$CONTAINER_NAME" apk add htop
                ;;
        esac
        log_event "htop instalado."
    fi
    
    # Instalar netstat si no está disponible
    if ! docker exec "$CONTAINER_NAME" which netstat &>/dev/null; then
        log_event "Instalando herramientas de red (netstat)..."
        case $PACKAGE_SYSTEM in
            apt)
                docker exec "$CONTAINER_NAME" apt-get install -y net-tools
                ;;
            dnf)
                docker exec "$CONTAINER_NAME" dnf install -y net-tools
                ;;
            yum)
                docker exec "$CONTAINER_NAME" yum install -y net-tools
                ;;
            apk)
                docker exec "$CONTAINER_NAME" apk add net-tools
                ;;
        esac
        log_event "net-tools (netstat) instalado."
    fi
    
    # Instalar apache2ctl si no está disponible
    if ! docker exec "$CONTAINER_NAME" which apache2ctl &>/dev/null && ! docker exec "$CONTAINER_NAME" which httpd &>/dev/null; then
        log_event "Instalando utilidades de Apache..."
        case $PACKAGE_SYSTEM in
            apt)
                docker exec "$CONTAINER_NAME" apt-get install -y apache2-utils
                ;;
            dnf)
                docker exec "$CONTAINER_NAME" dnf install -y httpd-tools
                ;;
            yum)
                docker exec "$CONTAINER_NAME" yum install -y httpd-tools
                ;;
            apk)
                docker exec "$CONTAINER_NAME" apk add apache2-utils
                ;;
        esac
        log_event "Utilidades de Apache instaladas."
    fi
}

# Verificar si las herramientas están disponibles en el contenedor
check_tools() {
    log_event "Verificando herramientas disponibles..."
    
    # Verificar htop
    if docker exec "$CONTAINER_NAME" which htop &>/dev/null; then
        log_event "La herramienta htop está disponible"
        HTOP_AVAILABLE=true
    else
        log_event "La herramienta htop no está disponible"
        HTOP_AVAILABLE=false
    fi
    
    # Verificar netstat
    if docker exec "$CONTAINER_NAME" which netstat &>/dev/null; then
        log_event "La herramienta netstat está disponible"
        NETSTAT_AVAILABLE=true
    else
        log_event "La herramienta netstat no está disponible"
        NETSTAT_AVAILABLE=false
    fi
    
    # Verificar apache2ctl
    if docker exec "$CONTAINER_NAME" which apache2ctl &>/dev/null || docker exec "$CONTAINER_NAME" which httpd &>/dev/null; then
        log_event "La herramienta apache2ctl/httpd está disponible"
        APACHE_AVAILABLE=true
    else
        log_event "La herramienta apache2ctl/httpd no está disponible"
        APACHE_AVAILABLE=false
    fi
}

# Ejecutar diagnóstico con htop (captura datos básicos)
run_htop_diagnostics() {
    if [ "$HTOP_AVAILABLE" = true ]; then
        log_event "Ejecutando diagnóstico con htop..."
        # htop es interactivo, así que usamos top en modo batch
        TMP_FILE="$LOG_DIR/${CONTAINER_NAME}_top.txt"
        docker exec "$CONTAINER_NAME" top -bn1 > "$TMP_FILE"
        cat "$TMP_FILE" >> "$LOG_FILE"
        log_event "Diagnóstico con top completado"
    fi
}

# Ejecutar diagnóstico con netstat
run_netstat_diagnostics() {
    if [ "$NETSTAT_AVAILABLE" = true ]; then
        log_event "Ejecutando diagnóstico de conexiones con netstat..."
        
        # Conexiones establecidas
        log_event "Conexiones establecidas:"
        docker exec "$CONTAINER_NAME" netstat -an | grep ESTABLISHED >> "$LOG_FILE"
        
        # Puertos en escucha
        log_event "Puertos en escucha:"
        docker exec "$CONTAINER_NAME" netstat -tulpn >> "$LOG_FILE"
        
        # Estadísticas de conexiones
        log_event "Estadísticas de conexiones:"
        docker exec "$CONTAINER_NAME" netstat -s >> "$LOG_FILE"
        
        log_event "Diagnóstico con netstat completado"
    fi
}

# Ejecutar diagnóstico con apache2ctl
run_apache_diagnostics() {
    if [ "$APACHE_AVAILABLE" = true ]; then
        log_event "Ejecutando diagnóstico de Apache..."
        
        # Verificar primero si Apache está realmente instalado (no solo las utilidades)
        if docker exec "$CONTAINER_NAME" which apache2 &>/dev/null || docker exec "$CONTAINER_NAME" which httpd &>/dev/null; then
            # Determinar qué comando usar
            APACHE_CMD="apache2ctl"
            if ! docker exec "$CONTAINER_NAME" which apache2ctl &>/dev/null; then
                APACHE_CMD="httpd"
            fi
            
            # Estado general
            log_event "Estado general de Apache:"
            if [ "$APACHE_CMD" = "apache2ctl" ]; then
                docker exec "$CONTAINER_NAME" apache2ctl status >> "$LOG_FILE" 2>&1
            else
                docker exec "$CONTAINER_NAME" httpd -S >> "$LOG_FILE" 2>&1
            fi
            
            # Información del módulo
            log_event "Módulos cargados:"
            if [ "$APACHE_CMD" = "apache2ctl" ]; then
                docker exec "$CONTAINER_NAME" apache2ctl -M >> "$LOG_FILE" 2>&1
            else
                docker exec "$CONTAINER_NAME" httpd -M >> "$LOG_FILE" 2>&1
            fi
            
            # Configuración
            log_event "Configuración:"
            if [ "$APACHE_CMD" = "apache2ctl" ]; then
                docker exec "$CONTAINER_NAME" apache2ctl -S >> "$LOG_FILE" 2>&1
            else
                docker exec "$CONTAINER_NAME" httpd -S >> "$LOG_FILE" 2>&1
            fi
            
            # Prueba de configuración
            log_event "Prueba de configuración:"
            if [ "$APACHE_CMD" = "apache2ctl" ]; then
                docker exec "$CONTAINER_NAME" apache2ctl configtest >> "$LOG_FILE" 2>&1
            else
                docker exec "$CONTAINER_NAME" httpd -t >> "$LOG_FILE" 2>&1
            fi
        else
            log_event "ADVERTENCIA: apache2ctl/httpd-tools está disponible pero Apache no está instalado"
        fi
        
        log_event "Diagnóstico con apache2ctl completado"
    fi
}

# Ejecutar diagnóstico general
run_general_diagnostics() {
    log_event "Ejecutando diagnóstico general del sistema..."
    
    # Información del sistema
    log_event "Información del sistema:"
    docker exec "$CONTAINER_NAME" uname -a >> "$LOG_FILE"
    
    # Uso de CPU
    log_event "Uso de CPU:"
    docker exec "$CONTAINER_NAME" cat /proc/cpuinfo | grep "model name" | head -n1 >> "$LOG_FILE"
    docker exec "$CONTAINER_NAME" cat /proc/loadavg >> "$LOG_FILE"
    
    # Uso de memoria
    log_event "Uso de memoria:"
    if docker exec "$CONTAINER_NAME" which free &>/dev/null; then
        docker exec "$CONTAINER_NAME" free -h >> "$LOG_FILE"
    else
        log_event "Comando 'free' no disponible"
        # Alternativa en sistemas sin el comando free
        if docker exec "$CONTAINER_NAME" test -f /proc/meminfo; then
            docker exec "$CONTAINER_NAME" cat /proc/meminfo | head -n 5 >> "$LOG_FILE"
        fi
    fi
    
    # Espacio en disco
    log_event "Espacio en disco:"
    docker exec "$CONTAINER_NAME" df -h >> "$LOG_FILE"
    
    # Procesos en ejecución
    log_event "Procesos en ejecución:"
    if docker exec "$CONTAINER_NAME" which ps &>/dev/null; then
        if docker exec "$CONTAINER_NAME" ps aux &>/dev/null; then
            docker exec "$CONTAINER_NAME" ps aux >> "$LOG_FILE"
        else
            docker exec "$CONTAINER_NAME" ps -ef >> "$LOG_FILE"
        fi
    else
        log_event "Comando 'ps' no disponible"
        # Alternativa usando /proc
        docker exec "$CONTAINER_NAME" ls -l /proc/[0-9]* | grep -v task | wc -l >> "$LOG_FILE"
        log_event "Número de procesos (contados desde /proc)"
    fi
    
    log_event "Diagnóstico general completado"
}

# Mostrar resumen de diagnóstico
show_summary() {
    log_event "================================================="
    log_event "RESUMEN DEL DIAGNÓSTICO"
    log_event "================================================="
    log_event "Contenedor: $CONTAINER_NAME"
    log_event "Sistema de paquetes: $PACKAGE_SYSTEM"
    log_event "Herramientas disponibles:"
    log_event "  - htop: $([ "$HTOP_AVAILABLE" = true ] && echo "SÍ" || echo "NO")"
    log_event "  - netstat: $([ "$NETSTAT_AVAILABLE" = true ] && echo "SÍ" || echo "NO")"
    log_event "  - apache2ctl/httpd: $([ "$APACHE_AVAILABLE" = true ] && echo "SÍ" || echo "NO")"
    log_event "Archivo de registro completo: $LOG_FILE"
    log_event "================================================="
}

# Función principal
main() {
    log_event "=========== Iniciando diagnóstico interno del contenedor ==========="
    
    detect_package_system
    check_tools
    
    # Instalar herramientas si es necesario
    if [ "$AUTO_INSTALL" = "true" ] && { [ "$HTOP_AVAILABLE" = false ] || [ "$NETSTAT_AVAILABLE" = false ] || [ "$APACHE_AVAILABLE" = false ]; }; then
        log_event "Se detectaron herramientas faltantes. Procediendo con la instalación automática."
        install_tools
        check_tools  # Volver a verificar después de la instalación
    fi
    
    run_general_diagnostics
    run_htop_diagnostics
    run_netstat_diagnostics
    run_apache_diagnostics
    show_summary
    
    log_event "Diagnóstico interno completado."
    echo ""
    echo "Diagnóstico completado. El archivo de log está en: $LOG_FILE"
}

# Ejecutar función principal
main
#!/bin/bash
# Script de mantenimiento para contenedores

# Variables de configuración
LOG_DIR="/var/log"
MAX_LOG_SIZE_MB=100
MAX_LOG_AGE_DAYS=7

# Función para limpiar logs
clean_logs() {
    echo "$(date): Iniciando limpieza de logs..."
    
    # Encontrar y comprimir archivos de log más antiguos que MAX_LOG_AGE_DAYS
    find $LOG_DIR -name "*.log" -type f -mtime +$MAX_LOG_AGE_DAYS -exec gzip {} \;
    
    # Encontrar y eliminar archivos comprimidos más antiguos que el doble de MAX_LOG_AGE_DAYS
    find $LOG_DIR -name "*.gz" -type f -mtime +$((MAX_LOG_AGE_DAYS*2)) -delete
    
    # Encontrar archivos de log mayores que MAX_LOG_SIZE_MB y rotarlos
    find $LOG_DIR -name "*.log" -type f -size +${MAX_LOG_SIZE_MB}M -exec mv {} {}.old \;
    
    echo "$(date): Limpieza de logs completada."
}

# Función para verificar el estado de los servicios
check_services() {
    echo "$(date): Verificando estado de servicios..."
    
    # Comprobar qué tipo de servidor web está ejecutándose
    if command -v apache2 &> /dev/null; then
        if ! apache2ctl status > /dev/null; then
            echo "$(date): Apache no está funcionando correctamente. Intentando reiniciar..."
            apache2ctl restart
        else
            echo "$(date): Apache está funcionando correctamente."
        fi
    elif command -v nginx &> /dev/null; then
        if ! service nginx status > /dev/null; then
            echo "$(date): Nginx no está funcionando correctamente. Intentando reiniciar..."
            service nginx restart
        else
            echo "$(date): Nginx está funcionando correctamente."
        fi
    elif command -v lighttpd &> /dev/null; then
        if ! service lighttpd status > /dev/null; then
            echo "$(date): Lighttpd no está funcionando correctamente. Intentando reiniciar..."
            service lighttpd restart
        else
            echo "$(date): Lighttpd está funcionando correctamente."
        fi
    fi
    
    # Comprobar PHP-FPM si está instalado
    if command -v php-fpm7.4 &> /dev/null; then
        if ! service php7.4-fpm status > /dev/null; then
            echo "$(date): PHP-FPM no está funcionando correctamente. Intentando reiniciar..."
            service php7.4-fpm restart
        else
            echo "$(date): PHP-FPM está funcionando correctamente."
        fi
    fi
    
    echo "$(date): Verificación de servicios completada."
}

# Función para generar informe de estado
generate_status_report() {
    REPORT_FILE="/tmp/status_report_$(date +%Y%m%d).txt"
    echo "$(date): Generando informe de estado en $REPORT_FILE..."
    
    echo "=== INFORME DE ESTADO DEL SERVIDOR ($(date)) ===" > $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    echo "=== INFORMACIÓN DEL SISTEMA ===" >> $REPORT_FILE
    echo "Hostname: $(hostname)" >> $REPORT_FILE
    echo "IP Addresses:" >> $REPORT_FILE
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    echo "=== USO DE RECURSOS ===" >> $REPORT_FILE
    echo "CPU:" >> $REPORT_FILE
    top -l 1 | head -10 | grep "CPU usage" >> $REPORT_FILE
    echo "Memoria:" >> $REPORT_FILE
    vm_stat >> $REPORT_FILE
    echo "Disco:" >> $REPORT_FILE
    df -h >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    echo "=== CONEXIONES ACTIVAS ===" >> $REPORT_FILE
    echo "Conexiones establecidas:" >> $REPORT_FILE
    netstat -ant | grep ESTABLISHED | wc -l >> $REPORT_FILE
    echo "Conexiones en espera:" >> $REPORT_FILE
    netstat -ant | grep LISTEN | wc -l >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    echo "=== LOGS RECIENTES ===" >> $REPORT_FILE
    if [ -f /var/log/apache2/error.log ]; then
        echo "Últimos errores de Apache:" >> $REPORT_FILE
        tail -n 10 /var/log/apache2/error.log >> $REPORT_FILE
    elif [ -f /var/log/nginx/error.log ]; then
        echo "Últimos errores de Nginx:" >> $REPORT_FILE
        tail -n 10 /var/log/nginx/error.log >> $REPORT_FILE
    elif [ -f /var/log/lighttpd/error.log ]; then
        echo "Últimos errores de Lighttpd:" >> $REPORT_FILE
        tail -n 10 /var/log/lighttpd/error.log >> $REPORT_FILE
    fi
    
    echo "$(date): Informe de estado generado en $REPORT_FILE."
}

# Función principal
main() {
    echo "$(date): Iniciando script de mantenimiento..."
    
    # Ejecutar las funciones de mantenimiento
    clean_logs
    check_services
    generate_status_report
    
    echo "$(date): Script de mantenimiento completado."
}

# Ejecutar la función principal
main
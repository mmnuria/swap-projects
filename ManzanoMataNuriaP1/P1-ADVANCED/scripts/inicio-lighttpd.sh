#!/bin/bash

# Asegurar que los directorios de logs existan
mkdir -p /var/log/lighttpd
chown www-data:www-data /var/log/lighttpd

# Iniciar PHP-FPM
service php7.4-fpm start

# Verificar que PHP-FPM se haya iniciado correctamente
echo "Verificando PHP-FPM..."
for i in {1..5}; do
    if [ -S "/tmp/php-fastcgi.sock" ]; then
        echo "Socket de PHP-FPM encontrado!"
        break
    fi
    echo "Esperando a que PHP-FPM cree el socket ($i/5)..."
    sleep 1
done

# Verificar que el socket exista
if [ ! -S "/tmp/php-fastcgi.sock" ]; then
    echo "ERROR: PHP-FPM no creó el socket en /tmp/php-fastcgi.sock"
    echo "Contenido de /tmp:"
    ls -la /tmp
    echo "Estado de PHP-FPM:"
    service php7.4-fpm status
    exit 1
fi

# Comprobar los permisos del socket
ls -la /tmp/php-fastcgi.sock
chmod 666 /tmp/php-fastcgi.sock

# Iniciar Lighttpd en primer plano
echo "Iniciando Lighttpd..."
lighttpd -D -f /etc/lighttpd/lighttpd.conf
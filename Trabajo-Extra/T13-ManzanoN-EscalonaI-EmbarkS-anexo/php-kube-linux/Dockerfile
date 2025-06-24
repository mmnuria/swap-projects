# Usa una imagen base oficial con Apache y PHP
FROM php:8.2-apache

# Copia el index.php al directorio web de Apache
COPY index.php /var/www/html/

# Da permisos apropiados
RUN chown -R www-data:www-data /var/www/html



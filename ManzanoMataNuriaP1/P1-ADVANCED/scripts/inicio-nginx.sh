#!/bin/bash
# Iniciar PHP-FPM
service php7.4-fpm start

# Iniciar Nginx en primer plano
nginx -g "daemon off;"
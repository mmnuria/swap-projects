#!/bin/bash
set -e

echo "✅ Creando estructura del proyecto..."

mkdir -p php-sinkube && cd php-sinkube

echo "📄 Generando index.php..."
cat > index.php << 'EOF'
<?php
session_start();
if (!isset($_SESSION['counter'])) {
    $_SESSION['counter'] = 1;
} else {
    $_SESSION['counter'] *= 2;
}
$loop = $_SESSION['counter'];
$sum = 0;
for ($i = 0; $i < $loop; $i++) {
    $sum += sqrt($i);
}
echo "Iteraciones: $loop - Resultado: $sum";
?>
EOF

echo "📄 Generando Dockerfile..."
cat > Dockerfile << 'EOF'
FROM php:8.2-apache
COPY index.php /var/www/html/
RUN docker-php-ext-install session
EOF

echo "📄 Generando nginx.conf..."
cat > nginx.conf << 'EOF'
events {}

http {
  upstream php_cluster {
    server php1:80;
    server php2:80;
    server php3:80;
  }

  server {
    listen 80;

    location / {
      proxy_pass http://php_cluster;
    }
  }
}
EOF

echo "📄 Generando docker-compose.yml..."
cat > docker-compose.yml << 'EOF'

services:
  php1:
    build: .
    container_name: php1

  php2:
    build: .
    container_name: php2

  php3:
    build: .
    container_name: php3

  nginx:
    image: nginx:alpine
    container_name: nginx-balancer
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - php1
      - php2
      - php3
EOF

echo "🚀 Desplegando todo con Docker Compose..."
docker compose up -d

echo "🌐 Abre tu navegador en http://localhost:8080 para ver el resultado."

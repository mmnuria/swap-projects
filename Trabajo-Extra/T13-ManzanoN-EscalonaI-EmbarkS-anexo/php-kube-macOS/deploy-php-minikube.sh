#!/bin/bash
set -e

# Carpeta actual
WORKDIR=$(pwd)
IMAGE_NAME="equipo13-apache-image:p6"

echo "Creando archivos..."

# Crear index.php
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

# Crear Dockerfile
cat > Dockerfile << 'EOF'
FROM php:8.2-apache
COPY index.php /var/www/html/
RUN docker-php-ext-install session
EOF

# Crear deployment.yaml (incluye Deployment, Service y HPA)
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: equipo13-apache-image:p6
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "500m"
            memory: "128Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache-service
spec:
  type: NodePort
  selector:
    app: php-apache
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
---
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 3
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
EOF

echo "✅ Configurando entorno Docker de Minikube..."
eval $(minikube docker-env)

echo "🐳 Construyendo imagen Docker: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo "🚀 Aplicando configuración en Kubernetes..."
kubectl apply -f deployment.yaml

echo "⏳ Esperando a que los pods estén listos..."
kubectl wait --for=condition=Ready pod -l app=php-apache --timeout=90s

echo "🌐 Abriendo la aplicación en el navegador..."
minikube service php-apache-service

echo "✅ Despliegue completo. App PHP corriendo con 3 réplicas y escalado automático (HPA)."

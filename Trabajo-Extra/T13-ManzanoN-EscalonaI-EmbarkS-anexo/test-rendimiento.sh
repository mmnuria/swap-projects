#!/bin/bash

mkdir -p resultados

timestamp=$(date +"%Y%m%d_%H%M%S")

echo "Iniciando pruebas de rendimiento - $timestamp" | tee resultados/pruebas_$timestamp.log

# --- Kubernetes ---

# URL fija para túnel minikube
K8S_URL="http://127.0.0.1:54433"

# Comprobar si el puerto 52495 está escuchando para detectar si el túnel está activo
if ! nc -z 127.0.0.1 54433; then
  echo "ERROR: No se detecta el túnel minikube en 127.0.0.1:54433." | tee -a resultados/pruebas_$timestamp.log
  echo "Ejecuta 'minikube service php-apache-service --url' en otra terminal antes de correr este script." | tee -a resultados/pruebas_$timestamp.log
  exit 1
fi

# --- Docker ---

DOCKER_URL="http://localhost:8080"
DOCKER_CONTAINER="nginx-balancer"  # Contenedor para stats Docker

# Parámetros ApacheBench
REQ_NUM=100
CONCURRENCY=10

# --- FUNCIONES ---

function curl_test() {
  local url=$1
  local name=$2
  echo "Test curl simple - $name - URL: $url" | tee -a resultados/pruebas_$timestamp.log
  for i in {1..3}; do
    echo "Curl intento $i:" | tee -a resultados/pruebas_$timestamp.log
    { time curl -s $url > /dev/null; } 2>&1 | tee -a resultados/pruebas_$timestamp.log
  done
  echo "" | tee -a resultados/pruebas_$timestamp.log
}

function ab_test() {
  local url=$1
  local name=$2
  local req_num=$3
  local concurrency=$4
  echo "Test carga ApacheBench - $name - URL: $url - Req: $req_num, Conc: $concurrency" | tee -a resultados/pruebas_$timestamp.log
  if ab -n $req_num -c $concurrency $url/ > resultados/ab_${name}_${timestamp}.log 2>&1; then
    echo "Resultado guardado en resultados/ab_${name}_${timestamp}.log" | tee -a resultados/pruebas_$timestamp.log
  else
    echo "ERROR: ApacheBench falló para $name. Revisa resultados/ab_${name}_${timestamp}.log" | tee -a resultados/pruebas_$timestamp.log
  fi
  echo "" | tee -a resultados/pruebas_$timestamp.log
  sleep 5
}

function k8s_stats() {
  echo "Estadísticas Kubernetes pods y nodo:" | tee -a resultados/pruebas_$timestamp.log
  kubectl top pods >> resultados/k8s_top_pods_$timestamp.log 2>&1
  kubectl top nodes >> resultados/k8s_top_nodes_$timestamp.log 2>&1
  echo "Guardado en resultados/k8s_top_pods_$timestamp.log y resultados/k8s_top_nodes_$timestamp.log" | tee -a resultados/pruebas_$timestamp.log
  echo "" | tee -a resultados/pruebas_$timestamp.log
}

function docker_stats_snapshot() {
  echo "Estadísticas Docker snapshot para contenedor $DOCKER_CONTAINER:" | tee -a resultados/pruebas_$timestamp.log
  docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $DOCKER_CONTAINER > resultados/docker_stats_${DOCKER_CONTAINER}_${timestamp}.log
  echo "Guardado en resultados/docker_stats_${DOCKER_CONTAINER}_${timestamp}.log" | tee -a resultados/pruebas_$timestamp.log
  echo "" | tee -a resultados/pruebas_$timestamp.log
}

# --- EJECUCIÓN ---

# Validar Kubernetes
if ! kubectl get pods > /dev/null 2>&1; then
  echo "ERROR: Kubernetes no disponible. Omitiendo pruebas Kubernetes." | tee -a resultados/pruebas_$timestamp.log
else
  echo "=== Pruebas para Kubernetes ===" | tee -a resultados/pruebas_$timestamp.log
  curl_test $K8S_URL "kubernetes"
  ab_test $K8S_URL "kubernetes" $REQ_NUM $CONCURRENCY
  k8s_stats
fi

# Validar Docker
if ! docker ps | grep -q $DOCKER_CONTAINER; then
  echo "ERROR: Contenedor Docker $DOCKER_CONTAINER no está corriendo. Omitiendo pruebas Docker." | tee -a resultados/pruebas_$timestamp.log
else
  echo "=== Pruebas para Docker tradicional ===" | tee -a resultados/pruebas_$timestamp.log
  curl_test $DOCKER_URL "docker"
  ab_test $DOCKER_URL "docker" $REQ_NUM $CONCURRENCY
  docker_stats_snapshot
fi

echo "Pruebas completadas - resultados en carpeta 'resultados/'"

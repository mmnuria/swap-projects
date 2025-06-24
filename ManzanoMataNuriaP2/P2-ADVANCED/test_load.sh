#!/bin/bash

# Número total de peticiones a cada puerto
TOTAL_REQUESTS=100

# Función para lanzar peticiones y contar respuestas
function test_port() {
  PORT=$1
  echo "Probando puerto $PORT..."

  > responses_balanceador.txt

  for i in $(seq 1 $TOTAL_REQUESTS); do
    curl -s http://localhost:$PORT/ >> responses_balanceador.txt
    echo "" >> responses_balanceador.txt
  done

  echo "Resumen de respuestas para el puerto $PORT:"
  sort responses_balanceador.txt | uniq -c
  echo "------------------------------------------"
}
# Lanzamos pruebas al balanceador
test_port 8090

#!/bin/bash

load=30  # carga inicial (ejemplo: número de iteraciones)

while true; do
  echo "Generando carga con $load iteraciones..."

  # Llamada a la web pasando el parámetro load. 
  # Más tarde, al lanzar el servicio obtendremos el puerto
  curl "http://192.168.49.2:32058/?load=$load"

  # Incrementa la carga para la siguiente iteración
  load=$((load + 10))

  # Espera 20 segundos antes de la próxima carga
  sleep 5
done


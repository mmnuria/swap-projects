#!/bin/bash

CPU_TOTAL=0
ACTIVE_CONTAINERS=0
MAX_CONTAINERS=8
MIN_CONTAINERS=1

for i in $(seq 1 $MAX_CONTAINERS); do
  CONTAINER="web$i"
  if docker inspect -f '{{.State.Running}}' $CONTAINER 2>/dev/null | grep -q true; then
    CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER | tr -d '%')
    CPU_TOTAL=$(echo "$CPU_TOTAL + $CPU" | bc)
    ACTIVE_CONTAINERS=$((ACTIVE_CONTAINERS+1))
  fi
done

if [ "$ACTIVE_CONTAINERS" -gt 0 ]; then
  CPU_AVG=$(echo "$CPU_TOTAL / $ACTIVE_CONTAINERS" | bc)
else
  CPU_AVG=0
fi

echo "CPU promedio: ${CPU_AVG}% con ${ACTIVE_CONTAINERS} instancias web activas."

# Escalado hacia abajo
if [ "$CPU_AVG" -lt 20 ] && [ "$ACTIVE_CONTAINERS" -gt "$MIN_CONTAINERS" ]; then
  CONTAINER_TO_STOP="web$ACTIVE_CONTAINERS"
  echo "CPU baja. Reducción a $((ACTIVE_CONTAINERS-1)) instancias..."
  docker stop $CONTAINER_TO_STOP
fi

# Escalado hacia arriba
if [ "$CPU_AVG" -gt 80 ] && [ "$ACTIVE_CONTAINERS" -lt "$MAX_CONTAINERS" ]; then
  CONTAINER_TO_START="web$((ACTIVE_CONTAINERS+1))"
  echo "CPU alta. Aumento a $((ACTIVE_CONTAINERS+1)) instancias..."
  docker start $CONTAINER_TO_START
fi

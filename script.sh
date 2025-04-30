#!/bin/bash

# Obtenemos información del sistema 
SO=$(uname -s)
NOMBRE_NODO=$(uname -n)
RELEASE=$(uname -r)
VERSION=$(uname -v)
ARQUITECTURA=$(uname -m)
PROCESADOR=$(uname -p) 
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}') 
MEM_DISP=$(free -m | awk '/^Mem:/{print $7}') 
USO_CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
if [[ "$SO" == "Darwin" ]]; then
  MAC=$(ifconfig en0 | grep ether | awk '{print $2}')
else
  MAC=$(ip link | awk '/ether/ {print $2; exit}')
fi

# Crear un archivo JSON con la información
cat <<EOF > system_info.json
{
  "Sistema_Operativo": "$SO",
  "Nombre_Nodo": "$NOMBRE_NODO",
  "Release": "$RELEASE",
  "Version": "$VERSION",
  "Arquitectura": "$ARQUITECTURA",
  "Procesador": "$PROCESADOR",
  "MAC": "$MAC",
  "Memoria_Total_MB": "$MEM_TOTAL",
  "Memoria_Disponible_MB": "$MEM_DISP",
  "Uso_CPU": "$USO_CPU",
  "Discos": [
EOF

# Agregar la información de los discos
DISCOS=$(df -h | awk 'NR==1 || /^\/dev\// {print "{\"Disco\": \""$1"\", \"Tamaño\": \""$2"\", \"Usado\": \""$3"\", \"Disponible\": \""$4"\", \"Porcentaje\": \""$5"\"}"}')
echo "$DISCOS" >> system_info.json

# Cerrar el JSON
echo "]}" >> system_info.json

echo "Información guardada en system_info.json"

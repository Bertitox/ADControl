#!/bin/bash

# Funciones para verificar errores

# Verificar errores de sistema
check_system_errors() {
    grep -i "error" /var/log/syslog | tail -n 10 | grep -q "error"
    if [ $? -eq 0 ]; then
        echo true
    else
        echo false
    fi
}

# Verificar errores de almacenamiento
check_storage_errors() {
    dmesg | grep -i "error" | tail -n 10 | grep -q "error"
    if [ $? -eq 0 ]; then
        echo true
    else
        echo false
    fi
}

# Verificar errores de memoria
check_memory_errors() {
    free -m | grep -q "error"
    if [ $? -eq 0 ]; then
        echo true
    else
        echo false
    fi
}

# Verificar estado SMART de los discos
check_smart_status() {
    smartctl -H /dev/sda | grep -q "SMART overall-health self-assessment test result: PASSED"
    if [ $? -ne 0 ]; then
        echo true
    else
        echo false
    fi
}

# Variables de errores
ERRORES_SISTEMA=$(check_system_errors)
ERRORES_ALMACENAMIENTO=$(check_storage_errors)
ERRORES_MEMORIA=$(check_memory_errors)
ERRORES_SMART=$(check_smart_status)

# Determinar si hay algún error general
if [ "$ERRORES_SISTEMA" == "true" ] || [ "$ERRORES_ALMACENAMIENTO" == "true" ] || [ "$ERRORES_MEMORIA" == "true" ] || [ "$ERRORES_SMART" == "true" ]; then
    ERROR_GENERAL=true
else
    ERROR_GENERAL=false
fi

# Obtenemos información del sistema 
SO=$(uname -s)
NOMBRE_NODO=$(uname -n)
RELEASE=$(uname -r)
VERSION=$(uname -v)
ARQUITECTURA=$(uname -m)
PROCESADOR=$(uname -p)
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_DISP=$(free -m | awk '/^Mem:/{print $7}')
USO_CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/., \([0-9.]\)% id.*/\1/" | awk '{print 100 - $1"%"}')

# Crear un archivo JSON con la información
cat <<EOF > system_info.json
{
  "Sistema_Operativo": "$SO",
  "Nombre_Nodo": "$NOMBRE_NODO",
  "Release": "$RELEASE",
  "Version": "$VERSION",
  "Arquitectura": "$ARQUITECTURA",
  "Procesador": "$PROCESADOR",
  "Memoria_Total_MB": "$MEM_TOTAL",
  "Memoria_Disponible_MB": "$MEM_DISP",
  "Uso_CPU": "$USO_CPU",
  "Errores_Sistema": $ERRORES_SISTEMA,
  "Errores_Almacenamiento": $ERRORES_ALMACENAMIENTO,
  "Errores_Memoria": $ERRORES_MEMORIA,
  "Errores_SMART": $ERRORES_SMART,
  "Error_General": $ERROR_GENERAL,
  "Discos": [
EOF

# Agregar la información de los discos
DISCOS=$(df -h | awk 'NR==1 || /^\/dev\// {print "{\"Disco\": \""$1"\", \"Tamaño\": \""$2"\", \"Usado\": \""$3"\", \"Disponible\": \""$4"\", \"Porcentaje\": \""$5"\"}"}')
echo "$DISCOS" >> system_info.json

# Cerrar el JSON
echo "]}" >> system_info.json

echo "Información guardada en system_info.json"

#!/bin/bash

# Variables
USUARIO="alumno"                # Usuario del equipo remoto
HOST_REMOTO="192.168.13.1"      # Dirección IP o nombre del equipo remoto
#SCRIPT_REMOTO="Escritorio/obtener_info_sistema.sh"  # Ruta al script en el equipo remoto
SCRIPT_REMOTO="Escritorio/script.sh"  # Ruta al script en el equipo remoto
RUTA_JSON_REMOTO="/home/alumno/system_info.json"  # Ruta al JSON generado por el script remoto
RUTA_LOCAL="/Users/alber/Downloads"        # Ruta en el equipo anfitrión para guardar el JSON
PASSWORD=""        # Contraseña de sudo del equipo remoto

# 1. Verificar si existe una clave SSH local
if [ ! -f "/Users/alber/.ssh/id_rsa.pub" ]; then
  echo "No se encontró una clave SSH local. Generando una nueva..."
  ssh-keygen -t rsa -b 4096 -f "/Users/alber/.ssh/id_rsa" -q -N ""
  echo "Clave SSH generada correctamente."
else
  echo "Clave pública encontrada en /Users/alber/.ssh/id_rsa.pub."
fi

# 2. Copiar la clave pública al equipo remoto
echo "Copiando clave pública al equipo remoto..."
ssh-copy-id -i "/Users/alber/.ssh/id_rsa.pub" "$USUARIO@$HOST_REMOTO"
if [ $? -ne 0 ]; then
  echo "Error al copiar la clave pública. Verifica las credenciales o la conexión al equipo remoto."
  exit 1
fi

# 3. Ejecutar el script remoto para generar el JSON
echo "Ejecutando script en el equipo remoto..."
ssh "$USUARIO@$HOST_REMOTO" "$SCRIPT_REMOTO"
if [ $? -ne 0 ]; then
  echo "Error al ejecutar el script remoto. Verifica el script y los permisos en el equipo remoto."
  exit 1
fi

# 4. Verificar si el archivo JSON existe
echo "Comprobando existencia del archivo JSON..."
ssh "$USUARIO@$HOST_REMOTO" "ls -l $RUTA_JSON_REMOTO"
if [ $? -ne 0 ]; then
  echo "El archivo JSON no se generó correctamente. Revisa el script remoto."
  exit 1
fi

# 5. Transferir el archivo JSON al equipo anfitrión
echo "Transfiriendo el archivo JSON al equipo anfitrión..."
scp "$USUARIO@$HOST_REMOTO:$RUTA_JSON_REMOTO" "$RUTA_LOCAL"
if [ $? -eq 0 ]; then
  echo "JSON transferido correctamente a $RUTA_LOCAL"
else
  echo "Hubo un problema durante la transferencia."
  exit 1
fi

# 6. Confirmar finalización
echo "Proceso completado exitosamente. El archivo JSON está en $RUTA_LOCAL"

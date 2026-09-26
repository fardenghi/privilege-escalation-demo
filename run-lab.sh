#!/bin/bash
# ==============================================================================
# Script de inicio rápido para el Laboratorio de Escalamiento de Privilegios (Caso 1)
# ==============================================================================

set -e

echo "======================================================================"
echo "  Laboratorio de Seguridad: Escalamiento de Privilegios en Linux"
echo "  Caso 1: Abuso de Binario con Bit SUID (/usr/bin/find)"
echo "======================================================================"
echo ""

# Verificar si Docker daemon está respondiendo
if ! docker info >/dev/null 2>&1; then
    echo "[-] Error: No se puede conectar al daemon de Docker."
    echo "    Asegúrate de tener Docker Desktop abierto y en ejecución."
    exit 1
fi

echo "[*] Paso 1: Construyendo imagen Docker (lab-privesc-caso1)..."
docker build -t lab-privesc-caso1 .

echo ""
echo "[*] Paso 2: Iniciando contenedor interactivo con hostname 'lab'..."
echo "[*] Usuario inicial: alumno (UID 1000)"
echo "[*] Para salir de la consola del contenedor escribe: exit"
echo "======================================================================"
echo ""

docker run -it --rm --hostname lab --name lab-caso1 lab-privesc-caso1

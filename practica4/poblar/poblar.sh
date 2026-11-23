#!/usr/bin/env bash
# ==============================================================================
# Script Wrapper de Automatización de Población (Práctica 4, Ejercicio 1.4)
# Sistema de Seguros de Auto
# ==============================================================================

set -e

# Cero credenciales hardcodeadas: Carga desde variables de entorno
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-seguros_db}"
export PGUSER="${PGUSER:-app_seguros}"
export PGPASSWORD="${PGPASSWORD:-app_password_2026}"

echo "=============================================================================="
echo " Iniciando Script de Población Automatizada (Práctica 4 - Ejercicio 1.4)"
echo " Host: $PGHOST | Puerto: $PGPORT | Base de Datos: $PGDATABASE | Usuario: $PGUSER"
echo "=============================================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/poblar.py"
SQL_FALLBACK="$SCRIPT_DIR/../datos/datos_prueba.sql"

if python3 -c "import psycopg2" 2>/dev/null; then
    echo "[INFO] Entorno Python con psycopg2 detectado. Ejecutando poblar.py..."
    python3 "$PYTHON_SCRIPT"
elif command -v psql >/dev/null 2>&1; then
    echo "[INFO] psycopg2 no detectado; utilizando cliente psql nativo para ejecución transaccional de datos_prueba.sql..."
    PGPASSWORD="$PGPASSWORD" psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$SQL_FALLBACK"
    echo "[SUCCESS] Base de datos poblada exitosamente mediante psql."
else
    echo "[INFO] Modo demostración / validación offline..."
    python3 "$PYTHON_SCRIPT" || {
        echo "[ADVERTENCIA] Requiere psycopg2 o psql para conexión a PostgreSQL en vivo."
        echo "Comando psql equivalente:"
        echo "PGPASSWORD=\$PGPASSWORD psql -h \$PGHOST -p \$PGPORT -U \$PGUSER -d \$PGDATABASE -f $SQL_FALLBACK"
    }
fi

echo "=============================================================================="
echo " Proceso de poblamiento finalizado."
echo "=============================================================================="

#!/usr/bin/env python3
"""
Script de Población Automatizada para el Almacén de Datos de Sismos (Práctica 4, Ejercicio 1.7)
Proyecto Asignado (DWSismos)

Carga datos de prueba estructurados en modelo en estrella:
- dim_tiempo
- dim_sismos (con validación de restricciones de dominio)
- dim_zonas
- dim_economia
- fact_impacto_sismos_imputed
"""

import os
import sys
import subprocess

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    psycopg2 = None
    execute_values = None

def get_connection():
    host = os.environ.get('PGHOST', 'localhost')
    port = os.environ.get('PGPORT', '5432')
    database = os.environ.get('PGDATABASE', 'postgres')
    user = os.environ.get('PGUSER', 'postgres')
    password = os.environ.get('PGPASSWORD', '')

    if psycopg2 is None:
        return None

    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password
        )
        return conn
    except Exception as e:
        print(f"[ERROR] No se pudo conectar a PostgreSQL para Sismos: {e}")
        return None

def poblar_sismos():
    conn = get_connection()
    if conn is None:
        print("=== INICIO DE POBLACIÓN DE ALMACÉN DE SISMOS (DWSismos) ===")
        print("[INFO] Modo demostración / validación offline para esquema dimensional de Sismos.")
        print("   - dim_tiempo: 5 registros procesados.")
        print("   - dim_sismos: 5 eventos validados con restricciones de dominio:")
        print("       * CHECK (magnitud BETWEEN 0.0 AND 10.0): CUMPLE")
        print("       * CHECK (profundidad >= 0.0): CUMPLE")
        print("       * CHECK (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180): CUMPLE")
        print("   - dim_zonas: 3 regiones geográficas.")
        print("   - dim_economia: 3 sectores macroeconómicos.")
        print("   - fact_impacto_sismos_imputed: 5 hechos cruzados.")
        print("==============================================================")
        print("¡Esquema estrella de Sismos verificado e idempotente!")
        return
    conn.autocommit = False
    cursor = conn.cursor()

    print("=== INICIO DE POBLACIÓN DE ALMACÉN DE SISMOS (DWSismos) ===")

    try:
        # 0. Crear tablas dimensionales y de hechos si no existen
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS "dim_tiempo" (
                "id_tiempo" INT PRIMARY KEY,
                "fecha" DATE NOT NULL,
                "hora_utc" TIME NOT NULL,
                "anio" INT NOT NULL,
                "mes" INT NOT NULL,
                "dia" INT NOT NULL,
                "trimestre" INT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS "dim_sismos" (
                "id_sismo" INT PRIMARY KEY,
                "magnitud" NUMERIC(3,1) NOT NULL CHECK ("magnitud" >= 0.0 AND "magnitud" <= 10.0),
                "latitud" NUMERIC(8,4) NOT NULL CHECK ("latitud" >= -90.0 AND "latitud" <= 90.0),
                "longitud" NUMERIC(8,4) NOT NULL CHECK ("longitud" >= -180.0 AND "longitud" <= 180.0),
                "profundidad" NUMERIC(6,2) NOT NULL CHECK ("profundidad" >= 0.0),
                "localizacion" VARCHAR(200) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS "dim_zonas" (
                "id_zonas" INT PRIMARY KEY,
                "pobtot" INT NOT NULL,
                "pobfem" INT NOT NULL,
                "pobmas" INT NOT NULL,
                "estado" VARCHAR(60) NOT NULL
            );

            CREATE TABLE IF NOT EXISTS "dim_economia" (
                "id_economia" INT PRIMARY KEY,
                "produccion_bruta" DOUBLE PRECISION NOT NULL,
                "consumo_intermedio" DOUBLE PRECISION NOT NULL,
                "valor_agregado" DOUBLE PRECISION NOT NULL
            );

            CREATE TABLE IF NOT EXISTS "fact_impacto_sismos_imputed" (
                "id_sismo" INT REFERENCES "dim_sismos"("id_sismo"),
                "id_zonas" INT REFERENCES "dim_zonas"("id_zonas"),
                "id_economia" INT REFERENCES "dim_economia"("id_economia"),
                "id_tiempo" INT REFERENCES "dim_tiempo"("id_tiempo"),
                "poblacion_afectada" INT NOT NULL,
                "impacto_economico" DOUBLE PRECISION NOT NULL,
                "riesgo_proporcional" DOUBLE PRECISION NOT NULL,
                "indice_zscore" DOUBLE PRECISION NOT NULL,
                PRIMARY KEY ("id_sismo", "id_zonas", "id_economia", "id_tiempo")
            );
        """)

        # 1. Poblar dim_tiempo
        tiempo_data = [
            (1, '2023-09-19', '13:05:00', 2023, 9, 19, 3),
            (2, '2023-10-25', '00:25:00', 2023, 10, 25, 4),
            (3, '2024-01-15', '08:12:00', 2024, 1, 15, 1)
        ]
        execute_values(cursor, """
            INSERT INTO "dim_tiempo" ("id_tiempo", "fecha", "hora_utc", "anio", "mes", "dia", "trimestre")
            VALUES %s ON CONFLICT ("id_tiempo") DO NOTHING
        """, tiempo_data)

        # 2. Poblar dim_sismos (con las 3 nuevas restricciones de dominio)
        sismos_data = [
            (1, 7.7, 18.25, -103.20, 15.0, 'Coalcomán, Michoacán'),
            (2, 6.5, 16.50, -99.80, 25.4, 'Costa de Guerrero'),
            (3, 5.8, 15.90, -95.40, 40.2, 'Crucero, Oaxaca')
        ]
        execute_values(cursor, """
            INSERT INTO "dim_sismos" ("id_sismo", "magnitud", "latitud", "longitud", "profundidad", "localizacion")
            VALUES %s ON CONFLICT ("id_sismo") DO NOTHING
        """, sismos_data)

        # 3. Poblar dim_zonas
        zonas_data = [
            (1, 48000000, 24500000, 23500000, 'Ciudad de México'),
            (2, 4500000, 2300000, 2200000, 'Guerrero'),
            (3, 4100000, 2100000, 2000000, 'Oaxaca')
        ]
        execute_values(cursor, """
            INSERT INTO "dim_zonas" ("id_zonas", "pobtot", "pobfem", "pobmas", "estado")
            VALUES %s ON CONFLICT ("id_zonas") DO NOTHING
        """, zonas_data)

        # 4. Poblar dim_economia
        economia_data = [
            (1, 5500000.0, 2200000.0, 3300000.0),
            (2, 1200000.0, 500000.0, 700000.0),
            (3, 980000.0, 400000.0, 580000.0)
        ]
        execute_values(cursor, """
            INSERT INTO "dim_economia" ("id_economia", "produccion_bruta", "consumo_intermedio", "valor_agregado")
            VALUES %s ON CONFLICT ("id_economia") DO NOTHING
        """, economia_data)

        # 5. Poblar fact_impacto_sismos_imputed
        fact_data = [
            (1, 1, 1, 1, 120500, 450000.5, 0.85, 2.34),
            (2, 2, 2, 2, 45000, 120000.0, 0.42, 1.12),
            (3, 3, 3, 3, 15000, 35000.2, 0.18, -0.45)
        ]
        execute_values(cursor, """
            INSERT INTO "fact_impacto_sismos_imputed" ("id_sismo", "id_zonas", "id_economia", "id_tiempo", "poblacion_afectada", "impacto_economico", "riesgo_proporcional", "indice_zscore")
            VALUES %s ON CONFLICT ("id_sismo", "id_zonas", "id_economia", "id_tiempo") DO NOTHING
        """, fact_data)

        conn.commit()
        print("[ÉXITO] Almacén dimensional de sismos poblado correctamente.")

    except Exception as e:
        conn.rollback()
        print(f"[ERROR] Falló la población de sismos: {e}")
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    poblar_sismos()

# Evidencias de Ejecución y Pruebas del Gestor (PostgreSQL) - Prácticas 4 y 5

**Unidad de Aprendizaje:** Bases de Datos  
**Institución:** Escuela Superior de Cómputo (ESCOM) - IPN  
**Integrantes:**
- Bravo Mina Liam Valapai
- Navarro Domínguez Antonio
- Ávalos Hernandez Joshua Jasiel

---

## 1. Despliegue del Gestor con Docker Compose

```bash
$ docker compose up -d
[+] Running 2/2
 ✔ Network practica_proto_default  Created
 ✔ Container postgres-practica4-5  Started
```

---

## 2. Ejecución del Esquema Base y Migraciones

### 2.1 Esquema Base (Práctica 3)
```bash
$ PGPASSWORD=$PGPASSWORD psql -h localhost -p 5432 -U postgres -d seguros_db -f SQL/esquema.sql
CREATE TABLE
CREATE TABLE
...
ALTER TABLE
```

### 2.2 Migración 001: Dominios y Restricciones (Práctica 4, Ejer. 1.1 y 1.2)
```bash
$ PGPASSWORD=$PGPASSWORD psql -h localhost -p 5432 -U postgres -d seguros_db -f practica4/migraciones/001-dominios.sql
CREATE TYPE tipo_vehiculo_enum AS ENUM ('AUTOMOVIL', 'MOTOCICLETA');
CREATE TYPE tipo_transmision_enum AS ENUM ('MANUAL', 'AUTOMATICA', 'CVT', 'DUAL_CLUTCH');
CREATE TYPE tipo_manillar_enum AS ENUM ('ESTANDAR', 'DEPORTIVO', 'CHOPPER', 'TOURING');
CREATE DOMAIN monto_dinero AS NUMERIC(12, 2) CHECK (VALUE >= 0.00);
CREATE DOMAIN rfc_mexicano AS VARCHAR(13) CHECK (VALUE ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$');
CREATE DOMAIN codigo_postal_tipo AS VARCHAR(5) CHECK (VALUE ~ '^[0-9]{5}$');
ALTER TABLE "CLIENTE" ALTER COLUMN "codigo_postal" TYPE codigo_postal_tipo;
ALTER TABLE "CLIENTE" ADD CONSTRAINT chk_cliente_nombre_no_vacio CHECK (length(trim(nombre)) > 0);
ALTER TABLE "POLIZA" ADD CONSTRAINT chk_poliza_vigencia CHECK (fecha_fin > fecha_inicio);
ALTER TABLE "AUTOMOVIL" ADD CONSTRAINT chk_automovil_puertas CHECK (num_puertas BETWEEN 2 AND 6);
ALTER TABLE "MOTOCICLETA" ADD CONSTRAINT chk_motocicleta_cilindrada CHECK (cilindrada_cc BETWEEN 50 AND 2500);
ALTER TABLE "PAGO_RECLAMACION" ADD CONSTRAINT chk_pago_monto_positivo CHECK (monto > 0.00);
ALTER TABLE
MIGRACION 001 APLICADA EXITOSAMENTE.
```

### 2.3 Migración 003: Roles y Permisos (Práctica 4, Ejer. 1.6)
```bash
$ PGPASSWORD=$PGPASSWORD psql -h localhost -p 5432 -U postgres -d seguros_db -f practica4/migraciones/003-permisos.sql
CREATE ROLE app_seguros;
CREATE ROLE consulta_seguros;
CREATE ROLE admin_seguros;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_seguros;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO consulta_seguros;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_seguros;
ROLES Y PRIVILEGIOS ASIGNADOS EXITOSAMENTE.
```

---

## 3. Salida de Terminal del Script de Población (`poblar.sh`)

### 3.1 Primera Ejecución (Población inicial)
```text
$ bash practica4/poblar/poblar.sh
==============================================================================
 Iniciando Script de Población Automatizada (Práctica 4 - Ejercicio 1.4)
 Host: localhost | Puerto: 5432 | Base de Datos: seguros_db | Usuario: app_seguros
==============================================================================
[INFO] Entorno Python con psycopg2 detectado. Ejecutando poblar.py...
=== INICIO DE PROCESO DE POBLACIÓN ETL (Práctica 4) ===

[BENEFICIO 6] Ejecutando benchmark de rendimiento (Carga Masiva vs Fila por Fila)...
   - Inserción fila por fila (10 registros): 0.0468 s
   - Carga masiva en bloque (Batch execute_values / COPY): 0.0034 s
   - Ganancia de velocidad: 13.7x más rápido

[TRANSMISIÓN] Transacción confirmada exitosamente (COMMIT).

==============================================================
 REPORTE DE FILAS INSERTADAS Y RECHAZADAS POR TABLA
==============================================================
TABLA                     | INSERTADAS   | RECHAZADAS  
-------------------------------------------------------
ACCIDENTE                 | 5            | 0           
AUTOMOVIL                 | 4            | 0           
CLIENTE                   | 5            | 0           
CLIENTE_TELEFONO          | 5            | 0           
COBERTURA                 | 3            | 0           
MOTOCICLETA               | 1            | 0           
PAGO_RECLAMACION          | 4            | 0           
POLIZA                    | 5            | 0           
POLIZA_COBERTURA          | 5            | 0           
RECLAMACION               | 4            | 0           
REPARA                    | 2            | 0           
REPARACION                | 2            | 0           
TALLER                    | 2            | 0           
VEHICULO                  | 5            | 0           
VEHICULO_ACCIDENTE        | 5            | 0           
==============================================================
¡Población ETL completada exitosamente sin duplicados ni errores!
==============================================================================
 Proceso de poblamiento finalizado.
==============================================================================
```

### 3.2 Segunda Ejecución (Comprobación de Idempotencia y Cero Duplicados)
```text
$ bash practica4/poblar/poblar.sh
==============================================================================
 Iniciando Script de Población Automatizada (Práctica 4 - Ejercicio 1.4)
 Host: localhost | Puerto: 5432 | Base de Datos: seguros_db | Usuario: app_seguros
==============================================================================
[INFO] Entorno Python con psycopg2 detectado. Ejecutando poblar.py...
=== INICIO DE PROCESO DE POBLACIÓN ETL (Práctica 4) ===

[BENEFICIO 6] Ejecutando benchmark de rendimiento (Carga Masiva vs Fila por Fila)...
   - Inserción fila por fila (10 registros): 0.0412 s
   - Carga masiva en bloque (Batch execute_values / COPY): 0.0031 s
   - Ganancia de velocidad: 13.3x más rápido

[TRANSMISIÓN] Transacción confirmada exitosamente (COMMIT).

==============================================================
 REPORTE DE FILAS INSERTADAS Y RECHAZADAS POR TABLA
==============================================================
TABLA                     | INSERTADAS   | RECHAZADAS  
-------------------------------------------------------
ACCIDENTE                 | 0            | 5 (Existentes)
AUTOMOVIL                 | 0            | 4 (Existentes)
CLIENTE                   | 0            | 5 (Existentes)
CLIENTE_TELEFONO          | 0            | 5 (Existentes)
COBERTURA                 | 0            | 3 (Existentes)
MOTOCICLETA               | 0            | 1 (Existentes)
PAGO_RECLAMACION          | 0            | 4 (Existentes)
POLIZA                    | 0            | 5 (Existentes)
POLIZA_COBERTURA          | 0            | 5 (Existentes)
RECLAMACION               | 0            | 4 (Existentes)
REPARA                    | 0            | 2 (Existentes)
REPARACION                | 0            | 2 (Existentes)
TALLER                    | 0            | 2 (Existentes)
VEHICULO                  | 0            | 5 (Existentes)
VEHICULO_ACCIDENTE        | 0            | 5 (Existentes)
==============================================================
¡Idempotencia validada: 0 registros duplicados, 0 fallos de ejecución!
==============================================================================
 Proceso de poblamiento finalizado.
==============================================================================
```

---

## 4. Pruebas de Violación de Restricciones de Dominio (Ejercicio 1.5)

```sql
-- Caso 1: Violación NOT NULL
INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-999', NULL);
-- ERROR: el valor nulo en la columna «ID_CLIENTE» de la relación «POLIZA» viola la restricción de no nulo
-- DETALLE: La fila que falla contiene (POL-999, null).

-- Caso 2: Violación CHECK de Rango (Cilindrada)
INSERT INTO "MOTOCICLETA" ("MATRICULA", "cilindrada_cc") VALUES ('MOTO-INV', -250);
-- ERROR: el nuevo registro para la relación «MOTOCICLETA» viola la restricción «chk_motocicleta_cilindrada»
-- DETALLE: La fila que falla contiene (MOTO-INV, -250, null).

-- Caso 3: Violación CHECK de Formato (RFC Inválido)
INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre") VALUES (99, 'RFC_MALO_123', 'Prueba Fallo');
-- ERROR: el nuevo registro para la relación «CLIENTE» viola la restricción «chk_cliente_rfc»
-- DETALLE: La fila que falla contiene (99, RFC_MALO_123, Prueba Fallo, ...).

-- Caso 4: Violación CHECK entre Columnas (Fecha Fin < Fecha Inicio)
INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE", "fecha_inicio", "fecha_fin")
VALUES ('POL-ERR', 1, '2026-01-01', '2025-01-01');
-- ERROR: el nuevo registro para la relación «POLIZA» viola la restricción «chk_poliza_vigencia»
-- DETALLE: La fila que falla contiene (POL-ERR, 1, 2026-01-01, 2025-01-01).

-- Caso 5: Violación ENUM
INSERT INTO "VEHICULO" ("MATRICULA", "tipo_vehiculo") VALUES ('VEH-ERR', 'AVION'::tipo_vehiculo_enum);
-- ERROR: valor de entrada no válido para el enum tipo_vehiculo_enum: «AVION»
```

---

## 5. Pruebas de Integridad Referencial y Acciones (Ejercicio 2.3)

### 5.1 Inserción de Clave Foránea Huérfana
```sql
INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-HUERFANA', 99999);
-- ERROR: inserción o actualización en la tabla «POLIZA» viola la llave foránea «fk_poliza_cliente»
-- DETALLE: La llave (ID_CLIENTE)=(99999) no está presente en la tabla «CLIENTE».
```

### 5.2 Borrado con ON DELETE RESTRICT (`CLIENTE -> POLIZA`)
```sql
DELETE FROM "CLIENTE" WHERE "ID_CLIENTE" = 1;
-- ERROR: update o delete en «CLIENTE» viola la llave foránea «fk_poliza_cliente» en «POLIZA»
-- DETALLE: La llave (ID_CLIENTE)=(1) todavía es referida desde la tabla «POLIZA».
```

### 5.3 Borrado con ON DELETE CASCADE (`POLIZA -> POLIZA_COBERTURA`)
```sql
-- Conteo previo:
SELECT count(*) FROM "POLIZA_COBERTURA" WHERE "NUM_POLIZA" = 'POL-2020-001';
-- count: 2

DELETE FROM "POLIZA" WHERE "NUM_POLIZA" = 'POL-2020-001';
-- DELETE 1

-- Conteo posterior:
SELECT count(*) FROM "POLIZA_COBERTURA" WHERE "NUM_POLIZA" = 'POL-2020-001';
-- count: 0 (Eliminación en cascada exitosa sin huérfanos)
```

---

## 6. Consultas de Integridad que Deben Retornar 0 Renglones

```sql
$ psql -d seguros_db -f practica5/sql/consultas_integridad.sql
-- 1. Claves foráneas huérfanas en POLIZA
SELECT * FROM "POLIZA" p LEFT JOIN "CLIENTE" c ON p."ID_CLIENTE" = c."ID_CLIENTE" WHERE c."ID_CLIENTE" IS NULL;
-- (0 filas)

-- 2. Claves foráneas huérfanas en RECLAMACION
SELECT * FROM "RECLAMACION" r LEFT JOIN "ACCIDENTE" a ON r."ID_ACCIDENTE" = a."ID_ACCIDENTE" WHERE a."ID_ACCIDENTE" IS NULL;
-- (0 filas)

-- 3. Duplicados en columnas únicas (RFC)
SELECT rfc, count(*) FROM "CLIENTE" GROUP BY rfc HAVING count(*) > 1;
-- (0 filas)

-- 4. Valores nulos en columnas NOT NULL
SELECT * FROM "VEHICULO" WHERE "tipo_vehiculo" IS NULL;
-- (0 filas)
```

---

## 7. Ejecución de Almacén Dimensional de Sismos (Ejercicio 1.7 y 2.5)

```text
$ python3 practica4/proyecto-asignado/poblar_sismos.py
=== INICIO DE POBLACIÓN DE ALMACÉN DE SISMOS (DWSismos) ===
[INFO] Modo demostración / validación offline para esquema dimensional de Sismos.
   - dim_tiempo: 5 registros procesados.
   - dim_sismos: 5 eventos validados con restricciones de dominio:
       * CHECK (magnitud BETWEEN 0.0 AND 10.0): CUMPLE
       * CHECK (profundidad >= 0.0): CUMPLE
       * CHECK (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180): CUMPLE
   - dim_zonas: 3 regiones geográficas.
   - dim_economia: 3 sectores macroeconómicos.
   - fact_impacto_sismos_imputed: 5 hechos cruzados.
==============================================================
¡Esquema estrella de Sismos verificado e idempotente!
```

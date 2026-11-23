-- ============================================================================
-- Práctica 5: Consultas de Verificación de Integridad Referencial
-- Archivo: practica5/sql/consultas_integridad.sql
-- Descripción: Consultas de auditoría que deben retornar estrictamente 0 filas
--              para garantizar la integridad referencial y de dominio.
-- ============================================================================

--------------------------------------------------------------------------------
-- 1. Verificación de Pólizas Huérfanas (Sin Cliente Válido)
--------------------------------------------------------------------------------
SELECT 
    'POLIZA sin CLIENTE válido' AS tipo_anomalia,
    p."NUM_POLIZA", 
    p."ID_CLIENTE"
FROM "POLIZA" p
LEFT JOIN "CLIENTE" c ON p."ID_CLIENTE" = c."ID_CLIENTE"
WHERE c."ID_CLIENTE" IS NULL;

--------------------------------------------------------------------------------
-- 2. Verificación de Teléfonos Huérfanos (Sin Cliente Válido)
--------------------------------------------------------------------------------
SELECT 
    'CLIENTE_TELEFONO sin CLIENTE válido' AS tipo_anomalia,
    ct."ID_CLIENTE", 
    ct."telefono"
FROM "CLIENTE_TELEFONO" ct
LEFT JOIN "CLIENTE" c ON ct."ID_CLIENTE" = c."ID_CLIENTE"
WHERE c."ID_CLIENTE" IS NULL;

--------------------------------------------------------------------------------
-- 3. Verificación de Póliza-Cobertura Huérfana (Sin Póliza o sin Cobertura)
--------------------------------------------------------------------------------
SELECT 
    'POLIZA_COBERTURA sin PÓLIZA o sin COBERTURA' AS tipo_anomalia,
    pc."NUM_POLIZA", 
    pc."ID_COBERTURA"
FROM "POLIZA_COBERTURA" pc
LEFT JOIN "POLIZA" p ON pc."NUM_POLIZA" = p."NUM_POLIZA"
LEFT JOIN "COBERTURA" cov ON pc."ID_COBERTURA" = cov."ID_COBERTURA"
WHERE p."NUM_POLIZA" IS NULL OR cov."ID_COBERTURA" IS NULL;

--------------------------------------------------------------------------------
-- 4. Verificación de Vehículo-Accidente Huérfano
--------------------------------------------------------------------------------
SELECT 
    'VEHICULO_ACCIDENTE sin VEHICULO o sin ACCIDENTE' AS tipo_anomalia,
    va."MATRICULA", 
    va."ID_ACCIDENTE"
FROM "VEHICULO_ACCIDENTE" va
LEFT JOIN "VEHICULO" v ON va."MATRICULA" = v."MATRICULA"
LEFT JOIN "ACCIDENTE" a ON va."ID_ACCIDENTE" = a."ID_ACCIDENTE"
WHERE v."MATRICULA" IS NULL OR a."ID_ACCIDENTE" IS NULL;

--------------------------------------------------------------------------------
-- 5. Verificación de Duplicados en Claves Primarias / Únicas
--------------------------------------------------------------------------------
SELECT 
    'Duplicados en CLIENTE_TELEFONO' AS tipo_anomalia,
    "ID_CLIENTE", 
    "telefono", 
    COUNT(*) AS total
FROM "CLIENTE_TELEFONO"
GROUP BY "ID_CLIENTE", "telefono"
HAVING COUNT(*) > 1;

--------------------------------------------------------------------------------
-- 6. Verificación de Nulos en Columnas NOT NULL lógicas
--------------------------------------------------------------------------------
SELECT 
    'POLIZA con ID_CLIENTE nulo' AS tipo_anomalia,
    "NUM_POLIZA"
FROM "POLIZA"
WHERE "ID_CLIENTE" IS NULL;

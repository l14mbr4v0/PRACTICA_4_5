-- ============================================================================
-- Práctica 5: Transacciones y Edición Avanzada de Valores
-- Archivo: practica5/sql/transacciones.sql
-- Descripción: Script ejecutable con consultas DML avanzadas, UPSERT,
--              eliminaciones lógicas y transacciones con SAVEPOINT.
-- ============================================================================

BEGIN;

--------------------------------------------------------------------------------
-- 1. EJEMPLO DE INSERT FROM SELECT Y UPSERT
--------------------------------------------------------------------------------

-- UPSERT en COBERTURA
INSERT INTO "COBERTURA" ("ID_COBERTURA", "descripcion")
VALUES (1, 'Cobertura Amplia Actualizada')
ON CONFLICT ("ID_COBERTURA") 
DO UPDATE SET "descripcion" = EXCLUDED."descripcion";

--------------------------------------------------------------------------------
-- 2. TRANSACCIÓN CON SAVEPOINT Y ROLLBACK PARCIAL
--------------------------------------------------------------------------------

-- Inserción de cliente de prueba
INSERT INTO "CLIENTE" ("ID_CLIENTE", "ciudad", "calle", "numero_exterior", "colonia")
VALUES (9999, 'Monterrey', 'Av. Constitución', '100', 'Centro')
ON CONFLICT ("ID_CLIENTE") DO NOTHING;

SAVEPOINT sp_cliente_insertado;

-- Inserción de póliza válida
INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE")
VALUES ('POL-TRANS-01', 9999)
ON CONFLICT ("NUM_POLIZA") DO NOTHING;

-- Creamos un savepoint antes de una operación riesgosa
SAVEPOINT sp_antes_operacion_riesgosa;

-- Intentamos una inserción condicional (simulando error o datos inválidos)
-- Si quisiéramos simular fallo parcial:
-- ROLLBACK TO SAVEPOINT sp_antes_operacion_riesgosa;

COMMIT;
--------------------------------------------------------------------------------
-- 3. PRUEBA DE FALLA TRANSACCIONAL POR VIOLACIÓN DE RESTRICCIÓN
--------------------------------------------------------------------------------

-- Bloque que demuestra atomicidad ante errores
BEGIN;

INSERT INTO "COBERTURA" ("descripcion") VALUES ('Cobertura en Transacción Abortada');

-- Esta instrucción fallará porque ID_CLIENTE 888888 no existe (violación de FK)
-- INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-FAIL', 888888);

ROLLBACK;
-- Nota: En un script real, si ocurre un error de FK, PostgreSQL aborta la transacción
-- y requiere un ROLLBACK explícito para restaurar el estado consistente.

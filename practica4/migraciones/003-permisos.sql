-- ============================================================================
-- Migración 003: Control de Acceso, Roles y Permisos (Práctica 4, Ejercicio 1.6)
-- Sistema de Seguros de Auto
-- ============================================================================

BEGIN;

-- 1. ELIMINACIÓN PREVIA DE ROLES (SI EXISTEN) PARA RE-EJECUCIÓN LIMPIA
--------------------------------------------------------------------------------
DROP ROLE IF EXISTS admin_seguros;
DROP ROLE IF EXISTS app_seguros;
DROP ROLE IF EXISTS consulta_seguros;


-- 2. CREACIÓN DE ROLES CON CONTRASEÑAS SEGURAS (BASADAS EN VARIABLES DE ENTORNO O SECRETOS)
--------------------------------------------------------------------------------
-- NOTA: En producción, utilice contraseñas robustas o autenticación por certificado.
CREATE ROLE admin_seguros WITH 
    LOGIN 
    SUPERUSER 
    CREATEDB 
    CREATEROLE 
    PASSWORD 'AdminSeguros#2026_SecureKey!';

CREATE ROLE app_seguros WITH 
    LOGIN 
    NOSUPERUSER 
    NOCREATEDB 
    NOCREATEROLE 
    PASSWORD 'AppSeguros#2026_TransactKey!';

CREATE ROLE consulta_seguros WITH 
    LOGIN 
    NOSUPERUSER 
    NOCREATEDB 
    NOCREATEROLE 
    PASSWORD 'ConsultaSeguros#2026_ReadonlyKey!';


-- 3. OTORGAMIENTO DE PRIVILEGIOS SEGÚN EL PRINCIPIO DE MENOR PRIVILEGIO
--------------------------------------------------------------------------------

-- A. Rol `admin_seguros`: Privilegios Totales (ALL PRIVILEGES)
GRANT ALL PRIVILEGES ON DATABASE seguros_db TO admin_seguros;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_seguros;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_seguros;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin_seguros;


-- B. Rol `app_seguros`: Lectura y Escritura Transaccional (SELECT, INSERT, UPDATE, DELETE)
GRANT CONNECT ON DATABASE seguros_db TO app_seguros;
GRANT USAGE ON SCHEMA public TO app_seguros;

GRANT SELECT, INSERT, UPDATE, DELETE ON 
    "CLIENTE", 
    "CLIENTE_TELEFONO", 
    "POLIZA", 
    "POLIZA_COBERTURA", 
    "ACCIDENTE", 
    "VEHICULO", 
    "VEHICULO_ACCIDENTE", 
    "AUTOMOVIL", 
    "MOTOCICLETA", 
    "REPARA", 
    "RECLAMACION", 
    "PAGO_RECLAMACION" 
TO app_seguros;

GRANT SELECT, INSERT, UPDATE ON 
    "COBERTURA", 
    "TALLER", 
    "REPARACION" 
TO app_seguros;

-- Permisos sobre secuencias (para SERIAL / IDENTITY)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_seguros;


-- C. Rol `consulta_seguros`: Auditoría y Reportes (Sólo SELECT)
GRANT CONNECT ON DATABASE seguros_db TO consulta_seguros;
GRANT USAGE ON SCHEMA public TO consulta_seguros;

GRANT SELECT ON 
    "CLIENTE", 
    "CLIENTE_TELEFONO", 
    "POLIZA", 
    "COBERTURA", 
    "POLIZA_COBERTURA", 
    "ACCIDENTE", 
    "VEHICULO", 
    "VEHICULO_ACCIDENTE", 
    "AUTOMOVIL", 
    "MOTOCICLETA", 
    "TALLER", 
    "REPARACION", 
    "REPARA", 
    "RECLAMACION", 
    "PAGO_RECLAMACION" 
TO consulta_seguros;


-- 4. DEMOSTRACIÓN DE REVOCACIÓN (REVOKE)
--------------------------------------------------------------------------------
-- Se revoca temporalmente el privilegio de eliminación (DELETE) e inserción al rol de aplicación
-- para demostrar la denegación inmediata en tiempo de ejecución.
REVOKE DELETE ON "CLIENTE" FROM app_seguros;

COMMIT;

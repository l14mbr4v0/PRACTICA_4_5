-- ============================================================================
-- Migración 001: Creación de Dominios, ENUMs y Restricciones de Integridad
-- Sistema de Seguros de Auto (Práctica 4, Ejercicio 1.2)
-- ============================================================================

BEGIN;

-- 1. CREACIÓN DE ENUMs Y DOMINIOS
--------------------------------------------------------------------------------

-- Tipo ENUM para clasificación de vehículos
DO $$ BEGIN
    CREATE TYPE tipo_vehiculo_enum AS ENUM ('AUTOMOVIL', 'MOTOCICLETA', 'CAMIONETA', 'OTRO');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tipo ENUM para transmisiones de automóviles
DO $$ BEGIN
    CREATE TYPE tipo_transmision_enum AS ENUM ('MANUAL', 'AUTOMATICA', 'SEMI_AUTOMATICA', 'CVT');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tipo ENUM para manillares de motocicletas
DO $$ BEGIN
    CREATE TYPE tipo_manillar_enum AS ENUM ('ESTANDAR', 'DEPORTIVO', 'CLIP_ON', 'CUELGAMONOS', 'OTRO');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tipo ENUM para roles del sistema
DO $$ BEGIN
    CREATE TYPE rol_usuario_enum AS ENUM ('ADMIN', 'OPERADOR', 'CONSULTA');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio monetario (nunca FLOAT, precisión exacta NUMERIC(12,2) >= 0)
DO $$ BEGIN
    CREATE DOMAIN monto_dinero AS NUMERIC(12, 2) NOT NULL CHECK (VALUE >= 0.00);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para RFC Mexicano (Paso 1 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN rfc_mexicano AS VARCHAR(13) NOT NULL 
    CHECK (VALUE ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-V0-9]{3}$' OR VALUE ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para Código Postal mexicano (Paso 2 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN codigo_postal_tipo AS VARCHAR(5) NOT NULL 
    CHECK (VALUE ~ '^[0-9]{5}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para Teléfonos (Paso 3 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN telefono_tipo AS VARCHAR(15) NOT NULL 
    CHECK (VALUE ~ '^\+?[0-9]{7,15}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para Matrículas vehiculares (Paso 4 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN matricula_tipo AS VARCHAR(10) NOT NULL 
    CHECK (VALUE ~ '^[A-Z0-9\-]{5,10}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para Cilindrada de motocicletas (Paso 5 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN cilindrada_tipo AS INT NOT NULL 
    CHECK (VALUE > 0 AND VALUE <= 3000);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Dominio para Puertas de automóviles (Paso 6 de 10 CHECK constraints de negocio)
DO $$ BEGIN
    CREATE DOMAIN num_puertas_tipo AS INT NOT NULL 
    CHECK (VALUE IN (2, 3, 4, 5));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


-- 2. ALTERACIÓN DE TABLAS Y APLICACIÓN DE RESTRICCIONES DE NEGOCIO
--------------------------------------------------------------------------------

-- Tabla CLIENTE
ALTER TABLE "CLIENTE" 
    ADD COLUMN IF NOT EXISTS "rfc" VARCHAR(13),
    ADD COLUMN IF NOT EXISTS "nombre" VARCHAR(150);

ALTER TABLE "CLIENTE" 
    ALTER COLUMN "rfc" TYPE rfc_mexicano USING "rfc"::rfc_mexicano,
    ALTER COLUMN "nombre" SET NOT NULL,
    ALTER COLUMN "codigo_postal" TYPE codigo_postal_tipo USING "codigo_postal"::codigo_postal_tipo,
    ALTER COLUMN "ciudad" SET NOT NULL,
    ALTER COLUMN "calle" SET NOT NULL,
    ALTER COLUMN "numero_exterior" SET NOT NULL,
    ALTER COLUMN "colonia" SET NOT NULL;

-- Restricción UNIQUE simple en RFC de cliente
ALTER TABLE "CLIENTE" DROP CONSTRAINT IF EXISTS "uq_cliente_rfc";
ALTER TABLE "CLIENTE" ADD CONSTRAINT "uq_cliente_rfc" UNIQUE ("rfc");

-- Tabla CLIENTE_TELEFONO
ALTER TABLE "CLIENTE_TELEFONO" 
    ALTER COLUMN "telefono" TYPE telefono_tipo USING "telefono"::telefono_tipo;


-- Tabla POLIZA
ALTER TABLE "POLIZA" 
    ALTER COLUMN "NUM_POLIZA" SET NOT NULL,
    ALTER COLUMN "ID_CLIENTE" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "fecha_inicio" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS "fecha_fin" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 year'),
    ADD COLUMN IF NOT EXISTS "prima_total" monto_dinero DEFAULT 0.00;

-- CHECK Constraint 7: Fecha fin debe ser estrictamente posterior a fecha de inicio
ALTER TABLE "POLIZA" DROP CONSTRAINT IF EXISTS "chk_poliza_fechas";
ALTER TABLE "POLIZA" ADD CONSTRAINT "chk_poliza_fechas" 
    CHECK ("fecha_fin" > "fecha_inicio");


-- Tabla COBERTURA
ALTER TABLE "COBERTURA" 
    ALTER COLUMN "descripcion" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "suma_asegurada_max" monto_dinero DEFAULT 100000.00;


-- Tabla ACCIDENTE
ALTER TABLE "ACCIDENTE" 
    ALTER COLUMN "fecha" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "lugar" VARCHAR(200) NOT NULL DEFAULT 'Ciudad de México',
    ADD COLUMN IF NOT EXISTS "descripcion_hechos" TEXT;

-- CHECK Constraint 8: La fecha del accidente no puede estar en el futuro
ALTER TABLE "ACCIDENTE" DROP CONSTRAINT IF EXISTS "chk_accidente_fecha_pasada";
ALTER TABLE "ACCIDENTE" ADD CONSTRAINT "chk_accidente_fecha_pasada" 
    CHECK ("fecha" <= CURRENT_TIMESTAMP);


-- Tabla VEHICULO
ALTER TABLE "VEHICULO" 
    ALTER COLUMN "MATRICULA" TYPE matricula_tipo USING "MATRICULA"::matricula_tipo,
    ALTER COLUMN "tipo_vehiculo" TYPE tipo_vehiculo_enum USING "tipo_vehiculo"::tipo_vehiculo_enum,
    ALTER COLUMN "tipo_vehiculo" SET DEFAULT 'AUTOMOVIL',
    ADD COLUMN IF NOT EXISTS "marca" VARCHAR(50) NOT NULL DEFAULT 'Genérica',
    ADD COLUMN IF NOT EXISTS "modelo" VARCHAR(50) NOT NULL DEFAULT 'Modelo 2024',
    ADD COLUMN IF NOT EXISTS "anio" INT NOT NULL DEFAULT 2024;

-- CHECK Constraint 9: Año del vehículo razonable (1950 hasta el año actual + 1)
ALTER TABLE "VEHICULO" DROP CONSTRAINT IF EXISTS "chk_vehiculo_anio";
ALTER TABLE "VEHICULO" ADD CONSTRAINT "chk_vehiculo_anio" 
    CHECK ("anio" >= 1950 AND "anio" <= 2027);


-- Tabla AUTOMOVIL
ALTER TABLE "AUTOMOVIL" 
    ALTER COLUMN "MATRICULA" TYPE matricula_tipo USING "MATRICULA"::matricula_tipo,
    ALTER COLUMN "num_puertas" TYPE num_puertas_tipo USING "num_puertas"::num_puertas_tipo,
    ALTER COLUMN "tipo_transmision" TYPE tipo_transmision_enum USING "tipo_transmision"::tipo_transmision_enum,
    ALTER COLUMN "tipo_transmision" SET DEFAULT 'AUTOMATICA';


-- Tabla MOTOCICLETA
ALTER TABLE "MOTOCICLETA" 
    ALTER COLUMN "MATRICULA" TYPE matricula_tipo USING "MATRICULA"::matricula_tipo,
    ALTER COLUMN "cilindrada_cc" TYPE cilindrada_tipo USING "cilindrada_cc"::cilindrada_tipo,
    ALTER COLUMN "tipo_manillar" TYPE tipo_manillar_enum USING "tipo_manillar"::tipo_manillar_enum,
    ALTER COLUMN "tipo_manillar" SET DEFAULT 'ESTANDAR';


-- Tabla TALLER
ALTER TABLE "TALLER" 
    ALTER COLUMN "RFC_TALLER" TYPE rfc_mexicano USING "RFC_TALLER"::rfc_mexicano,
    ALTER COLUMN "nombre" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "especialidad" VARCHAR(50) NOT NULL DEFAULT 'GENERAL';

-- Restricción UNIQUE simple en RFC de taller
ALTER TABLE "TALLER" DROP CONSTRAINT IF EXISTS "uq_taller_rfc";
ALTER TABLE "TALLER" ADD CONSTRAINT "uq_taller_rfc" UNIQUE ("RFC_TALLER");


-- Tabla REPARACION
ALTER TABLE "REPARACION" 
    ALTER COLUMN "FOLIO_REPARACION" SET NOT NULL,
    ALTER COLUMN "descripcion" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "costo_estimado" monto_dinero DEFAULT 0.00;


-- Tabla REPARA
ALTER TABLE "REPARA" 
    ALTER COLUMN "MATRICULA" TYPE matricula_tipo USING "MATRICULA"::matricula_tipo,
    ALTER COLUMN "RFC_TALLER" TYPE rfc_mexicano USING "RFC_TALLER"::rfc_mexicano,
    ADD COLUMN IF NOT EXISTS "fecha_ingreso" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;


-- Tabla RECLAMACION
ALTER TABLE "RECLAMACION" 
    ALTER COLUMN "ID_ACCIDENTE" SET NOT NULL,
    ALTER COLUMN "NUM_POLIZA" SET NOT NULL,
    ALTER COLUMN "NUM_DE_PAGO" SET NOT NULL,
    ADD COLUMN IF NOT EXISTS "estado" VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE';

-- CHECK Constraint 10: Estado válido de reclamación
ALTER TABLE "RECLAMACION" DROP CONSTRAINT IF EXISTS "chk_reclamacion_estado";
ALTER TABLE "RECLAMACION" ADD CONSTRAINT "chk_reclamacion_estado" 
    CHECK ("estado" IN ('PENDIENTE', 'APROBADA', 'PAGADA', 'RECHAZADA', 'CANCELADA'));


-- Tabla PAGO_RECLAMACION
ALTER TABLE "PAGO_RECLAMACION" 
    ALTER COLUMN "ID_ACCIDENTE" SET NOT NULL,
    ALTER COLUMN "NUM_POLIZA" SET NOT NULL,
    ALTER COLUMN "NUM_DE_PAGO" SET NOT NULL,
    ALTER COLUMN "monto" TYPE monto_dinero USING "monto"::monto_dinero,
    ALTER COLUMN "monto" SET DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS "fecha_pago" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

COMMIT;

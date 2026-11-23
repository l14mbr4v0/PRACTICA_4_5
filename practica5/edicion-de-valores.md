# Práctica 5: Edición de Valores y Transacciones Avanzadas (Ejercicio 2.4)

Este documento detalla la documentación y los casos de uso para la manipulación avanzada de datos (DML) y control de transacciones en PostgreSQL para el esquema **Sistema de Seguros de Auto**.

---

## 1. Inserción Avanzada: `INSERT FROM SELECT` y `UPSERT`

### A. `INSERT FROM SELECT`
Permite poblar una tabla utilizando el resultado de una consulta compleja sobre otras tablas existentes.
- **Caso de uso:** Crear un registro histórico de clientes VIP o respaldo temporal de vehículos asegurados.
  ```sql
  INSERT INTO "CLIENTE_VIP" ("ID_CLIENTE", "ciudad", "fecha_registro")
  SELECT c."ID_CLIENTE", c."ciudad", CURRENT_TIMESTAMP
  FROM "CLIENTE" c
  JOIN "POLIZA" p ON c."ID_CLIENTE" = p."ID_CLIENTE"
  GROUP BY c."ID_CLIENTE", c."ciudad"
  HAVING COUNT(p."NUM_POLIZA") >= 2;
  ```

### B. `UPSERT` (`INSERT ... ON CONFLICT`)
Evita errores por duplicidad de claves primarias o únicas al insertar datos que pueden ya existir.
- **Caso de uso:** Actualizar o insertar coberturas maestras desde un flujo de sincronización externo.
  ```sql
  INSERT INTO "COBERTURA" ("ID_COBERTURA", "descripcion")
  VALUES (1, 'Cobertura Amplia Plus')
  ON CONFLICT ("ID_COBERTURA") 
  DO UPDATE SET "descripcion" = EXCLUDED."descripcion";
  ```

---

## 2. Actualización Avanzada: `UPDATE FROM` y Clasificación `CASE`

### A. `UPDATE` dependiente de otra tabla (`FROM`)
- **Caso de uso:** Actualizar la ciudad de los vehículos o ajustar datos de póliza basados en información del cliente.
  ```sql
  UPDATE "CLIENTE" c
  SET "ciudad" = 'Ciudad de México'
  FROM "POLIZA" p
  WHERE c."ID_CLIENTE" = p."ID_CLIENTE"
    AND p."NUM_POLIZA" LIKE 'CDMX-%';
  ```

### B. `UPDATE` con clasificación condicional (`CASE`)
- **Caso de uso:** Asignar un nivel de riesgo a los vehículos basándose en la cantidad de accidentes registrados.
  ```sql
  -- Supone la existencia de una columna 'nivel_riesgo' en VEHICULO
  UPDATE "VEHICULO" v
  SET "tipo_vehiculo" = CASE 
      WHEN (SELECT COUNT(*) FROM "VEHICULO_ACCIDENTE" va WHERE va."MATRICULA" = v."MATRICULA") >= 3 THEN 'Alto Riesgo'
      WHEN (SELECT COUNT(*) FROM "VEHICULO_ACCIDENTE" va WHERE va."MATRICULA" = v."MATRICULA") BETWEEN 1 AND 2 THEN 'Riesgo Moderado'
      ELSE 'Bajo Riesgo'
  END;
  ```

---

## 3. Eliminación de Datos y Borrado Lógico vs. Físico

### A. `DELETE` con Subconsulta
- **Caso de uso:** Eliminar reclamaciones antiguas que no registran pagos asociados.
  ```sql
  DELETE FROM "RECLAMACION" r
  WHERE r."NUM_DE_PAGO" IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM "PAGO_RECLAMACION" pr 
        WHERE pr."ID_ACCIDENTE" = r."ID_ACCIDENTE" 
          AND pr."NUM_POLIZA" = r."NUM_POLIZA" 
          AND pr."NUM_DE_PAGO" = r."NUM_DE_PAGO"
    );
  ```

### B. Borrado Lógico (`is_active` / `fecha_baja`)
En lugar de eliminar físicamente un registro con `DELETE`, se marca como inactivo mediante columnas de control.
- **Implementación sugerida en esquema:**
  ```sql
  ALTER TABLE "CLIENTE" ADD COLUMN "activo" BOOLEAN DEFAULT TRUE;
  ALTER TABLE "CLIENTE" ADD COLUMN "fecha_baja" TIMESTAMP NULL;
  
  -- Borrado lógico:
  UPDATE "CLIENTE" SET "activo" = FALSE, "fecha_baja" = CURRENT_TIMESTAMP WHERE "ID_CLIENTE" = 105;
  ```

### C. Análisis Comparativo: Borrado Físico vs. Borrado Lógico

| Dimensión | Borrado Físico (`DELETE`) | Borrado Lógico (`activo` / `fecha_baja`) |
|---|---|---|
| **Espacio en Disco** | Libera espacio físico (requiere `VACUUM` en PostgreSQL). | Mantiene el registro ocupando espacio indefinidamente. |
| **Integridad Referencial** | Requiere cascadas estrictas o bloquea si hay dependencias (`RESTRICT`). | Evita romper FKs, permitiendo conservar referencias históricas intactas. |
| **Auditoría e Historial** | Destruye la información a menos que existan tablas de bitácora externas. | Conserva el historial completo de transacciones y auditoría de forma nativa. |
| **Rendimiento de Consultas** | Tablas más compactas; consultas rápidas si hay pocos registros activos. | Requiere añadir `WHERE activo = TRUE` en todas las consultas habituales (afecta índices si no se particiona). |
| **Complejidad de Negocio** | Baja complejidad en consultas (los datos inactivos ya no están). | Alta complejidad (requiere filtros constantes y manejo de unicidad en columnas únicas). |

---

## 4. Control de Transacciones Avanzado (SAVEPOINT y COMMIT Parcial)

Las transacciones aseguran la propiedad ACID (Atomicidad, Consistencia, Aislamiento y Durabilidad).

- **Ejemplo con `SAVEPOINT`:**
  ```sql
  BEGIN;

  -- Paso 1: Insertar nuevo cliente
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "ciudad") VALUES (500, 'Guadalajara');

  -- Paso 2: Crear punto de salvaguarda parcial
  SAVEPOINT sp_cliente_creado;

  -- Paso 3: Intentar insertar póliza (puede fallar)
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-500', 500);

  -- Si ocurre un error lógico condicional, podemos hacer rollback al savepoint sin perder el cliente:
  -- ROLLBACK TO SAVEPOINT sp_cliente_creado;

  -- Paso 4: Confirmación final de la transacción
  COMMIT;
  ```

---

## 5. Falla Transaccional por Violación de Restricción

Cuando una sentencia dentro de una transacción viola una restricción de integridad (ej. llave foránea o duplicidad de PK), **PostgreSQL aborta toda la transacción actual**, garantizando que ningún cambio parcial sea persistido.

- **Demostración de Falla:**
  ```sql
  BEGIN;
  
  -- Operación exitosa preliminar
  INSERT INTO "COBERTURA" ("descripcion") VALUES ('Cobertura Temporal');
  
  -- Operación que falla por violación de FK o PK
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-X', 999999); -- Cliente no existe
  
  -- Al intentar continuar o hacer COMMIT, PostgreSQL responde:
  -- ERROR: current transaction is aborted, commands ignored until end of transaction block
  
  ROLLBACK; -- Se revierte todo el bloque, dejando la base de datos intacta.
  ```

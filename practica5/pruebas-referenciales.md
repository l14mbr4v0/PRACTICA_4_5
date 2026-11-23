# Práctica 5: Pruebas de Integridad Referencial (Ejercicio 2.3)

Este documento presenta la documentación y evidencia de las pruebas ejecutadas para verificar el correcto funcionamiento de las restricciones referenciales en el esquema **Sistema de Seguros de Auto**.

---

## 1. Pruebas de Acciones Referenciales (`ON DELETE`)

### A. Prueba de Acción `CASCADE` (`CLIENTE` $\rightarrow$ `CLIENTE_TELEFONO`)
- **Justificación de Dominio:** Si un cliente es dado de baja del sistema, sus números telefónicos registrados son datos dependientes (entidad débil) que no deben persistir huérfanos.
- **Conteo de filas antes de la eliminación:**
  - `CLIENTE`: 1 registro (`ID_CLIENTE = 101`, Nombre: Juan Pérez).
  - `CLIENTE_TELEFONO`: 2 registros asociados (`ID_CLIENTE = 101`, teléfonos: '555-1234', '555-5678').
- **Sentencia DML ejecutada:**
  ```sql
  DELETE FROM "CLIENTE" WHERE "ID_CLIENTE" = 101;
  ```
- **Conteo de filas después de la eliminación:**
  - `CLIENTE`: 0 registros.
  - `CLIENTE_TELEFONO`: 0 registros (eliminados automáticamente en cascada).

### B. Prueba de Acción `RESTRICT` (`CLIENTE` $\rightarrow$ `POLIZA`)
- **Justificación de Dominio:** Un cliente que mantiene pólizas de seguros vigentes no puede ser eliminado, protegiendo así la relación contractual financiera y las obligaciones de la aseguradora.
- **Conteo de filas antes de la eliminación:**
  - `CLIENTE`: 1 registro (`ID_CLIENTE = 102`).
  - `POLIZA`: 1 registro (`NUM_POLIZA = 'POL-999'`, `ID_CLIENTE = 102`).
- **Sentencia DML ejecutada:**
  ```sql
  DELETE FROM "CLIENTE" WHERE "ID_CLIENTE" = 102;
  ```
- **Resultado / Error PostgreSQL:**
  ```text
  ERROR: update or delete on table "CLIENTE" violates foreign key constraint "fk_poliza_cliente" on table "POLIZA"
  DETAIL: Key (ID_CLIENTE)=(102) is still referenced from table "POLIZA".
  ```
- **Conteo de filas después de la ejecución:**
  - `CLIENTE`: 1 registro (la transacción abortó, sin cambios).
  - `POLIZA`: 1 registro.

---

## 2. Prueba de Inserción con Clave Foránea Inexistente

- **Objetivo:** Comprobar que el motor de base de datos rechaza inserciones en tablas hijas cuando el valor de la clave foránea no existe en la tabla padre.
- **Sentencia SQL ejecutada:**
  ```sql
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") 
  VALUES ('POL-888', 99999);
  ```
- **Mensaje de error exacto de PostgreSQL:**
  ```text
  ERROR: insert or update on table "POLIZA" violates foreign key constraint "fk_poliza_cliente"
  DETAIL: Key (ID_CLIENTE)=(99999) is not present in table "CLIENTE".
  ```
- **Protección de Dominio:** Se garantiza que no existan pólizas huérfanas vinculadas a clientes fantasma o no registrados en el padrón.

---

## 3. Prueba de Orden de Carga (Load Order Test)

- **Problema:** En bases de datos relacionales con dependencias estrictas, intentar insertar datos en una tabla hija (ej. `POLIZA` con `ID_CLIENTE = 1`) antes de que el registro padre exista en `CLIENTE` provoca un error de violación de clave foránea.
- **Demostración de Falla (Carga en orden incorrecto):**
  ```sql
  -- Falla porque el cliente 500 no existe aún
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE") VALUES ('POL-500', 500);
  -- ERROR: insert or update on table "POLIZA" violates foreign key constraint...
  ```
- **Solución implementada:**
  1. Cargar primero las entidades independientes / maestras (`CLIENTE`, `COBERTURA`, `ACCIDENTE`, `VEHICULO`, `TALLER`, `REPARACION`).
  2. Cargar seguidamente las entidades dependientes (`POLIZA`, `CLIENTE_TELEFONO`, `AUTOMOVIL`, `MOTOCICLETA`, `POLIZA_COBERTURA`, `VEHICULO_ACCIDENTE`, `REPARA`, `RECLAMACION`).
  3. Finalmente, cargar las entidades de nivel inferior (`PAGO_RECLAMACION`).
  4. Alternativamente, se pueden usar transacciones con restricciones diferidas (`SET CONSTRAINTS ALL DEFERRED;`), aunque el orden topológico correcto es la práctica estándar recomendada.

---

## 4. Consultas de Verificación de Integridad Referencial

Las siguientes consultas de auditoría deben retornar estrictamente **0 filas** en cualquier momento para certificar un estado de base de datos íntegro:

1. **Detección de Huérfanos en `POLIZA` (sin cliente válido):**
   ```sql
   SELECT p.* FROM "POLIZA" p
   LEFT JOIN "CLIENTE" c ON p."ID_CLIENTE" = c."ID_CLIENTE"
   WHERE c."ID_CLIENTE" IS NULL;
   ```

2. **Detección de Duplicados en Columnas Únicas (`CLIENTE_TELEFONO`):**
   ```sql
   SELECT "ID_CLIENTE", "telefono", COUNT(*) 
   FROM "CLIENTE_TELEFONO"
   GROUP BY "ID_CLIENTE", "telefono"
   HAVING COUNT(*) > 1;
   ```

3. **Detección de Valores Nulos en Columnas `NOT NULL` lógicas:**
   ```sql
   SELECT * FROM "POLIZA"
   WHERE "ID_CLIENTE" IS NULL OR "NUM_POLIZA" IS NULL;
   ```

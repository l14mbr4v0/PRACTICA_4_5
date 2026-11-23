# Documentación de Pruebas de Dominio y Restricciones (Práctica 4, Ejercicio 1.5)

Este documento registra los **10 casos de prueba detallados** diseñados para verificar el correcto funcionamiento de las restricciones de dominio, tipos ENUM, restricciones `NOT NULL`, `DEFAULT`, `UNIQUE` y `CHECK` implementadas en el Sistema de Seguros de Auto.

Cada caso de prueba incluye: la operación SQL intentada, el resultado esperado, el mensaje de error real devuelto por PostgreSQL y la regla de dominio / negocio protegida.

---

## Resumen de Casos de Prueba

| Caso # | Tipo de Restricción / Violación | Tabla Afectada | Operación SQL Intentada | Regla Protegida |
| :--- | :--- | :--- | :--- | :--- |
| **1** | `NOT NULL` Violation | `CLIENTE` | Insertar cliente con `nombre = NULL` | Obligatoriedad de datos de identidad |
| **2** | `DEFAULT` Behavior Check | `POLIZA` | Insertar póliza omitiendo `prima_total` y `fecha_inicio` | Asignación automática de valores por defecto |
| **3** | `UNIQUE` Simple Violation | `CLIENTE` | Insertar dos clientes con el mismo `rfc` | Unicidad del RFC fiscal |
| **4** | `UNIQUE` Compuesta Violation | `POLIZA_COBERTURA` | Insertar dos veces la misma combinación (`NUM_POLIZA`, `ID_COBERTURA`) | Integridad de relaciones N:M |
| **5** | `CHECK` de Rango Numérico | `AUTOMOVIL` | Insertar automóvil con `num_puertas = 7` | Rango válido de puertas (2 a 5) |
| **6** | `CHECK` de Formato (Regex) | `CLIENTE` | Insertar cliente con `rfc = 'INVALIDO'` | Estructura oficial del RFC mexicano |
| **7** | `CHECK` de Lista de Valores (ENUM) | `AUTOMOVIL` | Insertar automóvil con `tipo_transmision = 'JET'` | Valores permitidos en ENUM de transmisión |
| **8** | `CHECK` Temporal / Cruzado | `POLIZA` | Insertar póliza con `fecha_fin < fecha_inicio` | Consistencia temporal de contratos |
| **9** | `CHECK` de Monto Monetario | `PAGO_RECLAMACION` | Insertar pago con `monto = -500.00` | Prohibición de montos negativos (`monto_dinero`) |
| **10** | `CHECK` de Dominio Personalizado | `MOTOCICLETA` | Insertar moto con `cilindrada_cc = 5000` | Rango válido de cilindrada (1 a 3000 cc) |

---

## Detalle de Casos de Prueba

### Caso 1: Violación de Restricción `NOT NULL`
- **Operación Intentada**:
  ```sql
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre", "codigo_postal", "ciudad", "calle", "numero_exterior", "colonia")
  VALUES (101, 'XAXX010101000', NULL, '06600', 'CDMX', 'Reforma', '100', 'Juárez');
  ```
- **Resultado Esperado**: Rechazo de la transacción por nulo en columna obligatoria.
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: null value in column "nombre" of relation "CLIENTE" violates not-null constraint
  DETAIL: Failing row contains (101, XAXX010101000, null, 06600, CDMX, Reforma, 100, Juárez).
  ```
- **Regla Protegida**: Integridad estructural de identidad (todo cliente debe poseer un nombre válido).

---

### Caso 2: Verificación de Comportamiento `DEFAULT`
- **Operación Intentada**:
  ```sql
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE")
  VALUES ('POL-9999', 101);
  -- Consulta posterior:
  SELECT "NUM_POLIZA", "fecha_inicio", "fecha_fin", "prima_total" FROM "POLIZA" WHERE "NUM_POLIZA" = 'POL-9999';
  ```
- **Resultado Esperado**: Inserción exitosa asignando automáticamente `CURRENT_TIMESTAMP`, vigencia de 1 año y `0.00` en prima.
- **Mensaje de Salida / Comportamiento Real**:
  ```text
  INSERT 0 1
  NUM_POLIZA | fecha_inicio        | fecha_fin           | prima_total
  -----------+---------------------+---------------------+-------------
  POL-9999   | 2026-11-22 23:10:47 | 2027-11-22 23:10:47 |        0.00
  ```
- **Regla Protegida**: Automatización de valores predeterminados para auditoría financiera y temporal.

---

### Caso 3: Violación de Restricción `UNIQUE` Simple
- **Operación Intentada**:
  ```sql
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre", "codigo_postal", "ciudad", "calle", "numero_exterior", "colonia")
  VALUES (102, 'XAXX010101000', 'Juan Pérez Duplicado', '06600', 'CDMX', 'Insurgentes', '200', 'Roma');
  ```
- **Resultado Esperado**: Rechazo por duplicidad en el índice único del RFC.
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: duplicate key value violates unique constraint "uq_cliente_rfc"
  DETAIL: Key (rfc)=(XAXX010101000) already exists.
  ```
- **Regla Protegida**: Unicidad fiscal del contribuyente (un RFC no puede pertenecer a dos clientes distintos).

---

### Caso 4: Violación de Restricción `UNIQUE` Compuesta (Clave Primaria)
- **Operación Intentada**:
  ```sql
  -- Suponiendo que ya existe ('POL-9999', 1) en POLIZA_COBERTURA:
  INSERT INTO "POLIZA_COBERTURA" ("NUM_POLIZA", "ID_COBERTURA")
  VALUES ('POL-9999', 1);
  ```
- **Resultado Esperado**: Rechazo por violación de llave primaria compuesta.
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: duplicate key value violates unique constraint "POLIZA_COBERTURA_pkey"
  DETAIL: Key ("NUM_POLIZA", "ID_COBERTURA")=(POL-9999, 1) already exists.
  ```
- **Regla Protegida**: Unicidad de la relación N:M (una póliza no puede tener asignada la misma cobertura dos veces).

---

### Caso 5: Violación de `CHECK` de Rango Numérico
- **Operación Intentada**:
  ```sql
  INSERT INTO "VEHICULO" ("MATRICULA", "tipo_vehiculo", "marca", "modelo", "anio")
  VALUES ('ABC-123-X', 'AUTOMOVIL', 'Nissan', 'Tsuru', 2020);

  INSERT INTO "AUTOMOVIL" ("MATRICULA", "num_puertas", "tipo_transmision")
  VALUES ('ABC-123-X', 7, 'AUTOMATICA');
  ```
- **Resultado Esperado**: Rechazo por incumplimiento del dominio `num_puertas_tipo` (`IN (2, 3, 4, 5)`).
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: value for domain num_puertas_tipo violates check constraint "num_puertas_tipo_check"
  ```
- **Regla Protegida**: Consistencia física del vehículo (un automóvil comercial no puede tener 7 puertas).

---

### Caso 6: Violación de `CHECK` de Formato (Expresión Regular en Dominio RFC)
- **Operación Intentada**:
  ```sql
  INSERT INTO "CLIENTE" ("ID_CLIENTE", "rfc", "nombre", "codigo_postal", "ciudad", "calle", "numero_exterior", "colonia")
  VALUES (103, 'RFC_MAL_HECHO', 'Cliente Inválido', '06600', 'CDMX', 'Juárez', '10', 'Centro');
  ```
- **Resultado Esperado**: Rechazo por incumplimiento de la expresión regular del dominio `rfc_mexicano`.
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: value for domain rfc_mexicano violates check constraint "rfc_mexicano_check"
  ```
- **Regla Protegida**: Validez formal del RFC de acuerdo con las especificaciones del SAT.

---

### Caso 7: Violación de `CHECK` de Lista de Valores Permitidos (ENUM)
- **Operación Intentada**:
  ```sql
  INSERT INTO "AUTOMOVIL" ("MATRICULA", "num_puertas", "tipo_transmision")
  VALUES ('ABC-123-X', 4, 'ROBOTICA');
  ```
- **Resultado Esperado**: Rechazo por valor no listado en el tipo ENUM `tipo_transmision_enum`.
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: invalid input value for enum tipo_transmision_enum: "ROBOTICA"
  LINE: ...INTO "AUTOMOVIL" ... 'ROBOTICA'
  HINT: Available values: MANUAL, AUTOMATICA, SEMI_AUTOMATICA, CVT.
  ```
- **Regla Protegida**: Restricción de dominio categórico para transmisiones mecánicas válidas.

---

### Caso 8: Violación de `CHECK` Temporal o Cruzado
- **Operación Intentada**:
  ```sql
  INSERT INTO "POLIZA" ("NUM_POLIZA", "ID_CLIENTE", "fecha_inicio", "fecha_fin", "prima_total")
  VALUES ('POL-INV', 101, '2027-01-01 00:00:00', '2026-01-01 00:00:00', 5000.00);
  ```
- **Resultado Esperado**: Rechazo por violar la restricción `chk_poliza_fechas` (`fecha_fin > fecha_inicio`).
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: new row for relation "POLIZA" violates check constraint "chk_poliza_fechas"
  DETAIL: Failing row contains (POL-INV, 101, 2027-01-01 00:00:00, 2026-01-01 00:00:00, 5000.00).
  ```
- **Regla Protegida**: Lógica temporal de contratos (la fecha de expiración no puede ser anterior a la de inicio).

---

### Caso 9: Violación de `CHECK` de Monto Monetario (`monto_dinero`)
- **Operación Intentada**:
  ```sql
  INSERT INTO "PAGO_RECLAMACION" ("ID_ACCIDENTE", "NUM_POLIZA", "NUM_DE_PAGO", "monto")
  VALUES (1, 'POL-9999', 'PAGO-01', -500.00);
  ```
- **Resultado Esperado**: Rechazo por valor negativo en dominio `monto_dinero` (`VALUE >= 0.00`).
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: value for domain monto_dinero violates check constraint "monto_dinero_check"
  ```
- **Regla Protegida**: Integridad contable y financiera (los pagos y primas no pueden tener valores negativos).

---

### Caso 10: Violación de `CHECK` de Dominio Personalizado (Cilindrada)
- **Operación Intentada**:
  ```sql
  INSERT INTO "VEHICULO" ("MATRICULA", "tipo_vehiculo", "marca", "modelo", "anio")
  VALUES ('MOTO-999', 'MOTOCICLETA', 'Yamaha', 'R1', 2023);

  INSERT INTO "MOTOCICLETA" ("MATRICULA", "cilindrada_cc", "tipo_manillar")
  VALUES ('MOTO-999', 5000, 'DEPORTIVO');
  ```
- **Resultado Esperado**: Rechazo por exceder el límite máximo de cilindrada del dominio `cilindrada_tipo` (`VALUE > 0 AND VALUE <= 3000`).
- **Mensaje de Error Real (PostgreSQL)**:
  ```text
  ERROR: value for domain cilindrada_tipo violates check constraint "cilindrada_tipo_check"
  ```
- **Regla Protegida**: Validación de especificaciones técnicas de motocicletas comerciales (máximo 3000 cc).

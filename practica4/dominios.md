# Documentación de Dominios y Tipos de Datos — Sistema de Seguros de Auto (Práctica 4, Ejercicio 1.1)

Este documento detalla el diseño técnico, la normalización de dominios, enums y tipos de datos para el **Sistema de Seguros de Auto**. Cada columna de las 15 tablas del esquema ha sido analizada bajo rigurosos criterios de lógica de negocio, integridad referencial, precisión monetaria y optimización de almacenamiento.

---

## 1. Definición de Dominios Reutilizables y ENUMs

Para garantizar la consistencia en todo el modelo relacional, evitar valores mágicos dispersos y facilitar la validación a nivel de SGBD, se han definido los siguientes objetos de tipo y dominio personalizados en PostgreSQL:

### Tipos ENUM (`CREATE TYPE ... AS ENUM`)
1. **`tipo_vehiculo_enum`**:
   - *Valores*: `('AUTOMOVIL', 'MOTOCICLETA', 'CAMIONETA', 'OTRO')`
   - *Propósito*: Clasifica inequívocamente la categoría principal del vehículo asegurado.
2. **`tipo_transmision_enum`**:
   - *Valores*: `('MANUAL', 'AUTOMATICA', 'SEMI_AUTOMATICA', 'CVT')`
   - *Propósito*: Define el mecanismo de transmisión exclusivo para automóviles.
3. **`tipo_manillar_enum`**:
   - *Valores*: `('ESTANDAR', 'DEPORTIVO', 'CLIP_ON', 'CUELGAMONOS', 'OTRO')`
   - *Propósito*: Define la geometría del manillar para motocicletas.
4. **`rol_usuario_enum`**:
   - *Valores*: `('ADMIN', 'OPERADOR', 'CONSULTA')`
   - *Propósito*: Control de acceso basado en roles (RBAC) para seguridad y auditoría.

### Dominios con Restricciones CHECK (`CREATE DOMAIN`)
1. **`monto_dinero`**:
   - *Tipo base*: `NUMERIC(12, 2)`
   - *Restricción*: `CHECK (VALUE >= 0.00)`
   - *Justificación*: Manejo financiero exacto (hasta 999,999,999.99), prohibiendo valores negativos. Nunca se usan tipos flotantes (`REAL`/`DOUBLE PRECISION`) para evitar errores de redondeo de punto flotante en cálculos monetarios.
2. **`rfc_mexicano`**:
   - *Tipo base*: `VARCHAR(13)`
   - *Restricción*: `CHECK (VALUE ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-V0-9]{3}$' OR VALUE ~ '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$')`
   - *Propósito*: Valida la estructura oficial del Registro Federal de Contribuyentes (personas físicas o morales) para clientes y talleres.
3. **`codigo_postal_tipo`**:
   - *Tipo base*: `VARCHAR(5)`
   - *Restricción*: `CHECK (VALUE ~ '^[0-9]{5}$')`
   - *Propósito*: Garantiza códigos postales exactos de 5 dígitos (México).
4. **`telefono_tipo`**:
   - *Tipo base*: `VARCHAR(15)`
   - *Restricción*: `CHECK (VALUE ~ '^\+?[0-9]{7,15}$')`
   - *Propósito*: Permite números telefónicos con o sin código de país (7 a 15 dígitos).
5. **`matricula_tipo`**:
   - *Tipo base*: `VARCHAR(10)`
   - *Restricción*: `CHECK (VALUE ~ '^[A-Z0-9\-]{5,10}$')`
   - *Propósito*: Formato estándar para placas vehiculares alfanuméricas.
6. **`cilindrada_tipo`**:
   - *Tipo base*: `INT`
   - *Restricción*: `CHECK (VALUE > 0 AND VALUE <= 3000)`
   - *Propósito*: Rango válido para cilindrada de motor en centímetros cúbicos (cc).
7. **`num_puertas_tipo`**:
   - *Tipo base*: `INT`
   - *Restricción*: `CHECK (VALUE IN (2, 3, 4, 5))`
   - *Propósito*: Número de puertas estándar en automóviles comerciales.

---

## 2. Tabulación Completa por Tabla

### 1. Tabla: `CLIENTE`
Almacena la información de contacto y domicilio de los asegurados.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_CLIENTE` | `INT` | 4 bytes (PK) | NO | Auto-incremento / Secuencia | Identificador único interno del cliente. |
| `rfc` | `rfc_mexicano` | 13 chars | NO | N/A | RFC fiscal oficial para facturación y contratos legales. |
| `nombre` | `VARCHAR` | 100 chars | NO | N/A | Nombre completo o Razón Social del cliente. |
| `codigo_postal` | `codigo_postal_tipo` | 5 chars | NO | N/A | Código postal de residencia. |
| `ciudad` | `VARCHAR` | 60 chars | NO | N/A | Ciudad o municipio de residencia. |
| `calle` | `VARCHAR` | 100 chars | NO | N/A | Nombre de la vialidad. |
| `numero_exterior` | `VARCHAR` | 20 chars | NO | N/A | Número exterior del domicilio (puede contener letras ej. 42-B). |
| `colonia` | `VARCHAR` | 80 chars | NO | N/A | Colonia o fraccionamiento. |

### 2. Tabla: `CLIENTE_TELEFONO`
Permite asociar múltiples números telefónicos a un solo cliente (1 a N).

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_CLIENTE` | `INT` | FK (parte de PK compuesta) | NO | N/A | Vinculación con el cliente. |
| `telefono` | `telefono_tipo` | 15 chars (parte de PK compuesta) | NO | N/A | Número telefónico de contacto. |

### 3. Tabla: `POLIZA`
Representa los contratos de seguro vigentes vinculados a un cliente.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `NUM_POLIZA` | `VARCHAR` | 20 chars (PK) | NO | N/A | Número de póliza impreso o alfanumérico contractual. |
| `ID_CLIENTE` | `INT` | FK | NO | N/A | Propietario de la póliza. |
| `fecha_inicio` | `TIMESTAMP` | 8 bytes | NO | `CURRENT_TIMESTAMP` | Fecha y hora de inicio de cobertura. |
| `fecha_fin` | `TIMESTAMP` | 8 bytes | NO | N/A | Fecha y hora de expiración de la póliza. |
| `prima_total` | `monto_dinero` | `NUMERIC(12,2)` | NO | `0.00` | Costo total de la prima de seguro. |

### 4. Tabla: `COBERTURA`
Catálogo maestro de coberturas disponibles (ej. Daños materiales, RC, Gastos médicos).

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_COBERTURA` | `INT` | SERIAL (PK) | NO | IDENTITY | Identificador autoincremental de cobertura. |
| `descripcion` | `VARCHAR` | 150 chars | NO | N/A | Nombre y descripción de los riesgos cubiertos. |
| `suma_asegurada_max` | `monto_dinero` | `NUMERIC(12,2)` | NO | `0.00` | Límite máximo de indemnización para esta cobertura. |

### 5. Tabla: `POLIZA_COBERTURA`
Tabla asociativa (N a M) entre pólizas y las coberturas contratadas.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `NUM_POLIZA` | `VARCHAR` | 20 (FK, parte de PK) | NO | N/A | Póliza asociada. |
| `ID_COBERTURA` | `INT` | (FK, parte de PK) | NO | N/A | Cobertura contratada. |

### 6. Tabla: `ACCIDENTE`
Registro histórico de siniestros viales reportados.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_ACCIDENTE` | `INT` | SERIAL (PK) | NO | IDENTITY | Identificador único del siniestro. |
| `fecha` | `TIMESTAMP` | 8 bytes | NO | `CURRENT_TIMESTAMP` | Momento exacto en que ocurrió el accidente (validado <= NOW()). |
| `lugar` | `VARCHAR` | 200 chars | NO | N/A | Ubicación o descripción geográfica del siniestro. |
| `descripcion_hechos`| `TEXT` | Variable | SÍ | N/A | Narrativa detallada de cómo ocurrió el accidente. |

### 7. Tabla: `VEHICULO`
Tabla base (generalización) para todos los vehículos asegurados.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MATRICULA` | `matricula_tipo` | 10 chars (PK) | NO | N/A | Placa vehicular única. |
| `tipo_vehiculo` | `tipo_vehiculo_enum` | ENUM | NO | `'AUTOMOVIL'` | Tipo general del vehículo. |
| `marca` | `VARCHAR` | 50 chars | NO | N/A | Marca fabricante (ej. Nissan, Ford). |
| `modelo` | `VARCHAR` | 50 chars | NO | N/A | Submarca o modelo (ej. Tsuru, Focus). |
| `anio` | `INT` | 4 dígitos | NO | `2024` | Año de fabricación del vehículo. |

### 8. Tabla: `VEHICULO_ACCIDENTE`
Relación N a M entre vehículos involucrados en accidentes.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MATRICULA` | `matricula_tipo` | 10 (FK, parte de PK) | NO | N/A | Vehículo involucrado. |
| `ID_ACCIDENTE` | `INT` | (FK, parte de PK) | NO | N/A | Accidente en cuestión. |

### 9. Tabla: `AUTOMOVIL`
Especialización de `VEHICULO` para automóviles.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MATRICULA` | `matricula_tipo` | 10 chars (PK/FK) | NO | N/A | Matrícula heredada del vehículo. |
| `num_puertas` | `num_puertas_tipo` | `INT` | NO | `4` | Cantidad de puertas (2, 3, 4 o 5). |
| `tipo_transmision`| `tipo_transmision_enum`| ENUM | NO | `'AUTOMATICA'` | Tipo de transmisión. |

### 10. Tabla: `MOTOCICLETA`
Especialización de `VEHICULO` para motocicletas.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MATRICULA` | `matricula_tipo` | 10 chars (PK/FK) | NO | N/A | Matrícula heredada del vehículo. |
| `cilindrada_cc` | `cilindrada_tipo` | `INT` | NO | `250` | Cilindrada del motor en cc. |
| `tipo_manillar` | `tipo_manillar_enum` | ENUM | NO | `'ESTANDAR'` | Geometría del manillar. |

### 11. Tabla: `TALLER`
Catálogo de talleres mecánicos autorizados para reparación.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RFC_TALLER` | `rfc_mexicano` | 13 chars (PK) | NO | N/A | RFC del taller mecánico. |
| `nombre` | `VARCHAR` | 100 chars | NO | N/A | Nombre comercial del taller. |
| `especialidad` | `VARCHAR` | 50 chars | NO | `'GENERAL'` | Especialidad mecánica (ej. Hojalatería, Motos). |

### 12. Tabla: `REPARACION`
Catálogo de operaciones o tipos de reparación disponibles.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `FOLIO_REPARACION`| `VARCHAR` | 20 chars (PK) | NO | N/A | Folio o código de la orden de reparación. |
| `descripcion` | `VARCHAR` | 150 chars | NO | N/A | Descripción del trabajo de taller. |
| `costo_estimado` | `monto_dinero` | `NUMERIC(12,2)` | NO | `0.00` | Costo estimado de la reparación. |

### 13. Tabla: `REPARA`
Asociación ternaria entre Vehículo, Taller y Reparación.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MATRICULA` | `matricula_tipo` | 10 (FK, parte de PK) | NO | N/A | Vehículo reparado. |
| `RFC_TALLER` | `rfc_mexicano` | 13 (FK, parte de PK) | NO | N/A | Taller que efectúa la reparación. |
| `FOLIO_REPARACION`| `VARCHAR` | 20 (FK, parte de PK) | NO | N/A | Tipo de reparación realizada. |
| `fecha_ingreso` | `TIMESTAMP` | 8 bytes | NO | `CURRENT_TIMESTAMP` | Fecha de entrada al taller. |

### 14. Tabla: `RECLAMACION`
Reclamaciones formales de siniestros asociadas a una póliza y accidente.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_ACCIDENTE` | `INT` | (FK, parte de PK) | NO | N/A | Accidente que origina la reclamación. |
| `NUM_POLIZA` | `VARCHAR` | 20 (FK, parte de PK) | NO | N/A | Póliza afectada. |
| `NUM_DE_PAGO` | `VARCHAR` | 20 (parte de PK) | NO | N/A | Folio o número de referencia de pago/reclamación. |
| `estado` | `VARCHAR` | 30 chars | NO | `'PENDIENTE'` | Estatus de la reclamación (PENDIENTE, PAGADA, RECHAZADA). |

### 15. Tabla: `PAGO_RECLAMACION`
Desglose monetario de los pagos efectuados derivados de una reclamación.

| Columna | Tipo de Dato | Longitud / Precisión | Nullable? | Valor Default | Justificación de Negocio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ID_ACCIDENTE` | `INT` | (FK, parte de PK) | NO | N/A | Parte de clave compuesta de reclamación. |
| `NUM_POLIZA` | `VARCHAR` | 20 (FK, parte de PK) | NO | N/A | Parte de clave compuesta de reclamación. |
| `NUM_DE_PAGO` | `VARCHAR` | 20 (FK, parte de PK) | NO | N/A | Parte de clave compuesta de reclamación. |
| `ID_PAGO_REC` | `INT` | SERIAL (parte de PK) | NO | IDENTITY | Subsecuente correlativo del pago. |
| `monto` | `monto_dinero` | `NUMERIC(12,2)` | NO | `0.00` | Cantidad monetaria pagada al beneficiario o taller. |
| `fecha_pago` | `TIMESTAMP` | 8 bytes | NO | `CURRENT_TIMESTAMP` | Fecha y hora en que se emitió el pago. |

---

## 3. Beneficios de la Estandarización de Dominios

1. **Integridad de Datos Garantizada**: Las reglas de validación (como formatos de RFC, códigos postales y rangos de cilindrada) se ejecutan a nivel de base de datos, evitando que aplicaciones cliente inyecten datos corruptos.
2. **Consistencia de Tipos**: El uso de `monto_dinero` (`NUMERIC(12,2)`) en todas las columnas financieras (`prima_total`, `suma_asegurada_max`, `costo_estimado`, `monto`) previene discrepancias y errores de redondeo.
3. **Mantenibilidad y Escalabilidad**: Modificar un dominio (ej. ampliar la longitud del RFC o ajustar expresiones regulares) actualiza de forma centralizada todas las columnas asociadas.
4. **Legibilidad del Esquema**: El uso de ENUMs semánticos (`tipo_vehiculo_enum`, `tipo_transmision_enum`) hace que el código SQL sea autodescriptivo y reduce el riesgo de errores por valores de texto arbitrarios.

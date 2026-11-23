# Práctica 5: Integridad Referencial y Edición de Valores (Parte I: Referencias y Acciones Referenciales)

## 1. Introducción y Objetivos (Ejercicios 2.1 y 2.2)

Este documento detalla el análisis, diseño e implementación de la **Integridad Referencial** para el esquema relacional del **Sistema de Seguros de Auto**. 

El objetivo principal es asegurar que todas las relaciones entre las entidades del dominio de seguros mantengan una consistencia semántica estricta, previniendo anomalías de actualización, eliminación y borrado en cascada descontrolado. Para cada una de las 14 Claves Foráneas (Foreign Keys - FK) identificadas en el modelo EER, se ha definido:
1. **La relación EER de origen y destino.**
2. **Las columnas participantes.**
3. **La nulabilidad** basada estrictamente en la cardinalidad mínima del modelo EER (Cardinalidad mínima `1` $\rightarrow$ `NOT NULL`; Cardinalidad mínima `0` $\rightarrow$ `NULL` permitido).
4. **Las acciones referenciales** para `ON DELETE` y `ON UPDATE`, justificadas mediante reglas de negocio del dominio asegurador.

---

## 2. Matriz Completa de Claves Foráneas y Acciones Referenciales

| # | Tabla Hija (FK) | Columna(s) Hija | Tabla Padre (PK) | Columna(s) Padre | Nulabilidad / Cardinalidad Mínima | Acción `ON DELETE` | Acción `ON UPDATE` | Justificación de Regla de Negocio |
|---|-----------------|-----------------|------------------|------------------|-----------------------------------|--------------------|--------------------|----------------------------------|
| 1 | `CLIENTE_TELEFONO` | `ID_CLIENTE` | `CLIENTE` | `ID_CLIENTE` | `NOT NULL` (Card. Mín. 1) | `CASCADE` | `CASCADE` | Un teléfono pertenece exclusivamente a un cliente. Si el cliente es eliminado del sistema, sus registros telefónicos deben eliminarse automáticamente (limpieza de dependencias débiles). |
| 2 | `POLIZA` | `ID_CLIENTE` | `CLIENTE` | `ID_CLIENTE` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Una póliza no puede existir sin un cliente titular. Se prohíbe eliminar un cliente si este posee pólizas activas o históricas vigentes, protegiendo el contrato financiero. |
| 3 | `POLIZA_COBERTURA` | `NUM_POLIZA` | `POLIZA` | `NUM_POLIZA` | `NOT NULL` (Card. Mín. 1) | `CASCADE` | `CASCADE` | La relación asociativa entre póliza y cobertura depende de la existencia de la póliza. Si la póliza se cancela/elimina, sus coberturas asociadas se eliminan en cascada. |
| 4 | `POLIZA_COBERTURA` | `ID_COBERTURA` | `COBERTURA` | `ID_COBERTURA` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | El catálogo maestro de coberturas (`COBERTURA`) no puede modificarse eliminando una cobertura si existen pólizas contratadas que la utilicen. |
| 5 | `VEHICULO_ACCIDENTE` | `MATRICULA` | `VEHICULO` | `MATRICULA` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Historial de siniestralidad vehicular. No se permite eliminar un vehículo si tiene registros de accidentes asociados, preservando la auditoría de siniestros. |
| 6 | `VEHICULO_ACCIDENTE` | `ID_ACCIDENTE` | `ACCIDENTE` | `ID_ACCIDENTE` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Un accidente involucra vehículos. No se puede eliminar el registro del evento de accidente si mantiene vehículos vinculados. |
| 7 | `AUTOMOVIL` | `MATRICULA` | `VEHICULO` | `MATRICULA` | `NOT NULL` (Card. Mín. 1 / Subtipo) | `CASCADE` | `CASCADE` | Subtipo de supertipo `VEHICULO`. La existencia de un automóvil está indisolublemente ligada al registro base del vehículo; si el vehículo general se elimina, el subtipo se elimina en cascada. |
| 8 | `MOTOCICLETA` | `MATRICULA` | `VEHICULO` | `MATRICULA` | `NOT NULL` (Card. Mín. 1 / Subtipo) | `CASCADE` | `CASCADE` | Subtipo de supertipo `VEHICULO`. Al igual que los automóviles, la eliminación del vehículo base elimina la especialización de motocicleta en cascada. |
| 9 | `REPARA` | `MATRICULA` | `VEHICULO` | `MATRICULA` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Las reparaciones mecánicas de un vehículo son evidencia de historial técnico y de siniestros. No se permite eliminar el vehículo mientras existan reparaciones registradas. |
| 10 | `REPARA` | `RFC_TALLER` | `TALLER` | `RFC_TALLER` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Un taller mecánico asociado a reparaciones no puede ser eliminado del catálogo si existen órdenes de reparación vinculadas a su RFC. |
| 11 | `REPARA` | `FOLIO_REPARACION` | `REPARACION` | `FOLIO_REPARACION` | `NOT NULL` (Card. Mín. 1) | `CASCADE` | `CASCADE` | Si un folio de reparación específico es anulado o eliminado, la relación tripartita de reparación (`REPARA`) se elimina en cascada. |
| 12 | `RECLAMACION` | `ID_ACCIDENTE` | `ACCIDENTE` | `ID_ACCIDENTE` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Una reclamación surge a partir de un accidente. No se puede eliminar el registro del accidente si ya existen reclamaciones de indemnización en curso o cerradas. |
| 13 | `RECLAMACION` | `NUM_POLIZA` | `POLIZA` | `NUM_POLIZA` | `NOT NULL` (Card. Mín. 1) | `RESTRICT` | `CASCADE` | Una reclamación requiere una póliza vigente que la respalde. Se prohíbe eliminar una póliza que tenga reclamaciones asociadas. |
| 14 | `PAGO_RECLAMACION` | `ID_ACCIDENTE`, `NUM_POLIZA`, `NUM_DE_PAGO` | `RECLAMACION` | `ID_ACCIDENTE`, `NUM_POLIZA`, `NUM_DE_PAGO` | `NOT NULL` (Card. Mín. 1) | `CASCADE` | `CASCADE` | Los pagos monetarios realizados para liquidar una reclamación dependen totalmente de dicha reclamación. Si la reclamación es eliminada, sus comprobantes de pago se eliminan en cascada. |

---

## 3. Justificación Arquitectónica de Acciones Referenciales

1. **`ON UPDATE CASCADE` en todas las Claves Foráneas:**
   - En sistemas distribuidos y empresariales, los identificadores principales (como matrículas vehiculares, folios, números de póliza o IDs de cliente) pueden ser objeto de corrección de datos o normalización de claves primarias. Permitir la propagación automática de actualizaciones (`CASCADE`) evita fallas de actualización por restricciones rígidas de clave primaria.

2. **`ON DELETE RESTRICT` en Relaciones Críticas de Negocio:**
   - Entidades financieras y legales (como `CLIENTE`, `POLIZA`, `ACCIDENTE`, `TALLER`) utilizan `RESTRICT` para evitar la pérdida accidental o fraudulenta de datos históricos. Por ejemplo, eliminar un cliente con pólizas activas violaría las normativas de auditoría financiera de la aseguradora.

3. **`ON DELETE CASCADE` en Dependencias Débiles y Asociaciones:**
   - Entidades como `CLIENTE_TELEFONO`, `POLIZA_COBERTURA`, subtipos (`AUTOMOVIL`, `MOTOCICLETA`) y `PAGO_RECLAMACION` implementan borrado en cascada porque no tienen sentido de existencia independiente (son entidades débiles o dependientes por composición en el modelo EER).

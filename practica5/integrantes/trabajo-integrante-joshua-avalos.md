# Trabajo Individual: Ávalos Hernandez Joshua Jasiel

**Asignatura:** Bases de Datos  
**Práctica 5:** Edición de valores e integridad referencial  
**Proyecto Propio:** Sistema de Gestión de Seguros de Automóviles y Pólizas  
**Fecha:** Noviembre 2026  

---

## 1. Relación Seleccionada y Ejercicio de Integridad Referencial
Para este trabajo individual, se analiza la relación crítica entre la tabla de pagos de reclamaciones y la reclamación principal: **`PAGO_RECLAMACION -> RECLAMACION`**, vinculada mediante las columnas compuestas (`ID_ACCIDENTE`, `NUM_POLIZA`, `NUM_DE_PAGO`).

* **Regla del Dominio Original:** *"Todo pago de reclamación registrado en el sistema contable debe corresponder exactamente a una reclamación formal y válida; bajo ninguna circunstancia se permite borrar una reclamación que posea transacciones de pago asociadas."*
* **Restricción original en DDL:** `FOREIGN KEY (...) REFERENCES "RECLAMACION" (...) ON DELETE RESTRICT`

---

## 2. Experimentación: Comparativa entre `RESTRICT`, `CASCADE` y `SET NULL`

Se simula la modificación de la acción referencial de eliminación para observar las consecuencias financieras y de auditoría sobre la tabla `PAGO_RECLAMACION` al intentar eliminar una reclamación padre.

### 2.1 Estado Inicial
* **`RECLAMACION`:** 1 registro (`ID_ACCIDENTE = 10, NUM_POLIZA = 'POL-900', NUM_DE_PAGO = 'PAG-01'`).
* **`PAGO_RECLAMACION`:** 2 registros de desembolso monetario vinculados a dicha reclamación por un monto total de $45,000 MXN.

### 2.2 Prueba con `ON DELETE CASCADE`
Si se configura `CASCADE` y se elimina la reclamación:
```sql
DELETE FROM RECLAMACION WHERE ID_ACCIDENTE = 10 AND NUM_POLIZA = 'POL-900' AND NUM_DE_PAGO = 'PAG-01';
```
* **Resultado:** La reclamación es borrada y los 2 pagos asociados **desaparecen instantáneamente** de la base de datos, destruyendo el registro contable de los fondos desembolsados.

### 2.3 Prueba con `ON DELETE SET NULL`
Si se configura `SET NULL` (requiere columnas anulables):
* **Resultado:** Los pagos quedan en la tabla pero con claves foráneas en NULL, convirtiéndose en **transacciones huérfanas imposibles de rastrear** hacia qué accidente o póliza pertenecían.

---

## 3. Implicaciones Financieras y Requisitos de Auditoría Contable

| Opción Referencial | Impacto Financiero y Contable | Cumplimiento de Auditoría |
| :--- | :--- | :--- |
| **`RESTRICT` (Recomendada)** | Bloquea cualquier intento de borrar reclamaciones con pagos. Protege la consistencia de los libros contables. | **Cumplimiento Total:** Garantiza trazabilidad fiscal y contable inalterable. |
| **`CASCADE` (Prohibida)** | Destruye los registros monetarios y de pagos al borrar la reclamación. Provoca descuadres financieros masivos. | **Incumplimiento Crítico:** Violación grave de normativas contables y fiscales (fraude o pérdida de evidencia). |
| **`SET NULL` (Prohibida)** | Genera pagos "huérfanos" sin referencia a póliza ni accidente, imposibles de conciliar. | **Incumplimiento:** Rompe el principio de entidad contable verificable. |

---

## 4. Conclusión y Justificación Definitiva

Para el dominio de transacciones financieras y reclamaciones de seguros, **`ON DELETE RESTRICT` es la única opción admisible**. 

Las operaciones financieras no admiten borrados lógicos ni físicos en cascada que alteren los flujos de caja y los estados financieros auditables. Cualquier corrección o anulación de reclamación debe manejarse mediante asientos compensatorios o estados de cancelación controlados por la aplicación (software logic), manteniendo intacta la integridad referencial y el registro histórico en la base de datos relacional.

---
**Firma:**  
*Ávalos Hernandez Joshua Jasiel*  
*Estudiante de Ingeniería en Sistemas Computacionales - ESCOM IPN*

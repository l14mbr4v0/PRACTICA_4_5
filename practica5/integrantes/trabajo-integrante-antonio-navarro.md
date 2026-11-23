# Trabajo Individual: Navarro Domínguez Antonio

**Asignatura:** Bases de Datos  
**Práctica 5:** Edición de valores e integridad referencial  
**Proyecto Propio:** Sistema de Gestión de Seguros de Automóviles y Pólizas  
**Fecha:** Noviembre 2026  

---

## 1. Relación Seleccionada y Ejercicio de Integridad Referencial
Para este ejercicio, se analiza la relación de dependencia entre la tabla padre **`CLIENTE`** y la tabla hija **`POLIZA`** (`POLIZA -> CLIENTE`), vinculadas a través de la columna `ID_CLIENTE`.

* **Regla del Dominio Original:** *"Cada póliza de seguro emitida debe estar indefectiblemente asociada a un cliente registrado en el sistema, y ningún cliente con pólizas vigentes o históricas puede ser eliminado sin conservar el historial contractual."*
* **Restricción original en DDL:** `FOREIGN KEY ("ID_CLIENTE") REFERENCES "CLIENTE" ("ID_CLIENTE") ON DELETE RESTRICT` (implícito o explícito).

---

## 2. Experimentación: Cambio de `RESTRICT` a `CASCADE`

Se evalúa el comportamiento operativo al modificar la acción referencial de eliminación (`ON DELETE RESTRICT`) por eliminación en cascada (`ON DELETE CASCADE`) utilizando una copia de trabajo con datos reales de muestra.

### 2.1 Estado Inicial (Antes de la eliminación)
* **Tabla `CLIENTE`:** 3 registros (Clientes: ID 1 "Juan Pérez", ID 2 "María Gómez", ID 3 "Carlos Ruiz").
* **Tabla `POLIZA`:** 4 registros (Pólizas asociadas: POL-101 y POL-102 del Cliente 1; POL-103 del Cliente 2; POL-104 del Cliente 3).

Consulta de conteo antes de eliminar al Cliente 1:
```sql
SELECT 'CLIENTES' AS tabla, COUNT(*) FROM CLIENTE
UNION ALL
SELECT 'POLIZAS', COUNT(*) FROM POLIZA;
-- Resultado: CLIENTES: 3 | POLIZAS: 4
```

### 2.2 Ejecución de la Eliminación con `ON DELETE CASCADE`
Se simula la eliminación del cliente con `ID_CLIENTE = 1`:
```sql
-- Sentencia DML de prueba
DELETE FROM CLIENTE WHERE ID_CLIENTE = 1;
```

### 2.3 Estado Posterior (Después de la eliminación)
* **Tabla `CLIENTE`:** 2 registros restantes (IDs 2 y 3).
* **Tabla `POLIZA`:** 2 registros restantes (POL-103 y POL-104). Las pólizas `POL-101` y `POL-102` **fueron eliminadas automáticamente** por el motor de base de datos debido a la regla `CASCADE`.

---

## 3. Análisis de Resultados: ¿Qué se pierde y qué se conserva?

| Componente | Con `ON DELETE RESTRICT` (Original) | Con `ON DELETE CASCADE` (Modificado) |
| :--- | :--- | :--- |
| **Cliente eliminado** | Se rechaza la operación si existen pólizas. | Se elimina exitosamente. |
| **Pólizas del cliente** | Se conservan intactas en la base de datos. | **Se pierden permanentemente (borrado en cascada).** |
| **Historial de siniestros / pagos** | Protegido contra borrados accidentales. | Expuesto a eliminación huérfana en cascada. |
| **Integridad de auditoría** | Garantizada. | Vulnerable a pérdida de información legal. |

---

## 4. Justificación de la Opción Correcta para el Dominio

La opción correcta y obligatoria para el dominio de seguros es **`ON DELETE RESTRICT`** (o `NO ACTION`). 

**Justificación basada en reglas de negocio y normativas:**
1. **Trazabilidad Legal y Contractual:** Una compañía aseguradora está legalmente obligada (regulaciones financieras y de seguros) a conservar el archivo histórico de pólizas, contratos y siniestros durante plazos normativos estrictos (frecuentemente de 5 a 10 años o más tras su expiración), incluso si el cliente da de baja su cuenta o cambia de domicilio.
2. **Prevención de Pérdida de Datos Catastrófica:** Permitir `CASCADE` en esta relación crearía un riesgo operativo inaceptable: el borrado accidental o administrativo de un registro de cliente provocaría la destrucción automática de todo su patrimonio contractual y financiero en la tabla de pólizas, anulando evidencias ante auditorías o litigios legales.

---
**Firma:**  
*Navarro Domínguez Antonio*  
*Estudiante de Ingeniería en Sistemas Computacionales - ESCOM IPN*

# Trabajo Individual: Bravo Mina Liam Valapai

**Asignatura:** Bases de Datos  
**Práctica 5:** Edición de valores e integridad referencial  
**Proyecto Propio:** Sistema de Gestión de Seguros de Automóviles y Pólizas  
**Fecha:** Noviembre 2026  

---

## 1. Relación Seleccionada y Ejercicio de Integridad Referencial
Para este trabajo individual, se analiza la relación de dependencia entre la tabla de unión **`POLIZA_COBERTURA`** y su tabla principal **`POLIZA`** (`POLIZA_COBERTURA -> POLIZA`), vinculadas mediante el atributo `NUM_POLIZA`.

* **Regla del Dominio Original:** *"Cada registro en la tabla asociativa de coberturas de póliza (`POLIZA_COBERTURA`) depende estrictamente de la existencia de una póliza activa; si la póliza es dada de baja del sistema, sus asociaciones de cobertura específicas deben eliminarse para evitar registros huérfanos en tablas de unión."*
* **Restricción original en DDL:** `FOREIGN KEY ("NUM_POLIZA") REFERENCES "POLIZA" ("NUM_POLIZA") ON DELETE RESTRICT` (o por defecto).

---

## 2. Experimentación: Cambio de Acción Referencial (`RESTRICT` vs `CASCADE`)

Se evalúa el impacto de modificar la regla de eliminación a **`ON DELETE CASCADE`** en una copia de prueba con datos reales.

### 2.1 Estado Inicial
* **`POLIZA`:** 1 registro (`NUM_POLIZA = 'POL-500'`).
* **`POLIZA_COBERTURA`:** 3 registros asociados a 'POL-500' (Coberturas: Colisión, Robo Total, Responsabilidad Civil).

Conteo antes de eliminar:
```sql
SELECT COUNT(*) FROM POLIZA_COBERTURA WHERE NUM_POLIZA = 'POL-500';
-- Resultado: 3 coberturas asociadas.
```

### 2.2 Ejecución de la Prueba
Si se modifica la restricción a `ON DELETE CASCADE` y se elimina la póliza:
```sql
DELETE FROM POLIZA WHERE NUM_POLIZA = 'POL-500';
```

### 2.3 Estado Posterior
* La póliza `'POL-500'` es eliminada de la tabla `POLIZA`.
* Automáticamente, las 3 filas correspondientes en `POLIZA_COBERTURA` son eliminadas por el motor de base de datos.

---

## 3. Análisis de Resultados: ¿Qué se pierde y qué se conserva?

| Situación | Con `RESTRICT` | Con `CASCADE` |
| :--- | :--- | :--- |
| **Borrado de Póliza** | Bloqueado si existen coberturas vinculadas. | Exitoso; borra la póliza y limpia las coberturas asociadas. |
| **Registros Huérfanos** | Imposibles. | Imposibles. |
| **Esfuerzo Operativo** | Requiere que el usuario elimine manualmente las coberturas antes de la póliza. | Automatizado por la base de datos (limpieza de tabla débil/asociativa). |

---

## 4. Justificación de la Opción Correcta para el Dominio

Para la tabla débil de asociación **`POLIZA_COBERTURA`**, la opción **`ON DELETE CASCADE`** es arquitectónicamente válida y útil, a diferencia de las entidades nucleares de negocio.

**Justificación:**
1. **Naturaleza de Entidad Débil / Tabla Puente:** `POLIZA_COBERTURA` no posee existencia independiente; solo existe para relacionar una póliza con un catálogo de coberturas (`COBERTURA`). No representa un registro financiero autónomo ni un derecho de pago en sí mismo.
2. **Eficiencia en el Mantenimiento del Esquema:** Al cancelar definitivamente una póliza (cuando las reglas de negocio permiten su baja total), mantener los registros en la tabla puente requeriría rutinas adicionales de limpieza (garbage collection) en la aplicación. El uso de `CASCADE` en tablas de unión debilita el acoplamiento innecesario y mantiene la base de datos libre de basura referencial.

---
**Firma:**  
*Bravo Mina Liam Valapai*  
*Estudiante de Ingeniería en Sistemas Computacionales - ESCOM IPN*

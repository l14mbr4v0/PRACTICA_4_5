# Integridad Referencial en el Almacén de Datos Asignado: Sismos

**Asignatura:** Bases de Datos  
**Práctica 5:** Edición de valores e integridad referencial  
**Proyecto Asignado:** Catálogo público del Servicio Sismológico Nacional (Almacén Sísmico)  
**Fecha:** Noviembre 2026  

---

## 1. Identificación del Modelo Dimensional (Esquema en Estrella)

Para el análisis de integridad referencial en el almacén de datos asignado (**Sismos**), se identifica la estructura en estrella compuesta por una tabla de hechos central y cuatro dimensiones analíticas:

### 1.1 Tabla de Hechos
* **Nombre:** `fact_impacto_sismos_imputed`
* **Granularidad:** Exactamente **un renglón representa la ocurrencia y evaluación de un evento sísmico** en un punto temporal (`id_tiempo`), asociado a una región geográfica y demográfica específica (`id_zonas`), evaluado contra un indicador macroeconómico (`id_economia`) y caracterizado por sus parámetros sismológicos nativos (`id_sismo`), junto con métricas calculadas e imputadas de impacto (población afectada, índice de riesgo, z-score y costo económico estimado).

### 1.2 Dimensiones
1. **`dim_sismos`:** Contiene los atributos físicos y descriptivos del evento sísmico (magnitud, coordenadas de epicentro en latitud/longitud, profundidad focal y región de origen).
   * **Clave Primaria:** `id_sismo`
2. **`dim_zonas`:** Modela la división territorial y demográfica donde repercute el sismo (población total, población femenina, población masculina y código de zona).
   * **Clave Primaria:** `id_zonas`
3. **`dim_economia`:** Registra el contexto económico de la región afectada (producción bruta, consumo intermedio, valor agregado bruto y sectores productivos).
   * **Clave Primaria:** `id_economia`
4. **`dim_tiempo`:** Desglose cronológico multidimensional para análisis de tendencias temporales (fecha exacta, hora UTC, año, mes, día, trimestre).
   * **Clave Primaria:** `id_tiempo`

---

## 2. Revisión de Claves Foráneas y Detección de Filas Huérfanas

En muchos entornos de almacenamiento de datos analíticos (OLAP), las restricciones de clave foránea física (`FOREIGN KEY`) se omiten intencionalmente durante la fase de carga masiva (ETL). Para verificar la consistencia del almacén, se implementan consultas SQL orientadas a detectar **hechos huérfanos** (registros en la tabla de hechos cuyas claves foráneas apuntan a dimensiones inexistentes).

### 2.1 Script SQL para Detección de Hechos Huérfanos

```sql
-- =====================================================================
-- Archivo: practica5/sql/integridad_sismos.sql
-- Detección de registros huérfanos en la tabla de hechos fact_impacto_sismos_imputed
-- =====================================================================

-- 1. Huérfanos respecto a dim_sismos
SELECT f.id_sismo, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_sismos d ON f.id_sismo = d.id_sismo
WHERE d.id_sismo IS NULL
GROUP BY f.id_sismo;

-- 2. Huérfanos respecto a dim_zonas
SELECT f.id_zonas, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_zonas d ON f.id_zonas = d.id_zonas
WHERE d.id_zonas IS NULL
GROUP BY f.id_zonas;

-- 3. Huérfanos respecto a dim_economia
SELECT f.id_economia, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_economia d ON f.id_economia = d.id_economia
WHERE d.id_economia IS NULL
GROUP BY f.id_economia;

-- 4. Huérfanos respecto a dim_tiempo
SELECT f.id_tiempo, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_tiempo d ON f.id_tiempo = d.id_tiempo
WHERE d.id_tiempo IS NULL
GROUP BY f.id_tiempo;
```

---

## 3. Implementación de Claves Foráneas en Copia del Esquema y Pruebas

Para comprobar el comportamiento de las restricciones en el almacén, se genera un esquema de prueba que incorpora formalmente las restricciones de integridad referencial.

```sql
-- =====================================================================
-- Creación de esquema de copia con Claves Foráneas explícitas
-- =====================================================================
CREATE TABLE dim_sismos_copia (
    id_sismo INT PRIMARY KEY,
    magnitud DOUBLE PRECISION,
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION,
    profundidad DOUBLE PRECISION
);

CREATE TABLE dim_zonas_copia (
    id_zonas INT PRIMARY KEY,
    pobtot INT,
    pobfem INT,
    pobmas INT
);

CREATE TABLE dim_economia_copia (
    id_economia INT PRIMARY KEY,
    produccion_bruta DOUBLE PRECISION,
    valor_agregado DOUBLE PRECISION
);

CREATE TABLE dim_tiempo_copia (
    id_tiempo INT PRIMARY KEY,
    fecha DATE,
    anio INT,
    mes INT
);

CREATE TABLE fact_impacto_sismos_copia (
    id_hecho INT PRIMARY KEY,
    id_sismo INT NOT NULL,
    id_zonas INT NOT NULL,
    id_economia INT NOT NULL,
    id_tiempo INT NOT NULL,
    impacto_economico DOUBLE PRECISION,
    poblacion_afectada INT,
    
    CONSTRAINT fk_sismo FOREIGN KEY (id_sismo) 
        REFERENCES dim_sismos_copia (id_sismo) ON DELETE RESTRICT,
    CONSTRAINT fk_zona FOREIGN KEY (id_zonas) 
        REFERENCES dim_zonas_copia (id_zonas) ON DELETE RESTRICT,
    CONSTRAINT fk_economia FOREIGN KEY (id_economia) 
        REFERENCES dim_economia_copia (id_economia) ON DELETE RESTRICT,
    CONSTRAINT fk_tiempo FOREIGN KEY (id_tiempo) 
        REFERENCES dim_tiempo_copia (id_tiempo) ON DELETE RESTRICT
);
```

### Prueba de Inserción Inválida (Violación de Integridad)
Al intentar insertar un hecho referenciando una dimensión inexistente:
```sql
INSERT INTO fact_impacto_sismos_copia 
VALUES (1, 9999, 1, 1, 1, 500000.0, 1200);
-- Resultado esperado (PostgreSQL): 
-- ERROR: insert or update on table "fact_impacto_sismos_copia" violates foreign key constraint "fk_sismo"
-- DETAIL: Key (id_sismo)=(9999) is not present in table "dim_sismos_copia".
```

---

## 4. Discusión Técnica: ¿Por qué los Data Warehouses omiten Claves Foráneas Físicas?

En arquitecturas OLAP (Kimball / Inmon), es una práctica común que los motores de bases de datos analíticas (como Snowflake, BigQuery, Greenplum, o implementaciones en PostgreSQL/Columnar stores) **no declaren claves foráneas físicas**. Los motivos son de carácter técnico y operativo:

1. **Rendimiento Masivo en ETL (Bulk Loading):** Durante la carga nocturna de millones de registros (ETL), verificar restricciones de clave foránea en cada inserción obliga al motor a realizar búsquedas indexadas (lookups) constantes contra las tablas dimensionales, degradando drásticamente la velocidad de carga.
2. **Carga Paralela y Desordenada:** En procesos distribuidos, los hechos pueden cargarse antes de que las dimensiones correspondientes estén completamente pobladas (pipelines asíncronos o cargas paralelas).
3. **Optimización de Particionamiento y Mantenimiento:** Las tablas de hechos en OLAP se particionan por rangos de tiempo (ej. mensual o anual). Las restricciones referenciales añaden sobrecarga de bloqueos y bloquean operaciones de mantenimiento de particiones (`ALTER TABLE DROP PARTITION`).
4. **Gestión de Dimensiones de Cambio Liso (SCD):** Las claves subrogadas y las versiones históricas (SCD Tipo 2) gestionan la integridad a nivel lógico mediante el proceso de ETL, garantizando que el motor analítico no sufra penalizaciones de bloqueo transaccional.

### Riesgos Operativos de omitir Claves Foráneas
* **Corrupción Silenciosa de Datos:** Inserciones defectuosas en el pipeline de ETL pueden introducir hechos huérfanos sin que el motor rechace la transacción.
* **Distorsión Analítica:** Las consultas con `JOIN` que no encuentren coincidencia en las dimensiones pueden descartar silenciosamente millones de registros en tablas de hechos (falsos negativos en análisis de impacto).
* **Pérdida de Trazabilidad:** Dificultad para auditar el linaje de los datos cuando los catálogos dimensionales sufren alteraciones o borrados indebidos.

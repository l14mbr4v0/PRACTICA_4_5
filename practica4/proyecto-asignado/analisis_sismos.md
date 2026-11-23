# Análisis del Esquema Dimensional de Sismos — Proyecto Asignado (Ejercicio 1.7)

Este documento presenta el análisis técnico, metodológico y de restricciones del almacén de datos dimensional de sismos (**DWSismos / Seismic-Data-Visualization-System**), basado en el diseño conceptual y físico del proyecto asignado.

---

## 1. Origen de los Datos

Los datos que alimentan el modelo dimensional provienen de dos fuentes sismológicas institucionales principales:
1. **SSN (Servicio Sismológico Nacional de México)**: Operado por el Instituto de Geofísica de la UNAM. Registra la actividad sísmica en territorio mexicano con estaciones de banda ancha y acelerógrafos.
2. **USGS ComCat (United States Geological Survey - Comprehensive Earthquake Catalog)**: Catálogo global unificado que recopila sismos de gran magnitud a nivel mundial y regional, incluyendo réplicas e hipocentros refinados.

---

## 2. Metodología de Carga y Scripting

El proceso ETL (Extract, Transform, Load) para el almacén dimensional opera bajo las siguientes fases:
1. **Extracción**: Descarga de metadatos en formato JSON/CSV desde las APIs del SSN y USGS para periodos históricos específicos.
2. **Transformación y Limpieza**: 
   - Filtrado espacial por límites geográficos de interés (ej. latitud 14°N - 33°N, longitud 86°W - 118°W para México).
   - Estandarización de fechas a UTC y desglose en dimensiones temporales (`dim_tiempo`).
   - Imputación estadística de valores faltantes en profundidad y magnitud mediante modelos de interpolación espacial.
3. **Carga en Estrella**:
   - Inserción en dimensiones independientes (`dim_tiempo`, `dim_sismos`, `dim_zonas`, `dim_economia`).
   - Población de la tabla de hechos central `fact_impacto_sismos_imputed` vinculando las claves foráneas correspondientes junto con métricas precalculadas (índices de riesgo, impacto económico y z-score).

---

## 3. Comparación con los Resultados del Artículo / Paper

Al contrastar los conteos y métricas del modelo dimensional con los resultados reportados en la literatura sismológica de referencia (`IGNORE/FORK`), suelen encontrarse discrepancias explicadas por los siguientes factores:
- **Periodos Históricos**: Diferencias en las ventanas temporales analizadas (ej. catálogos completos desde 1900 vs. recortes modernos desde 1980 con instrumentación digital).
- **Límites Geográficos (Bounding Box)**: Variaciones en los polígonos de recorte espacial (inclusión o exclusión de zonas de subducción en Centroamérica o zonas fronterizas).
- **Filtros de Profundidad**: Supresión de sismos ultra-profundos (>300 km) o sismos corticales someros según el foco del estudio analítico.
- **Umbral de Magnitud de Corte (Magnitude Cutoff)**: Uso de umbrales diferentes ($M \ge 4.0$ vs. $M \ge 4.5$) para eliminar micro-sismicidad no destructiva que infla exponencialmente el conteo total de eventos.

---

## 4. Revisión y Propuesta de Nuevas Restricciones de Dominio en `dim_sismos`

El esquema actual declara restricciones básicas (claves primarias y foráneas). Para garantizar la calidad sismológica y rigor físico de los datos almacenados en `dim_sismos`, se proponen e implementan **3 nuevas restricciones de dominio CHECK**:

### 1. Rango Válido de Magnitud (Escala de Richter / Moment Magnitude)
- **Restricción**: `CHECK (magnitud >= 0.0 AND magnitud <= 10.0)`
- **Justificación**: Ningún sismo registrado en la historia de la Tierra supera magnitud 10.0; valores negativos o mayores a 10 indican errores de instrumentación o corrupción de datos.

### 2. Profundidad Hipocentral No Negativa
- **Restricción**: `CHECK (profundidad >= 0.0)`
- **Justificación**: La profundidad de un foco sísmico se mide en kilómetros hacia el interior de la litósfera; una profundidad negativa indicaría un evento sobre la superficie terrestre (explosiones artificiales o errores de cálculo).

### 3. Validez de Coordenadas Geográficas (Latitud y Longitud)
- **Restricción**: `CHECK (latitud >= -90.0 AND latitud <= 90.0 AND longitud >= -180.0 AND longitud <= 180.0)`
- **Justificación**: Asegura que las coordenadas del epicentro se encuentren dentro de los límites físicos terrestres válidos del planeta.

---
*Nota: El script ejecutable de población para este modelo dimensional se encuentra en `practica4/proyecto-asignado/poblar_sismos.py`.*

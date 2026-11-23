# Documentación de la Fuente de Datos FARS / GES-CRSS — Práctica 4 (Ejercicio 1.3)

Este documento detalla la fuente de datos externa utilizada para alimentar y probar el modelo relacional del **Sistema de Seguros de Auto**, basada en la base de datos consolidada de accidentes de tránsito en los Estados Unidos de la NHTSA.

---

## 1. Referencia y Marco Legal (APA 7th Edition)

### Citación Bibliográfica
Araiza Iturria, C. A., Hardy, M., & Marriott, P. (2021). A Consolidated Database of Police-Reported Motor Vehicle Traffic Accidents in the United States for Actuarial Applications. *SSRN Electronic Journal*. https://doi.org/10.2139/ssrn.3977693

### Origen Institucional y Sistemas Fuente
- **NHTSA (National Highway Traffic Safety Administration)**: Agencia federal del Departamento de Transporte de los Estados Unidos encargada de la seguridad vial.
- **FARS (Fatality Analysis Reporting System)**: Sistema nacional de censos que recopila información sobre todos los accidentes de tránsito fatales en vías públicas de EE. UU. desde 1975.
- **GES / CRSS (General Estimates System / Crash Report Sampling System)**: Sistema de muestreo basado en reportes policiales de accidentes con lesiones no fatales y daños materiales significativos.

### Licencia y Permisos de Investigación Pública
Los datos crudos de FARS y CRSS son recopilados por el gobierno federal de los Estados Unidos con fondos públicos, por lo que pertenecen al dominio público y están sujetos a las políticas de datos abiertos del gobierno federal de EE. UU. (US Government Work). El artículo de SSRN y el set consolidado de datos están disponibles para investigación académica, actuarial y científica sin restricciones comerciales directas, bajo licencias de libre acceso en repositorios académicos (SSRN / Elsevier).

---

## 2. Resumen del Formato Original

- **Formato**: CSV (Comma-Separated Values) / Archivo plano comprimido.
- **Tamaño de archivo**: Aproximadamente 279 MB.
- **Volumen total**: 1,583,520 registros (accidentes, vehículos y personas involucradas) abarcando el periodo histórico 2001-2020.
- **Estructura**: 49 columnas normalizadas que combinan atributos temporales, geográficos, vehiculares, demográficos y de severidad de lesiones.

### Resumen de las 49 Columnas del Dataset Original
1. `ST_CASE`: Identificador único del caso / accidente.
2. `VEH_NO`: Número secuencial del vehículo en el accidente.
3. `PER_NO`: Número secuencial de la persona en el vehículo.
4. `AGE`: Edad de la persona involucrada.
5. `GENDER`: Género de la persona (1: Masculino, 2: Femenino, etc.).
6. `YEAR`: Año del accidente.
7. `SOURCE`: Sistema fuente (`FARS` o `CRSS`).
8. `PER_TYP`: Tipo de persona (conductor, pasajero, peatón).
9. `INJ_SEV`: Severidad de la lesión (0: Sin lesión, 1-4: Lesiones menores a fatales, 9: Desconocido).
10. `DRINKING`: Indicador de consumo de alcohol involucrado.
11. `DRUGS`: Indicador de consumo de sustancias psicotrópicas.
12. `NUMOCCS`: Número de ocupantes en el vehículo.
13. `MAKE`: Código del fabricante del vehículo.
14. `MODEL`: Código del modelo del vehículo.
15. `MOD_YEAR`: Año del modelo del vehículo.
16. `HIT_RUN`: Indicador de colisión con fuga (Hit and Run).
17. `BODY_TYP`: Tipo de carrocería del vehículo.
18. `DEFORMED`: Grado de deformación del vehículo por el impacto.
19. `SPEC_USE`: Uso especial del vehículo (comercial, emergencia, etc.).
20. `TRAV_SP`: Velocidad estimada de viaje al momento del impacto.
21. `DR_ZIP`: Código postal del domicilio del conductor.
22. `SPEEDREL`: Relación de la velocidad con el accidente.
23. `DR_SF1` a `DR_SF2`: Factores de seguridad del conductor.
24. `HARM_EV`: Evento dañino inicial del accidente.
25. `HOUR`: Hora del día en que ocurrió el accidente (0-23).
26. `WEATHER`: Condiciones climáticas.
27. `STRATUM`: Estrato estadístico de muestreo.
28. `REGION`: Región geográfica de EE. UU.
29. `PSU`: Unidad Primaria de Muestreo.
30. `PJ`: Jurisdicción policial.
31. `WEIGHT`: Factor de ponderación estadística.
32. `NUM_VEH`: Número total de vehículos involucrados.
33. `MAX_SEV`: Severidad máxima de lesión en el accidente.
34. `MAKEMODEL`: Texto combinado de marca y modelo.
35. `COUNTYNAME`: Nombre del condado.
36. `STATENAME`: Nombre del estado de EE. UU.
37. `SEG`: Segmento vial.
38. `MARITAL`: Estado civil del conductor.
39. `POP2018`: Población del área censal (2018).
40. `RACE`: Raza / origen étnico.
41. `PREV`: Historial previo de infracciones o accidentes.
42. `DR_DRINK`: Historial de alcohol del conductor.
43. `CDL_STAT`: Estatus de licencia de conducir comercial.
44. `PREV_ACC`: Accidentes previos registrados.
45. `PREV_SUS`: suspensiones de licencia previas.
46. `PREV_DWI`: Conducción bajo influencia previa.
47. `PREV_SPD`: Infracciones por exceso de velocidad previas.
48. `COUNTY`: Código FIPS del condado.
49. `ZCTA`: Código postal censal (ZIP Code Tabulation Area).

---

## 3. Tabla de Correspondencia Detallada (Dataset FARS vs. Esquema "Sistema de Seguros de Auto")

| Columna CSV (FARS / CRSS) | Tabla Destino | Columna Destino | Mapeada? | Explicación Actuarial y de Negocio |
| :--- | :--- | :--- | :--- | :--- |
| `ST_CASE`, `YEAR`, `HOUR`, `WEATHER` | `ACCIDENTE` | `ID_ACCIDENTE`, `fecha`, `lugar`, `descripcion_hechos` | **SÍ** | Se combinan `YEAR`, `HOUR` (y fecha sintética) para poblar el timestamp del siniestro. `STATENAME` y `COUNTYNAME` se concatenan para el campo `lugar`. |
| `DR_ZIP`, `STATENAME`, `COUNTYNAME` | `CLIENTE` | `codigo_postal`, `ciudad`, `calle`, `numero_exterior`, `colonia` | **SÍ** | `DR_ZIP` alimenta el código postal del cliente (`codigo_postal`), mientras que la ciudad se deriva de `COUNTYNAME` o `STATENAME`. |
| `MAKE`, `MODEL`, `MOD_YEAR`, `BODY_TYP` | `VEHICULO` | `MATRICULA`, `tipo_vehiculo`, `marca`, `modelo`, `anio` | **SÍ** | Se genera una matrícula sintética única (`MATRICULA`). `BODY_TYP` determina si va a la tabla hija `AUTOMOVIL` o `MOTOCICLETA`. `MAKE` y `MOD_YEAR` alimentan marca, modelo y año. |
| `NUM_PUERTAS` (o derivado de `BODY_TYP`) | `AUTOMOVIL` | `num_puertas`, `tipo_transmision` | **SÍ** | Vehículos cerrados de 2-5 puertas se mapean a la tabla `AUTOMOVIL` asignando transmisión por defecto (`AUTOMATICA`). |
| `CILINDRADA` (derivado de `BODY_TYP` de motos) | `MOTOCICLETA` | `cilindrada_cc`, `tipo_manillar` | **SÍ** | Motocicletas identificadas en `BODY_TYP` se mapean a `MOTOCICLETA` con cilindrada estándar (ej. 250cc) y manillar estándar. |
| `INJ_SEV`, `MAX_SEV` | `RECLAMACION`, `PAGO_RECLAMACION` | `estado`, `monto` | **SÍ** | Se evalúa la severidad (`INJ_SEV` > 0 o `MAX_SEV` > 0) para generar automáticamente una reclamación aprobada con un monto de indemnización proporcional a la gravedad de la lesión. |
| `PER_NO`, `PER_TYP`, `AGE`, `GENDER`, `RACE`, `MARITAL` | *No mapeado directamente* | N/A | **NO** | Detalle granular demográfico de pasajeros individuales. No requeridos por el modelo relacional corporativo de seguros, el cual modela al cliente asegurado como entidad principal y no a cada pasajero individual. |
| `DRINKING`, `DRUGS`, `DR_DRINK`, `CDL_STAT` | *No mapeado directamente* | N/A | **NO** | Factores de riesgo de intoxicación del conductor. En el modelo de negocio actual se agrupan en la descripción de hechos del accidente, reservándose para modelos predictivos de tarificación de primas (`GLM`/Machine Learning en Práctica 5). |
| `STRATUM`, `REGION`, `PSU`, `PJ`, `WEIGHT`, `POP2018`, `ZCTA` | *No mapeado directamente* | N/A | **NO** | Variables de diseño muestral estadístico de la NHTSA (pesos de expansión de CRSS). No forman parte de las pólizas ni de la contabilidad transaccional de la aseguradora. |
| `HIT_RUN`, `DEFORMED`, `SPEC_USE`, `TRAV_SP`, `SPEEDREL`, `DR_SF1` | *No mapeado directamente* | N/A | **NO** | Variables dinámicas forenses de investigación de colisiones viales. Son útiles para reconstrucción de accidentes pero exceden el alcance del registro contable de siniestros y pagos de la póliza. |

---

## 4. Anomalías de Datos y Reglas de Limpieza ETL

Para procesar el archivo crudo y garantizar la integridad ante restricciones estrictas de PostgreSQL (como dominios `rfc_mexicano`, `codigo_postal_tipo`, `monto_dinero`, y claves foráneas), se implementaron las siguientes reglas de limpieza en el script ETL:

1. **Tratamiento de Valores Nulos (`NA`, vacíos, espacios en blanco)**:
   - Los campos con el texto literal `'NA'`, `NULL` en texto, o cadenas vacías `''` se reemplazan por valores válidos por defecto según el tipo de dato en la base de datos (ej. códigos postales genéricos `'01000'` si faltaban, montos en `0.00`).
2. **Parsing de Fechas y Horas**:
   - El campo `YEAR` y `HOUR` se combinan para construir un timestamp válido (`TIMESTAMP`). Si la hora excede 23 o es inválida, se asigna por defecto `'12:00:00'`.
3. **Clasificación Tipológica de Vehículos**:
   - `BODY_TYP` se mapea al ENUM `tipo_vehiculo_enum` (`'AUTOMOVIL'`, `'MOTOCICLETA'`, `'CAMIONETA'`, `'OTRO'`). Si el código corresponde a motocicletas, se inserta en la tabla hija `MOTOCICLETA`; en caso contrario, en `AUTOMOVIL`.
4. **Mapeo de Severidad a Reclamaciones y Pagos**:
   - Lesiones severas (`INJ_SEV >= 2` o `MAX_SEV >= 2`) generan automáticamente una reclamación con estado `'APROBADA'` y un pago monetario estimado calculado en función de la gravedad (ej. $15,000.00 para lesiones moderadas, $50,000.00+ para severas/fatales).
5. **Complementación Sintética de Entidades Relacionales**:
   - Como el dataset de tráfico no incluye datos comerciales de seguros (números de póliza, talleres mecánicos, RFCs de clientes), el ETL genera sintéticamente:
     - **Clientes**: Con RFCs válidos generados algorítmicamente y domicilios coherentes.
     - **Pólizas**: Con folios únicos (`POL-2020-XXXX`) vinculados al cliente.
     - **Talleres**: Con RFCs de talleres mecánicos de prueba y folios de reparación.
6. **Extracción de Muestra de Prueba (~10 registros)**:
   - Tal como se instruyó, se extrajeron exactamente 10 registros representativos y limpios (`practica4/datos/fars_crss_sample_10.csv`) para validar de manera determinista la ejecución del pipeline ETL y la inserción transaccional en PostgreSQL.

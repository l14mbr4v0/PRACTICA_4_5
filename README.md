# Prácticas 4 y 5: Implementación DDL, Restricciones de Dominio, Carga DML, Integridad Referencial y Transacciones

**Unidad de Aprendizaje:** Bases de Datos  
**Plan de Estudios:** Ingeniería en Sistemas Computacionales (2020)  
**Institución:** Escuela Superior de Cómputo (ESCOM) - IPN  

---

## Integrantes del Equipo

*   **Bravo Mina Liam Valapai**
*   **Navarro Domínguez Antonio**
*   **Ávalos Hernandez Joshua Jasiel**

---

## Información de los Proyectos

*   **Proyecto Propio:** Sistema de Seguros de Auto (Base de Datos Transaccional OLTP)
*   **Proyecto Asignado:** Sistema de Visualización de Datos Sísmicos / DWSismos (Almacén de Datos Dimensional OLAP / Esquema en Estrella)
*   **Gestor de Base de Datos:** PostgreSQL 16 (desplegado mediante Docker Compose)

---

## Estructura del Repositorio

El repositorio se encuentra organizado de acuerdo con las especificaciones de entrega de las Prácticas 4 y 5:

```text
.
├── compose.yaml                    # Configuración de Docker Compose para PostgreSQL
├── SQL/
│   └── esquema.sql                 # DDL base generado en Práctica 3
├── practica4/                      # PARTE 1: Práctica 4 (DDL, Dominios, Permisos, Carga ETL)
│   ├── dominios.md                 # Ejercicio 1.1: Diccionario de datos, tipos y dominios
│   ├── fuente.md                   # Ejercicio 1.3: Análisis de fuente de datos (SSRN/FARS/CRSS)
│   ├── pruebas-dominio.md          # Ejercicio 1.5: 10 casos de prueba de violación de restricciones
│   ├── permisos.md                 # Ejercicio 1.6: Gestión de roles, usuarios y matriz de permisos
│   ├── migraciones/
│   │   ├── 001-dominios.sql        # Migración ALTER TABLE: dominios, ENUMs, NOT NULL, DEFAULT, CHECKs
│   │   └── 003-permisos.sql        # Migración DDL para roles (app, consulta, admin) y GRANTs
│   ├── datos/
│   │   ├── fars_crss_sample_10.csv # Muestra cruda extraída (~10 casos para pruebas)
│   │   ├── clean_sample_10.csv     # Muestra procesada y mapeada
│   │   └── datos_prueba.sql        # Inserciones SQL transaccionales (ON CONFLICT DO NOTHING)
│   ├── poblar/
│   │   ├── poblar.sh               # Script de un solo comando para poblar la base de datos
│   │   └── poblar.py               # Script Python transaccional, ordenado, idempotente y con benchmark
│   └── proyecto-asignado/
│       ├── analisis_sismos.md      # Ejercicio 1.7: Análisis de datos, dominios y discrepancias
│       └── poblar_sismos.py        # Población del almacén dimensional de sismos
├── practica5/                      # PARTE 2: Práctica 5 (Integridad Referencial, DML, Transacciones)
│   ├── referencias.md              # Ejercicio 2.1 y 2.2: Inventario de FKs y justificación de acciones
│   ├── pruebas-referenciales.md    # Ejercicio 2.3: Pruebas de CASCADE, RESTRICT, SET NULL y auditoría
│   ├── edicion-de-valores.md       # Ejercicio 2.4: DML avanzado, UPSERT, UPDATE con CASE y transacciones
│   ├── integridad-almacen.md       # Ejercicio 2.5: Análisis de integridad en el almacén de Sismos
│   ├── integrantes/                # Ejercicio 2.6: Trabajo individual firmado por cada integrante
│   │   ├── trabajo-integrante-antonio-navarro.md
│   │   ├── trabajo-integrante-liam-bravo.md
│   │   └── trabajo-integrante-joshua-avalos.md
│   └── sql/
│       ├── 002-referencias.sql     # Migración ALTER TABLE con todas las FKs y acciones referenciales
│       ├── transacciones.sql       # Consultas DML avanzadas, SAVEPOINTs y manejo de errores
│       ├── consultas_integridad.sql# Consultas de verificación que deben retornar 0 filas
│       ├── integridad_sismos.sql   # Pruebas de integridad en almacén asignado
│       ├── navarro_poliza_cliente.sql
│       ├── bravo_poliza_cobertura.sql
│       └── avalos_pago_reclamacion.sql
└── evidencias/
    ├── compose.yaml
    └── logs_ejecucion.md           # Trazas de terminal y resultados de ejecución de pruebas
```

---

## Guía de Ejecución Rápida

### 1. Despliegue del Contenedor de PostgreSQL
```bash
docker compose up -d
```

### 2. Ejecución del Esquema Base y Migraciones
Toda modificación al esquema se ejecuta mediante archivos de migración numerados:
```bash
# Variables de conexión (Cero credenciales en el repositorio)
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=seguros_db
export PGUSER=postgres
export PGPASSWORD=postgres123

# Esquema inicial limpio (Práctica 3)
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f SQL/esquema.sql

# Migración 001: Dominios, tipos personalizados y restricciones CHECK
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f practica4/migraciones/001-dominios.sql

# Migración 002: Claves foráneas y acciones referenciales (ON DELETE / ON UPDATE)
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f practica5/sql/002-referencias.sql

# Migración 003: Roles, usuarios y privilegios
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f practica4/migraciones/003-permisos.sql
```

### 3. Población Automatizada de Datos (Script de un Solo Comando)
El script `poblar.sh` se conecta empleando el rol de aplicación (`app_seguros`), garantizando el principio de menor privilegio:
```bash
# Ejecutar población (idempotente, transaccional, con reporte de filas)
bash practica4/poblar/poblar.sh

# Al ejecutarlo por segunda vez, se verifica que no duplica registros ni termina en error
bash practica4/poblar/poblar.sh
```

### 4. Ejecución de Consultas de Auditoría e Integridad
Para corroborar que la base de datos se encuentra completamente íntegra (0 filas huérfanas, 0 duplicados, 0 violaciones de nulos):
```bash
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f practica5/sql/consultas_integridad.sql
```

### 5. Almacén de Datos Asignado (Sismos)
Para ejecutar la verificación dimensional y la prueba de las tres restricciones de dominio propuestas:
```bash
python3 practica4/proyecto-asignado/poblar_sismos.py
```

---

## Resumen de Decisiones de Diseño

1. **Montos y Precisión:** Se utiliza estrictamente `NUMERIC(12,2)` para cantidades monetarias (primas, montos de reclamación, sumas aseguradas) y nunca punto flotante (`FLOAT`/`REAL`), eliminando errores de redondeo financiero.
2. **Restricciones de Dominio:** Se definieron dominios personalizados (`rfc_mexicano`, `codigo_postal_tipo`, `monto_dinero`) y tipos enumerados (`tipo_vehiculo_enum`, `tipo_transmision_enum`, `tipo_manillar_enum`), junto con más de 10 restricciones `CHECK` que modelan la lógica real de negocio de una aseguradora.
3. **Acciones Referenciales:**
   - `ON DELETE RESTRICT`: Aplicado en relaciones centrales de negocio (`POLIZA -> CLIENTE`, `VEHICULO -> CLIENTE`, `RECLAMACION -> POLIZA`, `PAGO_RECLAMACION -> RECLAMACION`) para preservar la trazabilidad contractual, jurídica y contable.
   - `ON DELETE CASCADE`: Aplicado estrictamente en entidades débiles o tablas puente (`POLIZA_COBERTURA -> POLIZA`, `VEHICULO_ACCIDENTE -> ACCIDENTE`) que carecen de significado sin la entidad padre.
4. **Almacén Dimensional vs. Base Relacional:** Se analizó el esquema en estrella del proyecto asignado (`DWSismos`), explicando por qué los data warehouses omiten claves foráneas físicas en favor del rendimiento en cargas ETL masivas paralelas, y contrastándolo con los riesgos de inconsistencia que ello conlleva.

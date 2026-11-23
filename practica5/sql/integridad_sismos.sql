-- =====================================================================
-- Archivo: practica5/sql/integridad_sismos.sql
-- Descripción: Script de pruebas de integridad referencial para el almacén "Sismos"
-- =====================================================================

-- 1. Consultas para detectar hechos huérfanos en fact_impacto_sismos_imputed
SELECT f.id_sismo, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_sismos d ON f.id_sismo = d.id_sismo
WHERE d.id_sismo IS NULL
GROUP BY f.id_sismo;

SELECT f.id_zonas, COUNT(*) AS total_huerfanos
FROM fact_impacto_sismos_imputed f
LEFT JOIN dim_zonas d ON f.id_zonas = d.id_zonas
WHERE d.id_zonas IS NULL
GROUP BY f.id_zonas;

-- 2. Creación de esquema de copia con claves foráneas explícitas
CREATE TABLE IF NOT EXISTS dim_sismos_copia (
    id_sismo INT PRIMARY KEY,
    magnitud DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS dim_zonas_copia (
    id_zonas INT PRIMARY KEY,
    pobtot INT
);

CREATE TABLE IF NOT EXISTS fact_impacto_sismos_copia (
    id_hecho INT PRIMARY KEY,
    id_sismo INT NOT NULL,
    id_zonas INT NOT NULL,
    CONSTRAINT fk_sismo FOREIGN KEY (id_sismo) REFERENCES dim_sismos_copia(id_sismo) ON DELETE RESTRICT,
    CONSTRAINT fk_zona FOREIGN KEY (id_zonas) REFERENCES dim_zonas_copia(id_zonas) ON DELETE RESTRICT
);

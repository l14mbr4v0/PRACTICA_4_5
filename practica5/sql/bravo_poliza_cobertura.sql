-- =====================================================================
-- Archivo: practica5/sql/bravo_poliza_cobertura.sql
-- Integrante: Bravo Mina Liam Valapai
-- Relación: POLIZA_COBERTURA -> POLIZA
-- =====================================================================

-- Conteo de coberturas por póliza
SELECT NUM_POLIZA, COUNT(*) AS total_coberturas 
FROM POLIZA_COBERTURA 
GROUP BY NUM_POLIZA;

-- Ejemplo de cambio de acción referencial a CASCADE para tabla débil
-- ALTER TABLE POLIZA_COBERTURA DROP CONSTRAINT poliza_cobertura_num_poliza_fkey;
-- ALTER TABLE POLIZA_COBERTURA ADD CONSTRAINT poliza_cobertura_num_poliza_fkey 
--    FOREIGN KEY (NUM_POLIZA) REFERENCES POLIZA(NUM_POLIZA) ON DELETE CASCADE;

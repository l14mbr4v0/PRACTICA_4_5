-- =====================================================================
-- Archivo: practica5/sql/navarro_poliza_cliente.sql
-- Integrante: Navarro Domínguez Antonio
-- Relación: POLIZA -> CLIENTE (Prueba de RESTRICT vs CASCADE)
-- =====================================================================

-- Conteo inicial
SELECT 'CLIENTE' AS tabla, COUNT(*) FROM CLIENTE
UNION ALL
SELECT 'POLIZA', COUNT(*) FROM POLIZA;

-- Prueba de borrado con RESTRICT (Debe fallar si hay pólizas asociadas)
-- DELETE FROM CLIENTE WHERE ID_CLIENTE = 1;

-- Modificación temporal a CASCADE para demostración
-- ALTER TABLE POLIZA DROP CONSTRAINT poliza_id_cliente_fkey;
-- ALTER TABLE POLIZA ADD CONSTRAINT poliza_id_cliente_fkey 
--    FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE(ID_CLIENTE) ON DELETE CASCADE;

-- Conteo posterior al borrado en cascada
-- DELETE FROM CLIENTE WHERE ID_CLIENTE = 1;
-- SELECT COUNT(*) FROM POLIZA;

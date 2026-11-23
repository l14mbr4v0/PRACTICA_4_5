-- =====================================================================
-- Archivo: practica5/sql/avalos_pago_reclamacion.sql
-- Integrante: Ávalos Hernandez Joshua Jasiel
-- Relación: PAGO_RECLAMACION -> RECLAMACION
-- =====================================================================

-- Verificación de pagos asociados a reclamaciones
SELECT r.ID_ACCIDENTE, r.NUM_POLIZA, r.NUM_DE_PAGO, COUNT(p.ID_PAGO_REC) AS total_pagos, SUM(p.monto) AS monto_total
FROM RECLAMACION r
LEFT JOIN PAGO_RECLAMACION p ON r.ID_ACCIDENTE = p.ID_ACCIDENTE 
    AND r.NUM_POLIZA = p.NUM_POLIZA 
    AND r.NUM_DE_PAGO = p.NUM_DE_PAGO
GROUP BY r.ID_ACCIDENTE, r.NUM_POLIZA, r.NUM_DE_PAGO;

-- Demostración de protección contable mediante RESTRICT
-- Intentar borrar una reclamación con pagos arrojará un error de integridad referencial.

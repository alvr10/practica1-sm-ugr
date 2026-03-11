-- ============================================================
-- DML: Datos sintéticos para oltp_logistica
-- ============================================================

-- Transportistas con agentes aduaneros
INSERT INTO oltp_logistica.transportistas (nombre, cif, tipo_servicio, agente_aduanas, telefono, email) VALUES
('SEUR Ceuta SL',               'B51001122A', 'express',    'Aduanas Ceuta SL',           '+34-956-500100', 'ceuta@seur.com'),
('MRW Logística SA',            'A51002233B', 'estandar',   'Gestiones Aduaneras Sur SL', '+34-956-500200', 'ceuta@mrw.es'),
('Correos Express SA',          'A28003344C', 'estandar',   'Correos Aduanas',            '+34-902-197197', 'express@correos.es'),
('DHL Express Spain SLU',       'B28004455D', 'express',    'DHL Global Forwarding',      '+34-902-122424', 'ceuta@dhl.com'),
('GLS Spain SA',                'A28005566E', 'estandar',   'Trámites Estrecho SL',       '+34-902-334455', 'ceuta@gls-group.eu'),
('Nacex Ceuta SL',              'B51006677F', 'express',    'Aduanas del Puerto SA',      '+34-956-500300', 'ceuta@nacex.es'),
('ASM Transporte Urgente SA',   'A28007788G', 'express',    'Agencia Aduanera Sur SL',    '+34-902-100200', 'ceuta@asmred.com'),
('Disfrimur Logística SL',      'B30008899H', 'terrestre',  'Transitarios Murcia SL',     '+34-968-123456', 'info@disfrimur.es'),
('Ferry Balearia Ceuta SA',     'A51009900J', 'maritimo',   'Puerto de Ceuta Aduanas',    '+34-956-647000', 'ceuta@balearia.com'),
('Correos Paquetería SA',       'A28010011K', 'estandar',   'Correos Aduanas',            '+34-900-400500', 'paq@correos.es');

-- Rutas logísticas Ceuta → Destinos peninsulares
INSERT INTO oltp_logistica.rutas (transportista_id, origen, destino, dias_transito, coste_base) VALUES
(1, 'Ceuta', 'Málaga',      2,  8.90),  (1, 'Ceuta', 'Sevilla',     3, 10.50),
(1, 'Ceuta', 'Cádiz',       2,  9.20),  (1, 'Ceuta', 'Granada',     3, 10.90),
(1, 'Ceuta', 'Madrid',      4, 14.50),  (2, 'Ceuta', 'Málaga',      3, 7.50),
(2, 'Ceuta', 'Almería',     3,  9.80),  (2, 'Ceuta', 'Córdoba',     4, 11.20),
(3, 'Ceuta', 'Málaga',      4,  6.20),  (3, 'Ceuta', 'Huelva',      5, 12.50),
(4, 'Ceuta', 'Madrid',      3, 18.90),  (4, 'Ceuta', 'Barcelona',   4, 22.50),
(5, 'Ceuta', 'Murcia',      4, 13.80),  (5, 'Ceuta', 'Valencia',    5, 16.20),
(6, 'Ceuta', 'Málaga',      2,  9.50),  (7, 'Ceuta', 'Madrid',      3, 17.50),
(8, 'Ceuta', 'Murcia',      5, 12.00),  (9, 'Ceuta', 'Algeciras',   1,  3.50),
(9, 'Ceuta', 'Málaga',      2,  5.80),  (10,'Ceuta', 'Málaga',      5,  5.50);

-- Envíos (referenciando pedidos que se insertarán luego — se usa CTE o se hace después)
-- NOTA: Los envíos se insertan con los pedido_id que se generarán en 05_dml_ventas_trans.sql
-- Por ello este bloque de envíos se debe ejecutar DESPUÉS de ese script.
-- Se incluye aquí como referencia; ver 05_dml_ventas_trans.sql para el orden correcto.

-- Trámites de aduanas (DUA) de ejemplo independiente para poblar el esquema
-- (se relacionarán con los envios una vez generados)

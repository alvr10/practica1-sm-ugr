-- ============================================================
-- DML: Datos sintéticos para oltp_inventario
-- ============================================================

-- Proveedores (tecnológicos internacionales)
INSERT INTO oltp_inventario.proveedores (nombre, pais_origen, contacto, email, telefono, cif) VALUES
('Apple Distribution International', 'Irlanda',    'Procurement Dept.',    'orders@apple-dist.eu',      '+353-1-2345678',  NULL),
('Samsung Electronics Iberia SL',    'España',     'Ventas B2B',           'b2b@samsung.es',            '+34-900-123456',  'B28111222A'),
('Ingram Micro España SL',           'España',     'Canal Distribución',   'canal@ingrammicro.es',      '+34-914-567890',  'B28222333B'),
('Tech Data España SA',              'España',     'Dept. Mayoristas',     'mayoristas@techdata.es',    '+34-916-789012',  'A28333444C'),
('Lenovo Global Technology SL',      'España',     'Partner Program',      'partners@lenovo.es',        '+34-917-890123',  'B28444555D'),
('HP Inc. España SL',                'España',     'Distribuidores',       'dist@hp.com',               '+34-918-901234',  'B28555666E'),
('NVIDIA Corporation',               'EEUU',       'Sales EMEA',           'emea-sales@nvidia.com',     '+1-408-5551234',  NULL),
('AMD España SL',                    'España',     'Ventas Canal',         'canal@amd.es',              '+34-919-012345',  'B28666777F'),
('Logitech Europe SA',               'Suiza',      'B2B Sales',            'b2b@logitech.eu',           '+41-21-8631234',  NULL),
('Western Digital España SL',        'España',     'Partner Sales',        'partners@wd.es',            '+34-910-123456',  'B28777888G');

-- Costes de productos (referenciando los 50 productos creados)
INSERT INTO oltp_inventario.costes_producto (producto_id, proveedor_id, coste_unitario, moneda) VALUES
(1, 1, 1650.00,'EUR'), (2, 1, 1100.00,'EUR'), (3, 3,  1380.00,'EUR'), (4, 5,  1280.00,'EUR'),
(5, 6, 1170.00,'EUR'), (6, 3,  1200.00,'EUR'), (7, 1,   950.00,'EUR'), (8, 2,   720.00,'EUR'),
(9, 3,  570.00,'EUR'), (10,3,   490.00,'EUR'), (11,3,   540.00,'EUR'), (12,2,   310.00,'EUR'),
(13,1,  890.00,'EUR'), (14,2,   570.00,'EUR'), (15,3,   105.00,'EUR'), (16,5,   430.00,'EUR'),
(17,8,  520.00,'EUR'), (18,3,   430.00,'EUR'), (19,7,   830.00,'EUR'), (20,8,   740.00,'EUR'),
(21,3,  100.00,'EUR'), (22,3,   200.00,'EUR'), (23,9,    62.00,'EUR'), (24,3,    72.00,'EUR'),
(25,3,  240.00,'EUR'), (26,3,   400.00,'EUR'), (27,9,    55.00,'EUR'), (28,3,   110.00,'EUR'),
(29,3,  155.00,'EUR'), (30,3,   120.00,'EUR'), (31,3,    30.00,'EUR'), (32,2,   125.00,'EUR'),
(33,10,  78.00,'EUR'), (34,3,    65.00,'EUR'), (35,10,   58.00,'EUR'), (36,3,    30.00,'EUR'),
(37,6,  280.00,'EUR'), (38,3,   148.00,'EUR'), (39,3,   228.00,'EUR'), (40,3,   105.00,'EUR'),
(41,6,  168.00,'EUR'), (42,3,   790.00,'EUR'), (43,1,   940.00,'EUR'), (44,3,    42.00,'EUR'),
(45,3,  140.00,'EUR'), (46,2,    98.00,'EUR'), (47,3,    38.00,'EUR'), (48,3,    22.00,'EUR'),
(49,3,   85.00,'EUR'), (50,3,    32.00,'EUR');

-- Stock en almacenes
INSERT INTO oltp_inventario.stock (producto_id, ubicacion, cantidad, stock_minimo, ultima_entrada) VALUES
(1, 'Almacén Ceuta',    8,  3, '2024-11-15'), (2, 'Almacén Ceuta',   12,  5, '2024-11-20'),
(3, 'Almacén Ceuta',    6,  3, '2024-11-10'), (4, 'Almacén Ceuta',    9,  3, '2024-11-18'),
(5, 'Almacén Ceuta',    7,  3, '2024-11-12'), (6, 'Almacén Ceuta',    5,  2, '2024-10-30'),
(7, 'Almacén Ceuta',   15,  5, '2024-11-22'), (8, 'Almacén Ceuta',   20,  8, '2024-11-23'),
(9, 'Almacén Ceuta',   18,  5, '2024-11-20'), (10,'Almacén Ceuta',   22, 10, '2024-11-21'),
(11,'Almacén Ceuta',   16,  6, '2024-11-19'), (12,'Almacén Ceuta',   30, 10, '2024-11-24'),
(13,'Almacén Ceuta',   10,  4, '2024-11-15'), (14,'Almacén Ceuta',   12,  5, '2024-11-17'),
(15,'Almacén Ceuta',   40, 15, '2024-11-24'), (16,'Almacén Ceuta',    8,  3, '2024-11-10'),
(17,'Almacén Ceuta',    6,  2, '2024-11-05'), (18,'Almacén Ceuta',    5,  2, '2024-11-08'),
(19,'Almacén Ceuta',    4,  2, '2024-10-28'), (20,'Almacén Ceuta',    6,  2, '2024-11-02'),
(21,'Almacén Ceuta',   20,  8, '2024-11-20'), (22,'Almacén Ceuta',   15,  5, '2024-11-18'),
(23,'Almacén Ceuta',   35, 10, '2024-11-24'), (24,'Almacén Ceuta',   25,  8, '2024-11-22'),
(25,'Almacén Ceuta',   18,  6, '2024-11-20'), (26,'Almacén Ceuta',    8,  3, '2024-11-15'),
(27,'Almacén Ceuta',   40, 12, '2024-11-24'), (28,'Almacén Ceuta',   22,  8, '2024-11-21'),
(29,'Almacén Ceuta',   15,  5, '2024-11-18'), (30,'Almacén Ceuta',   12,  4, '2024-11-16'),
(31,'Almacén Ceuta',   50, 15, '2024-11-24'), (32,'Almacén Ceuta',   18,  6, '2024-11-20'),
(33,'Almacén Ceuta',   25,  8, '2024-11-22'), (34,'Almacén Ceuta',   30, 10, '2024-11-23'),
(35,'Almacén Ceuta',   45, 15, '2024-11-24'), (36,'Almacén Ceuta',   60, 20, '2024-11-24'),
(37,'Almacén Ceuta',    5,  2, '2024-11-10'), (38,'Almacén Ceuta',    8,  3, '2024-11-14'),
(39,'Almacén Ceuta',    6,  3, '2024-11-12'), (40,'Almacén Ceuta',   12,  4, '2024-11-18'),
(41,'Almacén Ceuta',    7,  3, '2024-11-16'), (42,'Almacén Ceuta',    6,  3, '2024-11-11'),
(43,'Almacén Ceuta',    9,  4, '2024-11-15'), (44,'Almacén Ceuta',   50, 15, '2024-11-24'),
(45,'Almacén Ceuta',   20,  8, '2024-11-20'), (46,'Almacén Ceuta',   35, 10, '2024-11-23'),
(47,'Almacén Ceuta',   70, 20, '2024-11-24'), (48,'Almacén Ceuta',   80, 25, '2024-11-24'),
(49,'Almacén Ceuta',   25,  8, '2024-11-22'), (50,'Almacén Ceuta',   40, 12, '2024-11-23'),
-- Stock en almacén regulador Algeciras
(7, 'Almacén Algeciras', 10, 5, '2024-11-20'), (8, 'Almacén Algeciras', 15, 8, '2024-11-21'),
(12,'Almacén Algeciras', 20,10, '2024-11-22'), (23,'Almacén Algeciras', 15, 5, '2024-11-20');

-- Movimientos de inventario (entradas de stock)
INSERT INTO oltp_inventario.movimientos (producto_id, tipo, cantidad, ubicacion, fecha, referencia, notas) VALUES
(1,  'entrada', 10, 'Almacén Ceuta',    '2024-11-15', 'ALB-2024-1101', 'Reposición Apple MacBook Pro'),
(7,  'entrada', 20, 'Almacén Ceuta',    '2024-11-22', 'ALB-2024-1102', 'Lote iPhone 15 Pro'),
(8,  'entrada', 30, 'Almacén Ceuta',    '2024-11-23', 'ALB-2024-1103', 'Lote Samsung Galaxy S24'),
(19, 'entrada',  6, 'Almacén Ceuta',    '2024-10-28', 'ALB-2024-1054', 'RTX 4080 Super - alta demanda'),
(32, 'entrada', 25, 'Almacén Ceuta',    '2024-11-20', 'ALB-2024-1120', 'Samsung SSD 990 Pro 2TB'),
(7,  'entrada', 15, 'Almacén Algeciras','2024-11-20', 'ALB-2024-1121', 'Stock regulador Algeciras iPhone'),
(8,  'entrada', 20, 'Almacén Algeciras','2024-11-21', 'ALB-2024-1122', 'Stock regulador Algeciras Samsung'),
(12, 'entrada', 25, 'Almacén Algeciras','2024-11-22', 'ALB-2024-1123', 'Smartphones gama media Algeciras'),
(3,  'salida',   2, 'Almacén Ceuta',    '2024-11-18', 'PED-2024-0089', 'Salida por venta'),
(1,  'salida',   1, 'Almacén Ceuta',    '2024-11-19', 'PED-2024-0092', 'Salida por venta'),
(23, 'salida',   3, 'Almacén Ceuta',    '2024-11-20', 'PED-2024-0095', 'Salida por venta periféricos'),
(21, 'ajuste',   2, 'Almacén Ceuta',    '2024-11-10', 'INV-2024-NOV',  'Ajuste inventario tras conteo'),
(15, 'devolucion',1,'Almacén Ceuta',    '2024-11-12', 'DEV-2024-0012', 'Kindle defectuoso, devuelto al proveedor');

-- ============================================================
-- DML: Datos sintéticos para oltp_rrhh
-- ============================================================

-- Departamentos internos
INSERT INTO oltp_rrhh.departamentos (nombre, descripcion) VALUES
('Ventas',         'Equipo comercial y atención al cliente'),
('Logística',      'Gestión de envíos, almacén y aduanas'),
('Finanzas',       'Facturación, pagos y contabilidad'),
('IT/Sistemas',    'Infraestructura tecnológica interna'),
('Dirección',      'Dirección general y estrategia');

-- Empleados (15 empleados reales del PDF + más para cubrir >50 registros totales en RRHH)
INSERT INTO oltp_rrhh.empleados (nombre, apellidos, email, telefono, nif, departamento_id, territorio, cargo, fecha_alta, salario_base) VALUES
('Elena',     'Montero Ruiz',       'emontero@ceutaconnect.es',   '+34-956-100001', '51100001A', 1, 'Ceuta',  'Directora Comercial',   '2019-03-01', 3200.00),
('Antonio',   'Jiménez Vargas',     'ajimenez@ceutaconnect.es',   '+34-956-100002', '51100002B', 1, 'Sur',    'Comercial Senior',      '2020-06-15', 2400.00),
('Carmen',    'López Soto',         'clopez@ceutaconnect.es',     '+34-956-100003', '51100003C', 1, 'Sur',    'Comercial Junior',      '2021-09-01', 1900.00),
('Mohamed',   'Benali Fernández',   'mbenali@ceutaconnect.es',    '+34-956-100004', '51100004D', 1, 'Ceuta',  'Atención al Cliente',   '2021-01-10', 1800.00),
('Sara',      'García Medina',      'sgarcia@ceutaconnect.es',    '+34-956-100005', '51100005E', 1, 'Norte',  'Comercial Junior',      '2022-03-20', 1900.00),
('Adrián',    'Reyes Castro',       'areyes@ceutaconnect.es',     '+34-956-100006', '51100006F', 2, 'Ceuta',  'Jefe de Almacén',       '2018-11-01', 2600.00),
('Fátima',    'Muñoz Haro',         'fmunoz@ceutaconnect.es',     '+34-956-100007', '51100007G', 2, 'Ceuta',  'Gestora Aduanas DUA',   '2020-02-14', 2300.00),
('Juan',      'Torres Blanco',      'jtorres@ceutaconnect.es',    '+34-956-100008', '51100008H', 2, 'Sur',    'Coordinador Logística', '2019-07-01', 2200.00),
('Patricia',  'Navarro Gil',        'pnavarro@ceutaconnect.es',   '+34-956-100009', '51100009J', 2, 'Ceuta',  'Operario Almacén',      '2022-05-16', 1700.00),
('Rafael',    'Domínguez Ortiz',    'rdominguez@ceutaconnect.es', '+34-956-100010', '51100010K', 3, 'Ceuta',  'Director Financiero',   '2017-09-01', 3500.00),
('Silvia',    'Pérez Aguilar',      'sperez@ceutaconnect.es',     '+34-956-100011', '51100011L', 3, 'Ceuta',  'Contable Senior',       '2019-04-08', 2500.00),
('Marcos',    'Herrera Vela',       'mherrera@ceutaconnect.es',   '+34-956-100012', '51100012M', 3, 'Ceuta',  'Administrativo',        '2021-10-01', 1850.00),
('David',     'Moreno Ríos',        'dmoreno@ceutaconnect.es',    '+34-956-100013', '51100013N', 4, 'Ceuta',  'Técnico IT',            '2020-01-20', 2100.00),
('Laura',     'Castellano Cruz',    'lcastellano@ceutaconnect.es','+34-956-100014', '51100014P', 4, 'Ceuta',  'Administradora Sistemas','2018-06-01', 2800.00),
('Iván',      'Gutiérrez Ponce',    'igutierrez@ceutaconnect.es', '+34-956-100015', '51100015Q', 5, 'Ceuta',  'Director General',      '2015-01-01', 5000.00);

-- Objetivos comerciales (trimestres 2023-2024)
INSERT INTO oltp_rrhh.objetivos (empleado_id, anio, trimestre, importe_meta) VALUES
(1,  2023, 1, 80000), (1,  2023, 2, 90000), (1,  2023, 3, 95000), (1,  2023, 4, 100000),
(2,  2023, 1, 40000), (2,  2023, 2, 45000), (2,  2023, 3, 48000), (2,  2023, 4,  52000),
(3,  2023, 1, 25000), (3,  2023, 2, 28000), (3,  2023, 3, 30000), (3,  2023, 4,  33000),
(5,  2023, 1, 22000), (5,  2023, 2, 25000), (5,  2023, 3, 27000), (5,  2023, 4,  30000),
(1,  2024, 1, 85000), (1,  2024, 2, 92000), (2,  2024, 1, 42000), (2,  2024, 2,  47000),
(3,  2024, 1, 27000), (3,  2024, 2, 29000), (5,  2024, 1, 23000), (5,  2024, 2,  26000);

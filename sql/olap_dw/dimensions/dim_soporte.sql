-- ============================================================
-- DIMENSIONES DE SOPORTE (SCD Tipo 1 — sobrescritura directa)
-- Incluye: dim_proveedor, dim_transportista, dim_canal,
--          dim_ubicacion, dim_impuesto
-- ============================================================

-- ============================================================
-- dim_proveedor
-- Origen OLTP: oltp_inventario.proveedores
-- SCD Tipo 1: cambios se sobrescriben (no hay historificación)
-- Conformada: NO — solo fact_inventario
-- ============================================================
CREATE TABLE olap.dim_proveedor (
    proveedor_sk    SERIAL       NOT NULL,
    proveedor_nk    INT          NOT NULL,   -- proveedor_id OLTP
    nombre          VARCHAR(150) NOT NULL,
    pais_origen     VARCHAR(100) NOT NULL,
    contacto        VARCHAR(150),
    email           VARCHAR(150),
    telefono        VARCHAR(30),
    cif             VARCHAR(20),
    activo          BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_dim_proveedor PRIMARY KEY (proveedor_sk),
    CONSTRAINT uq_dim_proveedor_nk UNIQUE (proveedor_nk)
);

INSERT INTO olap.dim_proveedor (proveedor_nk, nombre, pais_origen, contacto, email, telefono, cif, activo)
SELECT proveedor_id, nombre, pais_origen, contacto, email, telefono, cif, activo
FROM oltp_inventario.proveedores
ON CONFLICT (proveedor_nk) DO UPDATE
    SET nombre      = EXCLUDED.nombre,
        pais_origen = EXCLUDED.pais_origen,
        activo      = EXCLUDED.activo;


-- ============================================================
-- dim_transportista
-- Origen OLTP: oltp_logistica.transportistas
-- SCD Tipo 1
-- Conformada: NO — solo fact_envios
-- ============================================================
CREATE TABLE olap.dim_transportista (
    transportista_sk    SERIAL      NOT NULL,
    transportista_nk    INT         NOT NULL,   -- transportista_id OLTP
    nombre              VARCHAR(150) NOT NULL,
    cif                 VARCHAR(20),
    tipo_servicio       VARCHAR(50) NOT NULL,
    agente_aduanas      VARCHAR(150),
    activo              BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_dim_transportista PRIMARY KEY (transportista_sk),
    CONSTRAINT uq_dim_transportista_nk UNIQUE (transportista_nk)
);

INSERT INTO olap.dim_transportista (transportista_nk, nombre, cif, tipo_servicio, agente_aduanas, activo)
SELECT transportista_id, nombre, cif, tipo_servicio, agente_aduanas, activo
FROM oltp_logistica.transportistas
ON CONFLICT (transportista_nk) DO UPDATE
    SET nombre        = EXCLUDED.nombre,
        tipo_servicio = EXCLUDED.tipo_servicio,
        activo        = EXCLUDED.activo;


-- ============================================================
-- dim_canal
-- Origen OLTP: valores del CHECK de oltp_ventas.pedidos.canal
-- SCD Tipo 1 (tabla estática, rara vez cambia)
-- Conformada: NO — solo fact_ventas_linea
-- ============================================================
CREATE TABLE olap.dim_canal (
    canal_sk        SERIAL      NOT NULL,
    canal_nk        VARCHAR(30) NOT NULL,   -- valor literal del canal
    descripcion     VARCHAR(100),
    tipo_canal      VARCHAR(30),            -- 'digital', 'humano', etc.
    CONSTRAINT pk_dim_canal PRIMARY KEY (canal_sk),
    CONSTRAINT uq_dim_canal_nk UNIQUE (canal_nk)
);

INSERT INTO olap.dim_canal (canal_nk, descripcion, tipo_canal) VALUES
    ('web',          'Pedido realizado a través del portal web', 'digital'),
    ('telefono',     'Pedido realizado por atención telefónica', 'humano'),
    ('marketplace',  'Pedido a través de marketplace externo',   'digital')
ON CONFLICT (canal_nk) DO NOTHING;


-- ============================================================
-- dim_ubicacion
-- Origen OLTP: CHECK constraints de oltp_inventario.stock.ubicacion
-- SCD Tipo 1
-- Conformada: NO — fact_inventario + fact_envios (destinos)
-- ============================================================
CREATE TABLE olap.dim_ubicacion (
    ubicacion_sk    SERIAL      NOT NULL,
    ubicacion_nk    VARCHAR(50) NOT NULL,   -- nombre literal de la ubicación
    ciudad          VARCHAR(100),
    provincia       VARCHAR(100),
    pais            VARCHAR(100) NOT NULL DEFAULT 'España',
    tipo_ubicacion  VARCHAR(30)  NOT NULL,  -- 'almacen', 'destino_envio'
    CONSTRAINT pk_dim_ubicacion PRIMARY KEY (ubicacion_sk),
    CONSTRAINT uq_dim_ubicacion_nk UNIQUE (ubicacion_nk)
);

INSERT INTO olap.dim_ubicacion (ubicacion_nk, ciudad, provincia, tipo_ubicacion) VALUES
    ('Almacén Ceuta',     'Ceuta',     'Ceuta',   'almacen'),
    ('Almacén Algeciras', 'Algeciras', 'Cádiz',   'almacen'),
    ('Almacén Málaga',    'Málaga',    'Málaga',  'almacen')
ON CONFLICT (ubicacion_nk) DO NOTHING;


-- ============================================================
-- dim_impuesto
-- Origen OLTP: valores de tipo_impuesto en oltp_ventas + oltp_finanzas
-- SCD Tipo 1 (tabla estática)
-- Conformada: SÍ — fact_ventas_linea + fact_pagos
-- ============================================================
CREATE TABLE olap.dim_impuesto (
    impuesto_sk     SERIAL      NOT NULL,
    tipo_impuesto   VARCHAR(10) NOT NULL,   -- IVA, IPSI, IGIC, EXENTO
    pct_impuesto    NUMERIC(5,2) NOT NULL,
    descripcion     VARCHAR(100),
    ambito          VARCHAR(50),            -- 'Peninsula', 'Ceuta', 'Canarias', etc.
    CONSTRAINT pk_dim_impuesto PRIMARY KEY (impuesto_sk),
    CONSTRAINT uq_dim_impuesto UNIQUE (tipo_impuesto, pct_impuesto)
);

INSERT INTO olap.dim_impuesto (tipo_impuesto, pct_impuesto, descripcion, ambito) VALUES
    ('IVA',    21.00, 'IVA general 21%',            'Península y Baleares'),
    ('IVA',    10.00, 'IVA reducido 10%',            'Península y Baleares'),
    ('IVA',     4.00, 'IVA superreducido 4%',        'Península y Baleares'),
    ('IPSI',    0.50, 'IPSI tipo 0.5% Ceuta',        'Ceuta'),
    ('IPSI',    4.00, 'IPSI tipo 4% Ceuta',          'Ceuta'),
    ('IGIC',    7.00, 'IGIC general 7%',             'Canarias'),
    ('EXENTO',  0.00, 'Operación exenta de impuesto', 'Global')
ON CONFLICT (tipo_impuesto, pct_impuesto) DO NOTHING;

-- ============================================================
-- ESQUEMA: oltp_finanzas
-- Descripción: Finanzas de Ceuta Connect
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp_finanzas;

-- Tabla de facturas (referencia cruzada a oltp_ventas.pedidos y clientes)
CREATE TABLE oltp_finanzas.facturas (
    factura_id     SERIAL PRIMARY KEY,
    num_factura    VARCHAR(30) NOT NULL UNIQUE,
    pedido_id      INT NOT NULL UNIQUE,  -- FK cruzada → oltp_ventas.pedidos
    cliente_id     INT NOT NULL,         -- FK cruzada → oltp_ventas.clientes
    fecha_emision  DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE NOT NULL,
    importe_bruto  NUMERIC(12,2) NOT NULL CHECK (importe_bruto >= 0),
    tipo_impuesto  VARCHAR(10) NOT NULL DEFAULT 'IVA'
                   CHECK (tipo_impuesto IN ('IVA','IPSI','IGIC','EXENTO')),
    pct_impuesto   NUMERIC(5,2) NOT NULL DEFAULT 21,
    importe_impuesto NUMERIC(12,2) NOT NULL,
    importe_total  NUMERIC(12,2) NOT NULL,
    estado         VARCHAR(20) NOT NULL DEFAULT 'emitida'
                   CHECK (estado IN ('emitida','pagada','vencida','anulada'))
);

CREATE INDEX idx_facturas_pedido ON oltp_finanzas.facturas(pedido_id);
CREATE INDEX idx_facturas_fecha ON oltp_finanzas.facturas(fecha_emision);
CREATE INDEX idx_facturas_estado ON oltp_finanzas.facturas(estado);

-- Tabla de liquidaciones IPSI/IVA
CREATE TABLE oltp_finanzas.liquidaciones (
    liquidacion_id  SERIAL PRIMARY KEY,
    periodo         VARCHAR(10) NOT NULL,  -- Ej: '2024-T1'
    tipo_impuesto   VARCHAR(10) NOT NULL CHECK (tipo_impuesto IN ('IVA','IPSI')),
    importe_base    NUMERIC(14,2) NOT NULL,
    importe_cuota   NUMERIC(14,2) NOT NULL,
    fecha_presentacion DATE,
    estado          VARCHAR(20) NOT NULL DEFAULT 'borrador'
                    CHECK (estado IN ('borrador','presentada','aceptada','impugnada')),
    UNIQUE (periodo, tipo_impuesto)
);

-- Tabla de gastos operativos
CREATE TABLE oltp_finanzas.gastos (
    gasto_id      SERIAL PRIMARY KEY,
    concepto      VARCHAR(200) NOT NULL,
    categoria     VARCHAR(50) NOT NULL
                  CHECK (categoria IN ('logistica','personal','marketing','aduanas','infraestructura','otros')),
    importe       NUMERIC(12,2) NOT NULL CHECK (importe > 0),
    fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
    proveedor     VARCHAR(150),
    num_factura_ext VARCHAR(50),
    notas         TEXT
);

CREATE INDEX idx_gastos_categoria ON oltp_finanzas.gastos(categoria);
CREATE INDEX idx_gastos_fecha ON oltp_finanzas.gastos(fecha);

-- Tabla de pagos recibidos
CREATE TABLE oltp_finanzas.pagos (
    pago_id       SERIAL PRIMARY KEY,
    factura_id    INT NOT NULL REFERENCES oltp_finanzas.facturas(factura_id),
    fecha_pago    DATE NOT NULL DEFAULT CURRENT_DATE,
    importe       NUMERIC(12,2) NOT NULL CHECK (importe > 0),
    metodo        VARCHAR(30) NOT NULL
                  CHECK (metodo IN ('tarjeta','transferencia','bizum','paypal','contrarreembolso')),
    referencia    VARCHAR(100) UNIQUE
);

CREATE INDEX idx_pagos_factura ON oltp_finanzas.pagos(factura_id);
CREATE INDEX idx_pagos_fecha ON oltp_finanzas.pagos(fecha_pago);
-- ============================================================
-- TABLA DE HECHOS: fact_ventas_linea
-- Proceso de negocio: Línea de detalle de pedido de venta
-- Granularidad: Una fila por línea de pedido (pedido_id + producto_id)
-- Origen OLTP:
--   oltp_ventas.detalle_pedido  (medidas principales)
--   oltp_ventas.pedidos         (canal, fecha, estado, descuento)
--   oltp_ventas.clientes        (→ dim_cliente)
--   oltp_rrhh.empleados         (→ dim_empleado)
--   oltp_finanzas.facturas      (impuesto, importes netos)
-- ============================================================

CREATE TABLE olap.fact_ventas_linea (
    -- Surrogate Keys (FKs a dimensiones)
    fecha_sk            INT          NOT NULL,
    producto_sk         INT          NOT NULL,
    cliente_sk          INT          NOT NULL,
    empleado_sk         INT          NOT NULL,
    canal_sk            INT          NOT NULL,
    impuesto_sk         INT          NOT NULL,

    -- Degenerate Dimensions (claves del sistema origen sin dimensión propia)
    pedido_nk           INT          NOT NULL,   -- pedido_id OLTP
    detalle_nk          INT          NOT NULL,   -- detalle_id OLTP
    estado_pedido       VARCHAR(30)  NOT NULL,

    -- MEDIDAS (Aditivas)
    cantidad            INT          NOT NULL,
    precio_unitario     NUMERIC(10,2) NOT NULL,
    descuento_pct       NUMERIC(5,2)  NOT NULL DEFAULT 0,
    importe_bruto       NUMERIC(12,2) NOT NULL,   -- cantidad * precio_unitario
    importe_descuento   NUMERIC(12,2) NOT NULL,   -- importe_bruto * descuento_pct/100
    importe_neto        NUMERIC(12,2) NOT NULL,   -- importe_bruto - importe_descuento
    importe_impuesto    NUMERIC(12,2) NOT NULL,   -- importe_neto * tasa_ipsi_pct/100
    importe_total       NUMERIC(12,2) NOT NULL,   -- importe_neto + importe_impuesto
    coste_linea         NUMERIC(12,2),            -- cantidad * coste_unitario (puede ser NULL)
    margen_linea        NUMERIC(12,2),            -- importe_neto - coste_linea

    -- Metadatos ETL
    fecha_carga         TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_fact_ventas_linea PRIMARY KEY (pedido_nk, detalle_nk),
    CONSTRAINT fk_fvl_fecha       FOREIGN KEY (fecha_sk)      REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fvl_producto    FOREIGN KEY (producto_sk)   REFERENCES olap.dim_producto(producto_sk),
    CONSTRAINT fk_fvl_cliente     FOREIGN KEY (cliente_sk)    REFERENCES olap.dim_cliente(cliente_sk),
    CONSTRAINT fk_fvl_empleado    FOREIGN KEY (empleado_sk)   REFERENCES olap.dim_empleado(empleado_sk),
    CONSTRAINT fk_fvl_canal       FOREIGN KEY (canal_sk)      REFERENCES olap.dim_canal(canal_sk),
    CONSTRAINT fk_fvl_impuesto    FOREIGN KEY (impuesto_sk)   REFERENCES olap.dim_impuesto(impuesto_sk)
);

CREATE INDEX idx_fvl_fecha     ON olap.fact_ventas_linea(fecha_sk);
CREATE INDEX idx_fvl_producto  ON olap.fact_ventas_linea(producto_sk);
CREATE INDEX idx_fvl_cliente   ON olap.fact_ventas_linea(cliente_sk);
CREATE INDEX idx_fvl_empleado  ON olap.fact_ventas_linea(empleado_sk);
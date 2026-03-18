-- ============================================================
-- TABLA DE HECHOS: fact_inventario
-- Proceso: Movimiento de stock en almacén
-- Granularidad: Un movimiento de inventario
-- Origen OLTP: oltp_inventario.movimientos + stock
-- ============================================================
CREATE TABLE olap.fact_inventario (
    -- SKs de dimensiones
    fecha_sk            INT          NOT NULL,
    producto_sk         INT          NOT NULL,
    proveedor_sk        INT,                      -- NULL si no aplica
    ubicacion_sk        INT          NOT NULL,

    -- Degenerate Dimensions
    movimiento_nk       INT          NOT NULL,
    tipo_movimiento     VARCHAR(20)  NOT NULL,
    referencia          VARCHAR(100),

    -- MEDIDAS
    cantidad_movimiento INT          NOT NULL,
    cantidad_stock_post INT,                      -- stock tras el movimiento (snapshot)
    coste_unitario      NUMERIC(10,2),
    coste_total         NUMERIC(12,2),            -- cantidad_movimiento * coste_unitario

    -- Metadatos ETL
    fecha_carga         TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_fact_inventario   PRIMARY KEY (movimiento_nk),
    CONSTRAINT fk_fi_fecha          FOREIGN KEY (fecha_sk)     REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fi_producto       FOREIGN KEY (producto_sk)  REFERENCES olap.dim_producto(producto_sk),
    CONSTRAINT fk_fi_proveedor      FOREIGN KEY (proveedor_sk) REFERENCES olap.dim_proveedor(proveedor_sk),
    CONSTRAINT fk_fi_ubicacion      FOREIGN KEY (ubicacion_sk) REFERENCES olap.dim_ubicacion(ubicacion_sk)
);

CREATE INDEX idx_fi_fecha     ON olap.fact_inventario(fecha_sk);
CREATE INDEX idx_fi_producto  ON olap.fact_inventario(producto_sk);
CREATE INDEX idx_fi_ubicacion ON olap.fact_inventario(ubicacion_sk);

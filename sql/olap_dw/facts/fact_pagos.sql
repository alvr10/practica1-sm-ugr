-- ============================================================
-- TABLA DE HECHOS: fact_pagos
-- Proceso: Cobros y facturación
-- Granularidad: Un pago recibido
-- Origen OLTP: oltp_finanzas.pagos + facturas
-- ============================================================
CREATE TABLE olap.fact_pagos (
    -- SKs de dimensiones
    fecha_pago_sk       INT          NOT NULL,
    fecha_emision_sk    INT          NOT NULL,
    fecha_vencimiento_sk INT         NOT NULL,
    cliente_sk          INT          NOT NULL,
    impuesto_sk         INT          NOT NULL,

    -- Degenerate Dimensions
    pago_nk             INT          NOT NULL,
    factura_nk          INT          NOT NULL,
    pedido_nk           INT          NOT NULL,
    num_factura         VARCHAR(30)  NOT NULL,
    metodo_pago         VARCHAR(30)  NOT NULL,
    estado_factura      VARCHAR(20)  NOT NULL,

    -- MEDIDAS
    importe_pago        NUMERIC(12,2) NOT NULL,
    importe_bruto_fac   NUMERIC(12,2) NOT NULL,
    importe_impuesto    NUMERIC(12,2) NOT NULL,
    importe_total_fac   NUMERIC(12,2) NOT NULL,
    dias_hasta_pago     INT,                      -- fecha_pago - fecha_emision

    -- Metadatos ETL
    fecha_carga         TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_fact_pagos        PRIMARY KEY (pago_nk),
    CONSTRAINT fk_fp_fecha_pago     FOREIGN KEY (fecha_pago_sk)        REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fp_fecha_emision  FOREIGN KEY (fecha_emision_sk)     REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fp_fecha_vto      FOREIGN KEY (fecha_vencimiento_sk) REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fp_cliente        FOREIGN KEY (cliente_sk)           REFERENCES olap.dim_cliente(cliente_sk),
    CONSTRAINT fk_fp_impuesto       FOREIGN KEY (impuesto_sk)          REFERENCES olap.dim_impuesto(impuesto_sk)
);

CREATE INDEX idx_fp_fecha_pago ON olap.fact_pagos(fecha_pago_sk);
CREATE INDEX idx_fp_cliente    ON olap.fact_pagos(cliente_sk);
CREATE INDEX idx_fp_factura    ON olap.fact_pagos(factura_nk);

-- ============================================================
-- TABLA DE HECHOS: fact_comisiones
-- Proceso: Comisiones comerciales de empleados
-- Granularidad: Una comisión (un empleado sobre un pedido)
-- Origen OLTP: oltp_rrhh.comisiones + objetivos
-- ============================================================
CREATE TABLE olap.fact_comisiones (
    -- SKs de dimensiones
    fecha_sk            INT          NOT NULL,
    empleado_sk         INT          NOT NULL,

    -- Degenerate Dimensions
    comision_nk         INT          NOT NULL,
    pedido_nk           INT          NOT NULL,

    -- MEDIDAS
    importe_comision    NUMERIC(10,2) NOT NULL,
    pct_aplicado        NUMERIC(5,2)  NOT NULL,
    importe_meta_trim   NUMERIC(12,2),            -- objetivo trimestral del empleado ese período

    -- Metadatos ETL
    fecha_carga         TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_fact_comisiones   PRIMARY KEY (comision_nk),
    CONSTRAINT fk_fc_fecha          FOREIGN KEY (fecha_sk)    REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fc_empleado       FOREIGN KEY (empleado_sk) REFERENCES olap.dim_empleado(empleado_sk)
);

CREATE INDEX idx_fc_fecha    ON olap.fact_comisiones(fecha_sk);
CREATE INDEX idx_fc_empleado ON olap.fact_comisiones(empleado_sk);
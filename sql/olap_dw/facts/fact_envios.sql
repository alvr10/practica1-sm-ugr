-- ============================================================
-- TABLA DE HECHOS: fact_envios
-- Proceso: Envío y entrega logística
-- Granularidad: Un envío (un pedido = un envío)
-- Origen OLTP: oltp_logistica.envios + tramites_aduanas
-- ============================================================
CREATE TABLE olap.fact_envios (
    -- SKs de dimensiones
    fecha_salida_sk         INT          NOT NULL,
    fecha_entrega_est_sk    INT          NOT NULL,
    fecha_entrega_real_sk   INT          NOT NULL DEFAULT 0,  -- 0 = pendiente
    cliente_sk              INT          NOT NULL,
    transportista_sk        INT          NOT NULL,

    -- Degenerate Dimensions
    pedido_nk               INT          NOT NULL,
    envio_nk                INT          NOT NULL,
    estado_envio            VARCHAR(30)  NOT NULL,
    provincia_destino       VARCHAR(100) NOT NULL,
    ciudad_destino          VARCHAR(100) NOT NULL,

    -- MEDIDAS
    coste_envio             NUMERIC(10,2) NOT NULL,
    peso_kg                 NUMERIC(8,2),
    dias_transito_real      INT,                   -- fecha_entrega_real - fecha_salida
    dias_retraso            INT,                   -- real - estimada (negativo = adelanto)
    coste_tramite_aduanas   NUMERIC(10,2) NOT NULL DEFAULT 0,
    horas_demora_aduanas    NUMERIC(6,2)  NOT NULL DEFAULT 0,
    coste_total_logistica   NUMERIC(12,2),         -- coste_envio + coste_tramite

    -- Metadatos ETL
    fecha_carga             TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_fact_envios       PRIMARY KEY (envio_nk),
    CONSTRAINT fk_fe_fecha_sal      FOREIGN KEY (fecha_salida_sk)       REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fe_fecha_est      FOREIGN KEY (fecha_entrega_est_sk)  REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fe_fecha_real     FOREIGN KEY (fecha_entrega_real_sk) REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fe_cliente        FOREIGN KEY (cliente_sk)            REFERENCES olap.dim_cliente(cliente_sk),
    CONSTRAINT fk_fe_transportista  FOREIGN KEY (transportista_sk)      REFERENCES olap.dim_transportista(transportista_sk)
);

CREATE INDEX idx_fe_fecha_sal     ON olap.fact_envios(fecha_salida_sk);
CREATE INDEX idx_fe_cliente       ON olap.fact_envios(cliente_sk);
CREATE INDEX idx_fe_transportista ON olap.fact_envios(transportista_sk);

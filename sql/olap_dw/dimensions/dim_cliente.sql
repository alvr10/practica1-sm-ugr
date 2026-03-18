-- ============================================================
-- DIMENSIÓN: dim_cliente
-- Origen OLTP: oltp_ventas.clientes
-- Tipo SCD: Tipo 2 — se versionan cambios en dirección, ciudad, provincia
-- Conformada: SÍ — fact_ventas_linea + fact_envios + fact_pagos
-- ============================================================

CREATE TABLE olap.dim_cliente (
    cliente_sk          SERIAL       NOT NULL,   -- Surrogate Key
    cliente_nk          INT          NOT NULL,   -- Natural Key (cliente_id)
    nombre              VARCHAR(150) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    telefono            VARCHAR(20),
    direccion           VARCHAR(200),
    ciudad              VARCHAR(100),
    provincia           VARCHAR(100),
    codigo_postal       VARCHAR(10),
    pais                VARCHAR(100) NOT NULL DEFAULT 'España',
    cif                 VARCHAR(20),
    segmento            VARCHAR(30)  GENERATED ALWAYS AS (
                            CASE
                                WHEN cif IS NOT NULL THEN 'B2B'
                                ELSE 'B2C'
                            END
                        ) STORED,               -- columna calculada
    fecha_alta_cliente  DATE         NOT NULL,
    -- SCD Tipo 2
    fecha_inicio        DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin           DATE         NOT NULL DEFAULT '9999-12-31',
    es_version_actual   BOOLEAN      NOT NULL DEFAULT TRUE,
    version             INT          NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_cliente PRIMARY KEY (cliente_sk)
);

CREATE INDEX idx_dim_cliente_nk     ON olap.dim_cliente(cliente_nk);
CREATE INDEX idx_dim_cliente_actual ON olap.dim_cliente(cliente_nk, es_version_actual);
CREATE INDEX idx_dim_cliente_prov   ON olap.dim_cliente(provincia);

-- -------------------------------------------------------
-- PROCEDIMIENTO SCD Tipo 2: upsert_dim_cliente
-- Versiona cambios en: dirección, ciudad, provincia, cp, email
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE olap.upsert_dim_cliente(p_cliente_nk INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_current     olap.dim_cliente%ROWTYPE;
    v_src         oltp_ventas.clientes%ROWTYPE;
    v_has_changes BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_src
    FROM oltp_ventas.clientes
    WHERE cliente_id = p_cliente_nk;

    SELECT * INTO v_current
    FROM olap.dim_cliente
    WHERE cliente_nk = p_cliente_nk
      AND es_version_actual = TRUE
    LIMIT 1;

    IF NOT FOUND THEN
        INSERT INTO olap.dim_cliente (
            cliente_nk, nombre, email, telefono, direccion, ciudad,
            provincia, codigo_postal, pais, cif, fecha_alta_cliente,
            fecha_inicio, fecha_fin, es_version_actual, version
        ) VALUES (
            v_src.cliente_id, v_src.nombre, v_src.email, v_src.telefono,
            v_src.direccion, v_src.ciudad, v_src.provincia,
            v_src.codigo_postal, v_src.pais, v_src.cif, v_src.fecha_alta,
            CURRENT_DATE, '9999-12-31', TRUE, 1
        );
    ELSE
        IF v_current.direccion  IS DISTINCT FROM v_src.direccion
        OR v_current.ciudad     IS DISTINCT FROM v_src.ciudad
        OR v_current.provincia  IS DISTINCT FROM v_src.provincia
        OR v_current.email      <> v_src.email
        THEN
            v_has_changes := TRUE;
        END IF;

        IF v_has_changes THEN
            UPDATE olap.dim_cliente
            SET fecha_fin         = CURRENT_DATE - INTERVAL '1 day',
                es_version_actual = FALSE
            WHERE cliente_sk = v_current.cliente_sk;

            INSERT INTO olap.dim_cliente (
                cliente_nk, nombre, email, telefono, direccion, ciudad,
                provincia, codigo_postal, pais, cif, fecha_alta_cliente,
                fecha_inicio, fecha_fin, es_version_actual, version
            ) VALUES (
                v_src.cliente_id, v_src.nombre, v_src.email, v_src.telefono,
                v_src.direccion, v_src.ciudad, v_src.provincia,
                v_src.codigo_postal, v_src.pais, v_src.cif, v_src.fecha_alta,
                CURRENT_DATE, '9999-12-31', TRUE, v_current.version + 1
            );
        END IF;
    END IF;
END;
$$;
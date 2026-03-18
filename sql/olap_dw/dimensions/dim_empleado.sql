-- ============================================================
-- DIMENSIÓN: dim_empleado
-- Origen OLTP: oltp_rrhh.empleados + oltp_rrhh.departamentos
-- Tipo SCD: Tipo 2 — se versionan cambios en cargo, departamento,
--           territorio y salario_base
-- Conformada: SÍ — fact_ventas_linea + fact_comisiones
-- ============================================================

CREATE TABLE olap.dim_empleado (
    empleado_sk         SERIAL       NOT NULL,   -- Surrogate Key
    empleado_nk         INT          NOT NULL,   -- Natural Key (empleado_id)
    nombre              VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(150) NOT NULL,
    nombre_completo     VARCHAR(255) GENERATED ALWAYS AS
                            (apellidos || ', ' || nombre) STORED,
    email               VARCHAR(150) NOT NULL,
    nif                 VARCHAR(15)  NOT NULL,
    departamento        VARCHAR(100) NOT NULL,   -- desnormalizado desde departamentos
    cargo               VARCHAR(100) NOT NULL,
    territorio          VARCHAR(100) NOT NULL,
    salario_base        NUMERIC(10,2) NOT NULL,
    activo_empleado     BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_alta_empleado DATE         NOT NULL,
    -- SCD Tipo 2
    fecha_inicio        DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin           DATE         NOT NULL DEFAULT '9999-12-31',
    es_version_actual   BOOLEAN      NOT NULL DEFAULT TRUE,
    version             INT          NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_empleado PRIMARY KEY (empleado_sk)
);

CREATE INDEX idx_dim_empleado_nk         ON olap.dim_empleado(empleado_nk);
CREATE INDEX idx_dim_empleado_actual     ON olap.dim_empleado(empleado_nk, es_version_actual);
CREATE INDEX idx_dim_empleado_territorio ON olap.dim_empleado(territorio);

-- -------------------------------------------------------
-- PROCEDIMIENTO SCD Tipo 2: upsert_dim_empleado
-- Versiona cambios en: cargo, departamento, territorio, salario
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE olap.upsert_dim_empleado(p_empleado_nk INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_current     olap.dim_empleado%ROWTYPE;
    v_src         RECORD;
    v_has_changes BOOLEAN := FALSE;
BEGIN
    SELECT
        e.empleado_id, e.nombre, e.apellidos, e.email, e.nif,
        d.nombre AS departamento,
        e.cargo, e.territorio, e.salario_base, e.activo, e.fecha_alta
    INTO v_src
    FROM oltp_rrhh.empleados e
    JOIN oltp_rrhh.departamentos d ON d.departamento_id = e.departamento_id
    WHERE e.empleado_id = p_empleado_nk;

    SELECT * INTO v_current
    FROM olap.dim_empleado
    WHERE empleado_nk = p_empleado_nk
      AND es_version_actual = TRUE
    LIMIT 1;

    IF NOT FOUND THEN
        INSERT INTO olap.dim_empleado (
            empleado_nk, nombre, apellidos, email, nif, departamento,
            cargo, territorio, salario_base, activo_empleado,
            fecha_alta_empleado, fecha_inicio, fecha_fin, es_version_actual, version
        ) VALUES (
            v_src.empleado_id, v_src.nombre, v_src.apellidos, v_src.email,
            v_src.nif, v_src.departamento, v_src.cargo, v_src.territorio,
            v_src.salario_base, v_src.activo, v_src.fecha_alta,
            CURRENT_DATE, '9999-12-31', TRUE, 1
        );
    ELSE
        IF v_current.cargo        <> v_src.cargo
        OR v_current.departamento <> v_src.departamento
        OR v_current.territorio   <> v_src.territorio
        OR v_current.salario_base <> v_src.salario_base
        THEN
            v_has_changes := TRUE;
        END IF;

        IF v_has_changes THEN
            UPDATE olap.dim_empleado
            SET fecha_fin         = CURRENT_DATE - INTERVAL '1 day',
                es_version_actual = FALSE
            WHERE empleado_sk = v_current.empleado_sk;

            INSERT INTO olap.dim_empleado (
                empleado_nk, nombre, apellidos, email, nif, departamento,
                cargo, territorio, salario_base, activo_empleado,
                fecha_alta_empleado, fecha_inicio, fecha_fin, es_version_actual, version
            ) VALUES (
                v_src.empleado_id, v_src.nombre, v_src.apellidos, v_src.email,
                v_src.nif, v_src.departamento, v_src.cargo, v_src.territorio,
                v_src.salario_base, v_src.activo, v_src.fecha_alta,
                CURRENT_DATE, '9999-12-31', TRUE, v_current.version + 1
            );
        END IF;
    END IF;
END;
$$;
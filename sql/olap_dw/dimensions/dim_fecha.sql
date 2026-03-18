-- ============================================================
-- DIMENSIÓN: dim_fecha
-- Origen OLTP: No existe — generada artificialmente (Date Spine)
-- Tipo SCD: Sin versiones (atributos estáticos de un día)
-- Conformada: SÍ — compartida por todos los procesos
-- ============================================================

CREATE TABLE olap.dim_fecha (
    fecha_sk         INT          NOT NULL,   -- Surrogate Key: formato YYYYMMDD
    fecha            DATE         NOT NULL,
    anio             SMALLINT     NOT NULL,
    trimestre        SMALLINT     NOT NULL,   -- 1-4
    mes              SMALLINT     NOT NULL,   -- 1-12
    semana_anio      SMALLINT     NOT NULL,   -- ISO week 1-53
    dia_mes          SMALLINT     NOT NULL,   -- 1-31
    dia_semana       SMALLINT     NOT NULL,   -- 1=Lunes ... 7=Domingo
    nombre_mes       VARCHAR(20)  NOT NULL,   -- 'Enero', 'Febrero', ...
    nombre_dia       VARCHAR(20)  NOT NULL,   -- 'Lunes', 'Martes', ...
    trimestre_label  VARCHAR(10)  NOT NULL,   -- 'Q1-2024'
    es_festivo       BOOLEAN      NOT NULL DEFAULT FALSE,
    es_fin_semana    BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_dim_fecha PRIMARY KEY (fecha_sk)
);

-- -------------------------------------------------------
-- Población: generación del Date Spine 2020-2030
-- Ejecutar una sola vez tras crear la tabla
-- -------------------------------------------------------
INSERT INTO olap.dim_fecha (
    fecha_sk, fecha, anio, trimestre, mes, semana_anio,
    dia_mes, dia_semana, nombre_mes, nombre_dia,
    trimestre_label, es_fin_semana
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT                        AS fecha_sk,
    d::DATE                                             AS fecha,
    EXTRACT(YEAR    FROM d)::SMALLINT                   AS anio,
    EXTRACT(QUARTER FROM d)::SMALLINT                   AS trimestre,
    EXTRACT(MONTH   FROM d)::SMALLINT                   AS mes,
    EXTRACT(WEEK    FROM d)::SMALLINT                   AS semana_anio,
    EXTRACT(DAY     FROM d)::SMALLINT                   AS dia_mes,
    EXTRACT(ISODOW  FROM d)::SMALLINT                   AS dia_semana,
    TO_CHAR(d, 'TMMonth')                               AS nombre_mes,
    TO_CHAR(d, 'TMDay')                                 AS nombre_dia,
    'Q' || EXTRACT(QUARTER FROM d)::TEXT
         || '-' || EXTRACT(YEAR FROM d)::TEXT           AS trimestre_label,
    EXTRACT(ISODOW FROM d) IN (6, 7)                    AS es_fin_semana
FROM GENERATE_SERIES(
    '2020-01-01'::DATE,
    '2030-12-31'::DATE,
    '1 day'::INTERVAL
) AS g(d);

-- Fila especial para fechas desconocidas / nulas
INSERT INTO olap.dim_fecha (
    fecha_sk, fecha, anio, trimestre, mes, semana_anio,
    dia_mes, dia_semana, nombre_mes, nombre_dia,
    trimestre_label, es_fin_semana
) VALUES (
    0, '1900-01-01', 1900, 1, 1, 1, 1, 1,
    'Desconocido', 'Desconocido', 'Q0-0000', FALSE
);
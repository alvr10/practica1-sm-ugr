-- ============================================================
-- DIMENSIÓN: dim_producto
-- Origen OLTP: oltp_ventas.productos + oltp_ventas.categorias
--              + oltp_inventario.costes_producto
--              + oltp_inventario.proveedores
-- Tipo SCD: Tipo 2 — se versionan cambios en precio, coste, categoría
-- Conformada: SÍ — fact_ventas_linea + fact_inventario
-- ============================================================

CREATE TABLE olap.dim_producto (
    producto_sk         SERIAL       NOT NULL,   -- Surrogate Key (PK del DW)
    producto_nk         INT          NOT NULL,   -- Natural Key (producto_id OLTP)
    nombre              VARCHAR(150) NOT NULL,
    sku                 VARCHAR(50)  NOT NULL,
    categoria           VARCHAR(100) NOT NULL,
    descripcion_cat     TEXT,
    marca               VARCHAR(100),
    precio_venta        NUMERIC(10,2) NOT NULL,
    precio_ipsi         NUMERIC(10,2) NOT NULL,
    coste_unitario      NUMERIC(10,2),           -- de oltp_inventario
    margen_bruto        NUMERIC(10,2),           -- precio_venta - coste_unitario
    moneda_coste        VARCHAR(10)  DEFAULT 'EUR',
    proveedor_nombre    VARCHAR(150),            -- desnormalizado desde proveedores
    proveedor_pais      VARCHAR(100),
    activo_producto     BOOLEAN      NOT NULL DEFAULT TRUE,
    -- Columnas SCD Tipo 2
    fecha_inicio        DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin           DATE         NOT NULL DEFAULT '9999-12-31',
    es_version_actual   BOOLEAN      NOT NULL DEFAULT TRUE,
    version             INT          NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_producto PRIMARY KEY (producto_sk)
);

CREATE INDEX idx_dim_producto_nk      ON olap.dim_producto(producto_nk);
CREATE INDEX idx_dim_producto_sku     ON olap.dim_producto(sku);
CREATE INDEX idx_dim_producto_actual  ON olap.dim_producto(producto_nk, es_version_actual);

-- -------------------------------------------------------
-- PROCEDIMIENTO SCD Tipo 2: upsert_dim_producto
-- Lógica:
--   1. Si el producto no existe → INSERT nueva fila v1
--   2. Si existe y hay cambio en atributos clave →
--        EXPIRE la fila actual (fecha_fin = hoy - 1, es_version_actual = FALSE)
--        INSERT nueva fila con version+1
--   3. Si no hay cambios → no hace nada (idempotente)
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE olap.upsert_dim_producto(p_producto_nk INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_current     olap.dim_producto%ROWTYPE;
    v_src         RECORD;
    v_has_changes BOOLEAN := FALSE;
BEGIN
    -- Leer datos actuales del origen (JOIN entre esquemas OLTP)
    SELECT
        p.producto_id,
        p.nombre,
        p.sku,
        c.nombre          AS categoria,
        c.descripcion     AS descripcion_cat,
        p.marca,
        p.precio_venta,
        p.precio_ipsi,
        cp.coste_unitario,
        p.precio_venta - COALESCE(cp.coste_unitario, 0) AS margen_bruto,
        COALESCE(cp.moneda, 'EUR')   AS moneda_coste,
        pv.nombre         AS proveedor_nombre,
        pv.pais_origen    AS proveedor_pais,
        p.activo          AS activo_producto
    INTO v_src
    FROM oltp_ventas.productos p
    JOIN oltp_ventas.categorias c        ON c.categoria_id   = p.categoria_id
    LEFT JOIN oltp_inventario.costes_producto cp ON cp.producto_id = p.producto_id
    LEFT JOIN oltp_inventario.proveedores pv     ON pv.proveedor_id = cp.proveedor_id
    WHERE p.producto_id = p_producto_nk;

    -- Buscar versión actual en la dimensión
    SELECT * INTO v_current
    FROM olap.dim_producto
    WHERE producto_nk = p_producto_nk
      AND es_version_actual = TRUE
    LIMIT 1;

    IF NOT FOUND THEN
        -- Caso 1: Producto nuevo → INSERT v1
        INSERT INTO olap.dim_producto (
            producto_nk, nombre, sku, categoria, descripcion_cat, marca,
            precio_venta, precio_ipsi, coste_unitario, margen_bruto,
            moneda_coste, proveedor_nombre, proveedor_pais, activo_producto,
            fecha_inicio, fecha_fin, es_version_actual, version
        ) VALUES (
            v_src.producto_id, v_src.nombre, v_src.sku, v_src.categoria,
            v_src.descripcion_cat, v_src.marca, v_src.precio_venta,
            v_src.precio_ipsi, v_src.coste_unitario, v_src.margen_bruto,
            v_src.moneda_coste, v_src.proveedor_nombre, v_src.proveedor_pais,
            v_src.activo_producto,
            CURRENT_DATE, '9999-12-31', TRUE, 1
        );
    ELSE
        -- Detectar cambios en atributos versionables
        IF v_current.precio_venta   <> v_src.precio_venta
        OR v_current.coste_unitario IS DISTINCT FROM v_src.coste_unitario
        OR v_current.categoria      <> v_src.categoria
        OR v_current.activo_producto <> v_src.activo_producto
        THEN
            v_has_changes := TRUE;
        END IF;

        IF v_has_changes THEN
            -- Caso 2a: Expirar versión actual
            UPDATE olap.dim_producto
            SET fecha_fin          = CURRENT_DATE - INTERVAL '1 day',
                es_version_actual  = FALSE
            WHERE producto_sk = v_current.producto_sk;

            -- Caso 2b: Insertar nueva versión
            INSERT INTO olap.dim_producto (
                producto_nk, nombre, sku, categoria, descripcion_cat, marca,
                precio_venta, precio_ipsi, coste_unitario, margen_bruto,
                moneda_coste, proveedor_nombre, proveedor_pais, activo_producto,
                fecha_inicio, fecha_fin, es_version_actual, version
            ) VALUES (
                v_src.producto_id, v_src.nombre, v_src.sku, v_src.categoria,
                v_src.descripcion_cat, v_src.marca, v_src.precio_venta,
                v_src.precio_ipsi, v_src.coste_unitario, v_src.margen_bruto,
                v_src.moneda_coste, v_src.proveedor_nombre, v_src.proveedor_pais,
                v_src.activo_producto,
                CURRENT_DATE, '9999-12-31', TRUE, v_current.version + 1
            );
        END IF;
        -- Caso 3: Sin cambios → no-op
    END IF;
END;
$$;
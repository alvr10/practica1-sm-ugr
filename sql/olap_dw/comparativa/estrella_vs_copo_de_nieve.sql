-- ============================================================
-- COMPARATIVA: Modelo Estrella vs Modelo Copo de Nieve
-- Caso de ejemplo: dim_producto (estrella) → normalizada (copo)
-- ============================================================

-- ============================================================
-- A) MODELO ESTRELLA (Star Schema) — YA IMPLEMENTADO
-- ============================================================
-- En el modelo estrella, dim_producto es plana (desnormalizada):
-- todos los atributos de categoría y proveedor están inline.
--
--   fact_ventas_linea
--        │
--        └── dim_producto  ←── TODO aquí: nombre, sku, categoria,
--                               marca, precio, coste, proveedor_nombre,
--                               proveedor_pais ... (fila ancha)
--
-- VENTAJAS del estrella:
--   + Una sola JOIN para llegar a todos los atributos descriptivos
--   + Mejor rendimiento en queries de BI / OLAP
--   + Más sencillo para usuarios finales y herramientas de BI
--   - Redundancia de datos (categoría repetida en cada fila de producto)
--   - Actualizar nombre de categoría requiere tocar muchas filas (SCD2 versiones)

-- Ya definida en dim_producto.sql — se muestra aquí solo la firma:
/*
CREATE TABLE olap.dim_producto (
    producto_sk      SERIAL,
    producto_nk      INT,
    nombre           VARCHAR(150),
    sku              VARCHAR(50),
    categoria        VARCHAR(100),      ← desnormalizado
    descripcion_cat  TEXT,              ← desnormalizado
    marca            VARCHAR(100),
    precio_venta     NUMERIC(10,2),
    coste_unitario   NUMERIC(10,2),
    proveedor_nombre VARCHAR(150),      ← desnormalizado
    proveedor_pais   VARCHAR(100),      ← desnormalizado
    ...
);
*/


-- ============================================================
-- B) MODELO COPO DE NIEVE (Snowflake Schema)
-- ============================================================
-- Se normalizan los atributos repetidos en sub-dimensiones propias.
-- dim_producto ahora solo tiene FKs a dim_categoria y dim_proveedor_sn.
--
--   fact_ventas_linea
--        │
--        └── dim_producto_sn  ──→  dim_categoria_sn
--                            └──→  dim_proveedor_sn
--
-- VENTAJAS del copo:
--   + Sin redundancia: un cambio en el nombre de categoría se hace en 1 fila
--   + Menor espacio en disco para dimensiones muy grandes
--   - Más JOINs en cada query analítica
--   - Mayor complejidad para los usuarios de BI
--   - Menor rendimiento en queries (más JOINs = más I/O)

-- Sub-dimensión: categorías normalizadas
CREATE TABLE olap.dim_categoria_sn (
    categoria_sk    SERIAL       NOT NULL,
    categoria_nk    INT          NOT NULL,  -- categoria_id OLTP
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    activa          BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_dim_categoria_sn PRIMARY KEY (categoria_sk),
    CONSTRAINT uq_dim_categoria_nk UNIQUE (categoria_nk)
);

INSERT INTO olap.dim_categoria_sn (categoria_nk, nombre, descripcion, activa)
SELECT categoria_id, nombre, descripcion, activa
FROM oltp_ventas.categorias
ON CONFLICT (categoria_nk) DO UPDATE
    SET nombre      = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion,
        activa      = EXCLUDED.activa;

-- Sub-dimensión: proveedores normalizados (reutiliza dim_proveedor ya creada)
-- → en copo de nieve, dim_producto_sn apuntaría a olap.dim_proveedor(proveedor_sk)

-- dim_producto en versión Snowflake (normalizada)
CREATE TABLE olap.dim_producto_sn (
    producto_sk       SERIAL        NOT NULL,
    producto_nk       INT           NOT NULL,
    nombre            VARCHAR(150)  NOT NULL,
    sku               VARCHAR(50)   NOT NULL,
    -- FKs a sub-dimensiones (aquí está la diferencia vs estrella)
    categoria_sk      INT           NOT NULL,   -- → dim_categoria_sn
    proveedor_sk      INT,                      -- → dim_proveedor
    marca             VARCHAR(100),
    precio_venta      NUMERIC(10,2) NOT NULL,
    precio_ipsi       NUMERIC(10,2) NOT NULL,
    coste_unitario    NUMERIC(10,2),
    moneda_coste      VARCHAR(10)   DEFAULT 'EUR',
    activo_producto   BOOLEAN       NOT NULL DEFAULT TRUE,
    -- SCD Tipo 2
    fecha_inicio      DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin         DATE          NOT NULL DEFAULT '9999-12-31',
    es_version_actual BOOLEAN       NOT NULL DEFAULT TRUE,
    version           INT           NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_producto_sn PRIMARY KEY (producto_sk),
    CONSTRAINT fk_dpsn_categoria  FOREIGN KEY (categoria_sk)  REFERENCES olap.dim_categoria_sn(categoria_sk),
    CONSTRAINT fk_dpsn_proveedor  FOREIGN KEY (proveedor_sk)  REFERENCES olap.dim_proveedor(proveedor_sk)
);

CREATE INDEX idx_dpsn_nk       ON olap.dim_producto_sn(producto_nk);
CREATE INDEX idx_dpsn_actual   ON olap.dim_producto_sn(producto_nk, es_version_actual);
CREATE INDEX idx_dpsn_cat      ON olap.dim_producto_sn(categoria_sk);


-- ============================================================
-- COMPARATIVA DE QUERY: Ventas por categoría
-- ============================================================

-- ESTRELLA: 1 JOIN basta (dim_producto ya tiene 'categoria')
/*
SELECT
    dp.categoria,
    SUM(fvl.importe_neto) AS total_ventas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto dp ON dp.producto_sk = fvl.producto_sk
GROUP BY dp.categoria
ORDER BY total_ventas DESC;
*/

-- COPO DE NIEVE: necesita 2 JOINs (producto → categoria)
/*
SELECT
    dc.nombre         AS categoria,
    SUM(fvl.importe_neto) AS total_ventas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto_sn dp   ON dp.producto_sk  = fvl.producto_sk
JOIN olap.dim_categoria_sn dc  ON dc.categoria_sk = dp.categoria_sk
GROUP BY dc.nombre
ORDER BY total_ventas DESC;
*/

-- ============================================================
-- COMPARATIVA DE QUERY: Top producto por proveedor y país
-- ============================================================

-- ESTRELLA: 1 JOIN (proveedor_pais ya está en dim_producto)
/*
SELECT
    dp.proveedor_nombre,
    dp.proveedor_pais,
    dp.nombre AS producto,
    SUM(fvl.cantidad) AS unidades_vendidas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto dp ON dp.producto_sk = fvl.producto_sk
GROUP BY dp.proveedor_nombre, dp.proveedor_pais, dp.nombre
ORDER BY unidades_vendidas DESC;
*/

-- COPO DE NIEVE: necesita 3 JOINs (ventas → producto → proveedor)
/*
SELECT
    pv.nombre  AS proveedor,
    pv.pais_origen,
    dp.nombre  AS producto,
    SUM(fvl.cantidad) AS unidades_vendidas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto_sn dp   ON dp.producto_sk  = fvl.producto_sk
JOIN olap.dim_proveedor   pv   ON pv.proveedor_sk = dp.proveedor_sk
GROUP BY pv.nombre, pv.pais_origen, dp.nombre
ORDER BY unidades_vendidas DESC;
*/


-- ============================================================
-- TABLA RESUMEN DE DECISIÓN
-- ============================================================
--
-- | Criterio                  | ESTRELLA       | COPO DE NIEVE     |
-- |---------------------------|----------------|-------------------|
-- | Nº de JOINs en queries    | Mínimo (1-2)   | Más (+1 por nivel)|
-- | Rendimiento OLAP          | ★★★★★          | ★★★               |
-- | Espacio en disco          | Mayor          | Menor             |
-- | Facilidad para BI tools   | Alta           | Media             |
-- | Consistencia de atributos | Redundancia    | Centralizada      |
-- | Mantenimiento ETL         | Simple         | Más complejo      |
-- | Recomendado para          | DW Analítico   | DM + muchas dims  |
-- ============================================================
-- CONCLUSIÓN para Ceuta Connect:
--   → Usar ESTRELLA como modelo principal del Data Warehouse.
--   → Considerar COPO solo si dim_categoria crece mucho en atributos
--     (ej. jerarquías: linea → familia → categoría → subcategoría)
-- ============================================================
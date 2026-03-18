-- ============================================================
-- ETL: Carga Inicial de Dimensiones de Soporte (Tipo 1)
-- Ejecutar ANTES que cualquier tabla de hechos
-- ============================================================

-- 1. dim_proveedor
INSERT INTO olap.dim_proveedor (proveedor_nk, nombre, pais_origen, contacto, email, telefono, cif, activo)
SELECT proveedor_id, nombre, pais_origen, contacto, email, telefono, cif, activo
FROM oltp_inventario.proveedores
ON CONFLICT (proveedor_nk) DO UPDATE
    SET nombre      = EXCLUDED.nombre,
        pais_origen = EXCLUDED.pais_origen,
        activo      = EXCLUDED.activo;

-- 2. dim_transportista
INSERT INTO olap.dim_transportista (transportista_nk, nombre, cif, tipo_servicio, agente_aduanas, activo)
SELECT transportista_id, nombre, cif, tipo_servicio, agente_aduanas, activo
FROM oltp_logistica.transportistas
ON CONFLICT (transportista_nk) DO UPDATE
    SET nombre        = EXCLUDED.nombre,
        tipo_servicio = EXCLUDED.tipo_servicio,
        activo        = EXCLUDED.activo;

-- 3. dim_cliente (SCD2 — llamar al procedimiento por cada cliente)
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT cliente_id FROM oltp_ventas.clientes LOOP
        CALL olap.upsert_dim_cliente(r.cliente_id);
    END LOOP;
END;
$$;

-- 4. dim_empleado (SCD2)
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT empleado_id FROM oltp_rrhh.empleados LOOP
        CALL olap.upsert_dim_empleado(r.empleado_id);
    END LOOP;
END;
$$;

-- 5. dim_producto (SCD2)
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT producto_id FROM oltp_ventas.productos LOOP
        CALL olap.upsert_dim_producto(r.producto_id);
    END LOOP;
END;
$$;


-- ============================================================
-- ETL: Carga de fact_ventas_linea
-- ============================================================
INSERT INTO olap.fact_ventas_linea (
    fecha_sk,
    producto_sk,
    cliente_sk,
    empleado_sk,
    canal_sk,
    impuesto_sk,
    pedido_nk,
    detalle_nk,
    estado_pedido,
    cantidad,
    precio_unitario,
    descuento_pct,
    importe_bruto,
    importe_descuento,
    importe_neto,
    importe_impuesto,
    importe_total,
    coste_linea,
    margen_linea
)
SELECT
    -- Lookup fecha_sk
    TO_CHAR(p.fecha_pedido, 'YYYYMMDD')::INT             AS fecha_sk,

    -- Lookup producto_sk (versión vigente en la fecha del pedido)
    dp.producto_sk,

    -- Lookup cliente_sk (versión vigente en la fecha del pedido)
    dc.cliente_sk,

    -- Lookup empleado_sk (versión vigente en la fecha del pedido)
    de.empleado_sk,

    -- Lookup canal_sk
    can.canal_sk,

    -- Lookup impuesto_sk: usamos la tasa IPSI del detalle
    COALESCE(
        (SELECT impuesto_sk FROM olap.dim_impuesto
         WHERE tipo_impuesto = 'IPSI'
           AND pct_impuesto  = dp2.tasa_ipsi_pct
         LIMIT 1),
        (SELECT impuesto_sk FROM olap.dim_impuesto WHERE tipo_impuesto = 'EXENTO' LIMIT 1)
    )                                                     AS impuesto_sk,

    p.pedido_id                                           AS pedido_nk,
    dp2.detalle_id                                        AS detalle_nk,
    p.estado                                              AS estado_pedido,

    dp2.cantidad,
    dp2.precio_unitario,
    COALESCE(p.descuento_pct, 0)                         AS descuento_pct,

    -- Cálculo de importes
    dp2.cantidad * dp2.precio_unitario                    AS importe_bruto,

    ROUND(dp2.cantidad * dp2.precio_unitario
          * COALESCE(p.descuento_pct, 0) / 100, 2)       AS importe_descuento,

    ROUND(dp2.cantidad * dp2.precio_unitario
          * (1 - COALESCE(p.descuento_pct, 0) / 100), 2) AS importe_neto,

    ROUND(dp2.cantidad * dp2.precio_unitario
          * (1 - COALESCE(p.descuento_pct, 0) / 100)
          * dp2.tasa_ipsi_pct / 100, 2)                   AS importe_impuesto,

    ROUND(dp2.cantidad * dp2.precio_unitario
          * (1 - COALESCE(p.descuento_pct, 0) / 100)
          * (1 + dp2.tasa_ipsi_pct / 100), 2)             AS importe_total,

    dp2.cantidad * COALESCE(cp.coste_unitario, 0)         AS coste_linea,

    ROUND(
        dp2.cantidad * dp2.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100)
        - dp2.cantidad * COALESCE(cp.coste_unitario, 0), 2
    )                                                     AS margen_linea

FROM oltp_ventas.detalle_pedido dp2
JOIN oltp_ventas.pedidos p
    ON p.pedido_id = dp2.pedido_id

-- Lookup dim_producto: versión actual (carga inicial: solo existe una versión)
JOIN olap.dim_producto dp
    ON dp.producto_nk      = dp2.producto_id
   AND dp.es_version_actual = TRUE

-- Lookup dim_cliente: versión actual
JOIN olap.dim_cliente dc
    ON dc.cliente_nk       = p.cliente_id
   AND dc.es_version_actual = TRUE

-- Lookup dim_empleado: versión actual
JOIN olap.dim_empleado de
    ON de.empleado_nk      = p.empleado_id
   AND de.es_version_actual = TRUE

-- Lookup dim_canal
JOIN olap.dim_canal can
    ON can.canal_nk        = p.canal

-- Coste unitario del inventario (LEFT: puede no existir)
LEFT JOIN oltp_inventario.costes_producto cp
    ON cp.producto_id = dp2.producto_id

ON CONFLICT (pedido_nk, detalle_nk) DO NOTHING;   -- idempotente


-- ============================================================
-- ETL: Carga de fact_inventario
-- ============================================================
INSERT INTO olap.fact_inventario (
    fecha_sk,
    producto_sk,
    proveedor_sk,
    ubicacion_sk,
    movimiento_nk,
    tipo_movimiento,
    referencia,
    cantidad_movimiento,
    cantidad_stock_post,
    coste_unitario,
    coste_total
)
SELECT
    TO_CHAR(m.fecha, 'YYYYMMDD')::INT   AS fecha_sk,

    dp.producto_sk,

    prov.proveedor_sk,

    ub.ubicacion_sk,

    m.movimiento_id                      AS movimiento_nk,
    m.tipo                               AS tipo_movimiento,
    m.referencia,

    m.cantidad                           AS cantidad_movimiento,

    s.cantidad                           AS cantidad_stock_post,

    cp.coste_unitario,

    m.cantidad * COALESCE(cp.coste_unitario, 0) AS coste_total

FROM oltp_inventario.movimientos m

JOIN olap.dim_producto dp
    ON dp.producto_nk = m.producto_id AND dp.es_version_actual = TRUE

LEFT JOIN oltp_inventario.costes_producto cp
    ON cp.producto_id = m.producto_id

LEFT JOIN olap.dim_proveedor prov
    ON prov.proveedor_nk = cp.proveedor_id

JOIN olap.dim_ubicacion ub
    ON ub.ubicacion_nk = m.ubicacion

LEFT JOIN oltp_inventario.stock s
    ON s.producto_id = m.producto_id AND s.ubicacion = m.ubicacion

ON CONFLICT (movimiento_nk) DO NOTHING;


-- ============================================================
-- ETL: Carga de fact_envios
-- ============================================================
INSERT INTO olap.fact_envios (
    fecha_salida_sk,
    fecha_entrega_est_sk,
    fecha_entrega_real_sk,
    cliente_sk,
    transportista_sk,
    pedido_nk,
    envio_nk,
    estado_envio,
    provincia_destino,
    ciudad_destino,
    coste_envio,
    peso_kg,
    dias_transito_real,
    dias_retraso,
    coste_tramite_aduanas,
    horas_demora_aduanas,
    coste_total_logistica
)
SELECT
    TO_CHAR(e.fecha_salida,       'YYYYMMDD')::INT   AS fecha_salida_sk,
    TO_CHAR(e.fecha_entrega_est,  'YYYYMMDD')::INT   AS fecha_entrega_est_sk,
    COALESCE(TO_CHAR(e.fecha_entrega_real, 'YYYYMMDD')::INT, 0) AS fecha_entrega_real_sk,

    dc.cliente_sk,
    dt.transportista_sk,

    e.pedido_id          AS pedido_nk,
    e.envio_id           AS envio_nk,
    e.estado_envio,
    e.provincia_destino,
    e.ciudad_destino,

    e.coste_envio,
    e.peso_kg,

    CASE WHEN e.fecha_entrega_real IS NOT NULL
         THEN e.fecha_entrega_real - e.fecha_salida
         ELSE NULL END   AS dias_transito_real,

    CASE WHEN e.fecha_entrega_real IS NOT NULL
         THEN e.fecha_entrega_real - e.fecha_entrega_est
         ELSE NULL END   AS dias_retraso,

    COALESCE(ta.coste_tramite, 0)   AS coste_tramite_aduanas,
    COALESCE(ta.horas_demora,  0)   AS horas_demora_aduanas,
    e.coste_envio + COALESCE(ta.coste_tramite, 0) AS coste_total_logistica

FROM oltp_logistica.envios e

JOIN oltp_ventas.pedidos p ON p.pedido_id = e.pedido_id

JOIN olap.dim_cliente dc
    ON dc.cliente_nk = p.cliente_id
   AND dc.es_version_actual = TRUE

JOIN olap.dim_transportista dt
    ON dt.transportista_nk = e.transportista_id

LEFT JOIN oltp_logistica.tramites_aduanas ta
    ON ta.envio_id = e.envio_id

ON CONFLICT (envio_nk) DO NOTHING;


-- ============================================================
-- ETL: Carga de fact_pagos
-- ============================================================
INSERT INTO olap.fact_pagos (
    fecha_pago_sk,
    fecha_emision_sk,
    fecha_vencimiento_sk,
    cliente_sk,
    impuesto_sk,
    pago_nk,
    factura_nk,
    pedido_nk,
    num_factura,
    metodo_pago,
    estado_factura,
    importe_pago,
    importe_bruto_fac,
    importe_impuesto,
    importe_total_fac,
    dias_hasta_pago
)
SELECT
    TO_CHAR(pg.fecha_pago,     'YYYYMMDD')::INT  AS fecha_pago_sk,
    TO_CHAR(f.fecha_emision,   'YYYYMMDD')::INT  AS fecha_emision_sk,
    TO_CHAR(f.fecha_vencimiento,'YYYYMMDD')::INT AS fecha_vencimiento_sk,

    dc.cliente_sk,

    COALESCE(
        (SELECT impuesto_sk FROM olap.dim_impuesto
         WHERE tipo_impuesto = f.tipo_impuesto
           AND pct_impuesto  = f.pct_impuesto
         LIMIT 1),
        (SELECT impuesto_sk FROM olap.dim_impuesto WHERE tipo_impuesto = 'EXENTO' LIMIT 1)
    )                                           AS impuesto_sk,

    pg.pago_id       AS pago_nk,
    f.factura_id     AS factura_nk,
    f.pedido_id      AS pedido_nk,
    f.num_factura,
    pg.metodo        AS metodo_pago,
    f.estado         AS estado_factura,

    pg.importe       AS importe_pago,
    f.importe_bruto  AS importe_bruto_fac,
    f.importe_impuesto,
    f.importe_total  AS importe_total_fac,

    pg.fecha_pago - f.fecha_emision AS dias_hasta_pago

FROM oltp_finanzas.pagos pg
JOIN oltp_finanzas.facturas f  ON f.factura_id = pg.factura_id
JOIN olap.dim_cliente dc
    ON dc.cliente_nk = f.cliente_id
   AND dc.es_version_actual = TRUE

ON CONFLICT (pago_nk) DO NOTHING;


-- ============================================================
-- ETL: Carga de fact_comisiones
-- ============================================================
INSERT INTO olap.fact_comisiones (
    fecha_sk,
    empleado_sk,
    comision_nk,
    pedido_nk,
    importe_comision,
    pct_aplicado,
    importe_meta_trim
)
SELECT
    TO_CHAR(c.fecha, 'YYYYMMDD')::INT   AS fecha_sk,

    de.empleado_sk,

    c.comision_id    AS comision_nk,
    c.pedido_id      AS pedido_nk,
    c.importe        AS importe_comision,
    c.pct_aplicado,

    -- Objetivo del trimestre correspondiente a la fecha de la comisión
    (
        SELECT o.importe_meta
        FROM oltp_rrhh.objetivos o
        WHERE o.empleado_id = c.empleado_id
          AND o.anio        = EXTRACT(YEAR    FROM c.fecha)
          AND o.trimestre   = EXTRACT(QUARTER FROM c.fecha)
        LIMIT 1
    )                                   AS importe_meta_trim

FROM oltp_rrhh.comisiones c
JOIN olap.dim_empleado de
    ON de.empleado_nk = c.empleado_id
   AND de.es_version_actual = TRUE

ON CONFLICT (comision_nk) DO NOTHING;
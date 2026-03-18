-- ============================================================
-- ETL: Carga Incremental (Delta Load)
-- Estrategia: cargar solo registros nuevos o modificados
-- desde la última fecha de carga (watermark)
-- ============================================================

-- -------------------------------------------------------
-- Tabla de control de cargas (watermark)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS olap.etl_control (
    proceso         VARCHAR(50) PRIMARY KEY,
    ultima_carga    TIMESTAMP NOT NULL DEFAULT '1970-01-01',
    filas_cargadas  INT       NOT NULL DEFAULT 0,
    duracion_seg    NUMERIC(8,2),
    estado          VARCHAR(20) NOT NULL DEFAULT 'ok'
);

INSERT INTO olap.etl_control (proceso) VALUES
    ('fact_ventas_linea'),
    ('fact_inventario'),
    ('fact_envios'),
    ('fact_pagos'),
    ('fact_comisiones')
ON CONFLICT (proceso) DO NOTHING;


-- -------------------------------------------------------
-- Procedimiento de carga incremental: fact_ventas_linea
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE olap.etl_incremental_ventas()
LANGUAGE plpgsql AS $$
DECLARE
    v_desde     TIMESTAMP;
    v_inicio    TIMESTAMP := NOW();
    v_filas     INT;
BEGIN
    SELECT ultima_carga INTO v_desde FROM olap.etl_control WHERE proceso = 'fact_ventas_linea';

    -- SCD2: re-evaluar versiones de dimensiones para pedidos recientes
    -- (si un cliente o producto cambió, sus SKs habrán cambiado)
    INSERT INTO olap.fact_ventas_linea (
        fecha_sk, producto_sk, cliente_sk, empleado_sk,
        canal_sk, impuesto_sk,
        pedido_nk, detalle_nk, estado_pedido,
        cantidad, precio_unitario, descuento_pct,
        importe_bruto, importe_descuento, importe_neto,
        importe_impuesto, importe_total, coste_linea, margen_linea
    )
    SELECT
        TO_CHAR(p.fecha_pedido, 'YYYYMMDD')::INT,
        dp.producto_sk,
        dc.cliente_sk,
        de.empleado_sk,
        can.canal_sk,
        COALESCE(
            (SELECT impuesto_sk FROM olap.dim_impuesto
             WHERE tipo_impuesto = 'IPSI' AND pct_impuesto = dp2.tasa_ipsi_pct LIMIT 1),
            (SELECT impuesto_sk FROM olap.dim_impuesto WHERE tipo_impuesto = 'EXENTO' LIMIT 1)
        ),
        p.pedido_id, dp2.detalle_id, p.estado,
        dp2.cantidad, dp2.precio_unitario, COALESCE(p.descuento_pct, 0),
        dp2.cantidad * dp2.precio_unitario,
        ROUND(dp2.cantidad * dp2.precio_unitario * COALESCE(p.descuento_pct,0)/100, 2),
        ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100), 2),
        ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100) * dp2.tasa_ipsi_pct/100, 2),
        ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100) * (1 + dp2.tasa_ipsi_pct/100), 2),
        dp2.cantidad * COALESCE(cp.coste_unitario, 0),
        ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100)
              - dp2.cantidad * COALESCE(cp.coste_unitario, 0), 2)
    FROM oltp_ventas.detalle_pedido dp2
    JOIN oltp_ventas.pedidos p         ON p.pedido_id = dp2.pedido_id
    JOIN olap.dim_producto dp          ON dp.producto_nk = dp2.producto_id
                                      AND p.fecha_pedido BETWEEN dp.fecha_inicio AND dp.fecha_fin
    JOIN olap.dim_cliente dc           ON dc.cliente_nk = p.cliente_id
                                      AND p.fecha_pedido BETWEEN dc.fecha_inicio AND dc.fecha_fin
    JOIN olap.dim_empleado de          ON de.empleado_nk = p.empleado_id
                                      AND p.fecha_pedido BETWEEN de.fecha_inicio AND de.fecha_fin
    JOIN olap.dim_canal can            ON can.canal_nk = p.canal
    LEFT JOIN oltp_inventario.costes_producto cp ON cp.producto_id = dp2.producto_id
    -- Filtro delta: solo pedidos desde la última carga
    WHERE p.fecha_pedido >= v_desde::DATE

    ON CONFLICT (pedido_nk, detalle_nk) DO UPDATE
        SET estado_pedido = EXCLUDED.estado_pedido;  -- actualizar estado si cambió

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    UPDATE olap.etl_control
    SET ultima_carga   = NOW(),
        filas_cargadas = v_filas,
        duracion_seg   = EXTRACT(EPOCH FROM NOW() - v_inicio),
        estado         = 'ok'
    WHERE proceso = 'fact_ventas_linea';

    RAISE NOTICE 'ETL fact_ventas_linea: % filas en % seg',
        v_filas, ROUND(EXTRACT(EPOCH FROM NOW() - v_inicio)::NUMERIC, 2);
END;
$$;
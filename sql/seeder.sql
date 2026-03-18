-- ============================================================
-- SEEDER: Ceuta Connect — Carga de datos OLTP + OLAP
--
-- ⚠️  Prerrequisito: ejecutar schema.sql antes que este script.
--     La estructura de tablas debe existir.
--
-- Ejecutar desde la raíz del repositorio:
--   psql -U postgres -d ceutaconnect -f sql/seeder.sql
-- ============================================================

-- 1. Datos maestros y transaccionales OLTP
\i sql/dml-schemas/01_dml_ventas.sql
\i sql/dml-schemas/02_dml_rrhh.sql
\i sql/dml-schemas/03_dml_inventario.sql
\i sql/dml-schemas/04_dml_logistica.sql
\i sql/dml-schemas/05_dml_finanzas.sql
\i sql/dml-schemas/06_dml_transacciones.sql

-- 2. Carga ETL: OLTP → OLAP (dimensiones + hechos)
\i sql/olap_dw/etl/etl_carga_completa.sql

-- ============================================================
-- Verificación de registros por tabla
-- ============================================================
SELECT tabla, registros FROM (
    SELECT 'oltp_ventas.categorias'         AS tabla, COUNT(*) AS registros FROM oltp_ventas.categorias        UNION ALL
    SELECT 'oltp_ventas.productos',                   COUNT(*) FROM oltp_ventas.productos                      UNION ALL
    SELECT 'oltp_ventas.clientes',                    COUNT(*) FROM oltp_ventas.clientes                       UNION ALL
    SELECT 'oltp_ventas.pedidos',                     COUNT(*) FROM oltp_ventas.pedidos                        UNION ALL
    SELECT 'oltp_ventas.detalle_pedido',              COUNT(*) FROM oltp_ventas.detalle_pedido                 UNION ALL
    SELECT 'oltp_rrhh.departamentos',                 COUNT(*) FROM oltp_rrhh.departamentos                    UNION ALL
    SELECT 'oltp_rrhh.empleados',                     COUNT(*) FROM oltp_rrhh.empleados                        UNION ALL
    SELECT 'oltp_rrhh.comisiones',                    COUNT(*) FROM oltp_rrhh.comisiones                       UNION ALL
    SELECT 'oltp_rrhh.objetivos',                     COUNT(*) FROM oltp_rrhh.objetivos                        UNION ALL
    SELECT 'oltp_inventario.proveedores',             COUNT(*) FROM oltp_inventario.proveedores                UNION ALL
    SELECT 'oltp_inventario.costes_producto',         COUNT(*) FROM oltp_inventario.costes_producto            UNION ALL
    SELECT 'oltp_inventario.stock',                   COUNT(*) FROM oltp_inventario.stock                      UNION ALL
    SELECT 'oltp_inventario.movimientos',             COUNT(*) FROM oltp_inventario.movimientos                UNION ALL
    SELECT 'oltp_logistica.transportistas',           COUNT(*) FROM oltp_logistica.transportistas              UNION ALL
    SELECT 'oltp_logistica.rutas',                    COUNT(*) FROM oltp_logistica.rutas                       UNION ALL
    SELECT 'oltp_logistica.envios',                   COUNT(*) FROM oltp_logistica.envios                      UNION ALL
    SELECT 'oltp_logistica.tramites_aduanas',         COUNT(*) FROM oltp_logistica.tramites_aduanas            UNION ALL
    SELECT 'oltp_finanzas.liquidaciones',             COUNT(*) FROM oltp_finanzas.liquidaciones                UNION ALL
    SELECT 'oltp_finanzas.gastos',                    COUNT(*) FROM oltp_finanzas.gastos                       UNION ALL
    SELECT 'oltp_finanzas.facturas',                  COUNT(*) FROM oltp_finanzas.facturas                     UNION ALL
    SELECT 'oltp_finanzas.pagos',                     COUNT(*) FROM oltp_finanzas.pagos                        UNION ALL
    -- Tablas OLAP
    SELECT 'olap.dim_fecha',                          COUNT(*) FROM olap.dim_fecha                             UNION ALL
    SELECT 'olap.dim_producto',                       COUNT(*) FROM olap.dim_producto                          UNION ALL
    SELECT 'olap.dim_cliente',                        COUNT(*) FROM olap.dim_cliente                           UNION ALL
    SELECT 'olap.dim_empleado',                       COUNT(*) FROM olap.dim_empleado                          UNION ALL
    SELECT 'olap.dim_proveedor',                      COUNT(*) FROM olap.dim_proveedor                         UNION ALL
    SELECT 'olap.dim_transportista',                  COUNT(*) FROM olap.dim_transportista                     UNION ALL
    SELECT 'olap.dim_canal',                          COUNT(*) FROM olap.dim_canal                             UNION ALL
    SELECT 'olap.dim_ubicacion',                      COUNT(*) FROM olap.dim_ubicacion                         UNION ALL
    SELECT 'olap.dim_impuesto',                       COUNT(*) FROM olap.dim_impuesto                          UNION ALL
    SELECT 'olap.fact_ventas_linea',                  COUNT(*) FROM olap.fact_ventas_linea                     UNION ALL
    SELECT 'olap.fact_inventario',                    COUNT(*) FROM olap.fact_inventario                       UNION ALL
    SELECT 'olap.fact_envios',                        COUNT(*) FROM olap.fact_envios                           UNION ALL
    SELECT 'olap.fact_pagos',                         COUNT(*) FROM olap.fact_pagos                            UNION ALL
    SELECT 'olap.fact_comisiones',                    COUNT(*) FROM olap.fact_comisiones
) t
ORDER BY tabla;

DO $$
BEGIN
    RAISE NOTICE '✔ Seeder completado — OLTP + OLAP poblados.';
END;
$$;
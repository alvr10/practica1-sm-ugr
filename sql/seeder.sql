-- ============================================================
-- MASTER SEEDER: Ceuta Connect – OLTP completo
--
-- Ejecutar desde la raíz del repositorio:
--   psql -U postgres -d ceutaconnect -f sql/seeder.sql
-- ============================================================

-- 1. Crear esquemas
CREATE SCHEMA IF NOT EXISTS oltp_ventas;
CREATE SCHEMA IF NOT EXISTS oltp_rrhh;
CREATE SCHEMA IF NOT EXISTS oltp_inventario;
CREATE SCHEMA IF NOT EXISTS oltp_logistica;
CREATE SCHEMA IF NOT EXISTS oltp_finanzas;

-- ============================================================
-- 2. DDL — Definición de tablas por esquema
-- ============================================================
\i sql/ddl-schemas/01_ddl_ventas.sql
\i sql/ddl-schemas/02_ddl_rrhh.sql
\i sql/ddl-schemas/03_ddl_inventario.sql
\i sql/ddl-schemas/04_ddl_logistica.sql
\i sql/ddl-schemas/05_ddl_finanzas.sql

-- ============================================================
-- 3. DML — Datos maestros y transaccionales
-- ============================================================
\i sql/dml-schemas/01_dml_ventas.sql
\i sql/dml-schemas/02_dml_rrhh.sql
\i sql/dml-schemas/03_dml_inventario.sql
\i sql/dml-schemas/04_dml_logistica.sql
\i sql/dml-schemas/05_dml_finanzas.sql
\i sql/dml-schemas/06_dml_transacciones.sql

-- ============================================================
-- 4. Verificación de registros por tabla
-- ============================================================
SELECT tabla, registros FROM (
    SELECT 'oltp_ventas.categorias'          AS tabla, COUNT(*) AS registros FROM oltp_ventas.categorias     UNION ALL
    SELECT 'oltp_ventas.productos',                    COUNT(*) FROM oltp_ventas.productos                   UNION ALL
    SELECT 'oltp_ventas.clientes',                     COUNT(*) FROM oltp_ventas.clientes                    UNION ALL
    SELECT 'oltp_ventas.pedidos',                      COUNT(*) FROM oltp_ventas.pedidos                     UNION ALL
    SELECT 'oltp_ventas.detalle_pedido',                COUNT(*) FROM oltp_ventas.detalle_pedido              UNION ALL
    SELECT 'oltp_rrhh.departamentos',                  COUNT(*) FROM oltp_rrhh.departamentos                 UNION ALL
    SELECT 'oltp_rrhh.empleados',                      COUNT(*) FROM oltp_rrhh.empleados                     UNION ALL
    SELECT 'oltp_rrhh.comisiones',                     COUNT(*) FROM oltp_rrhh.comisiones                    UNION ALL
    SELECT 'oltp_rrhh.objetivos',                      COUNT(*) FROM oltp_rrhh.objetivos                     UNION ALL
    SELECT 'oltp_inventario.proveedores',              COUNT(*) FROM oltp_inventario.proveedores              UNION ALL
    SELECT 'oltp_inventario.costes_producto',          COUNT(*) FROM oltp_inventario.costes_producto          UNION ALL
    SELECT 'oltp_inventario.stock',                    COUNT(*) FROM oltp_inventario.stock                   UNION ALL
    SELECT 'oltp_inventario.movimientos',              COUNT(*) FROM oltp_inventario.movimientos              UNION ALL
    SELECT 'oltp_logistica.transportistas',            COUNT(*) FROM oltp_logistica.transportistas           UNION ALL
    SELECT 'oltp_logistica.rutas',                     COUNT(*) FROM oltp_logistica.rutas                    UNION ALL
    SELECT 'oltp_logistica.envios',                    COUNT(*) FROM oltp_logistica.envios                   UNION ALL
    SELECT 'oltp_logistica.tramites_aduanas',          COUNT(*) FROM oltp_logistica.tramites_aduanas         UNION ALL
    SELECT 'oltp_finanzas.liquidaciones',              COUNT(*) FROM oltp_finanzas.liquidaciones              UNION ALL
    SELECT 'oltp_finanzas.gastos',                     COUNT(*) FROM oltp_finanzas.gastos                    UNION ALL
    SELECT 'oltp_finanzas.facturas',                   COUNT(*) FROM oltp_finanzas.facturas                  UNION ALL
    SELECT 'oltp_finanzas.pagos',                      COUNT(*) FROM oltp_finanzas.pagos
) t
ORDER BY tabla;
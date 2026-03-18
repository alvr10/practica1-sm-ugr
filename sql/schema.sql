-- ============================================================
-- MASTER DDL: Ceuta Connect — Estructura completa OLTP + OLAP
--
-- Crea todos los esquemas y tablas sin insertar ningún dato.
-- Útil para despliegues en producción, CI/CD o revisión de esquema.
--
-- Ejecutar desde la raíz del repositorio:
--   psql -U postgres -d ceutaconnect -f sql/schema.sql
-- ============================================================

-- 1. Esquemas OLTP
CREATE SCHEMA IF NOT EXISTS oltp_ventas;
CREATE SCHEMA IF NOT EXISTS oltp_rrhh;
CREATE SCHEMA IF NOT EXISTS oltp_inventario;
CREATE SCHEMA IF NOT EXISTS oltp_logistica;
CREATE SCHEMA IF NOT EXISTS oltp_finanzas;

-- 2. DDL OLTP
\i sql/ddl-schemas/01_ddl_ventas.sql
\i sql/ddl-schemas/02_ddl_rrhh.sql
\i sql/ddl-schemas/03_ddl_inventario.sql
\i sql/ddl-schemas/04_ddl_logistica.sql
\i sql/ddl-schemas/05_ddl_finanzas.sql

-- 3. Esquema OLAP
\i sql/olap_dw/00_bus_matrix.sql

-- 4. Dimensiones (orden: sin FK primero, luego SCD2)
\i sql/olap_dw/dimensions/dim_fecha.sql
\i sql/olap_dw/dimensions/dim_soporte.sql
\i sql/olap_dw/dimensions/dim_cliente.sql
\i sql/olap_dw/dimensions/dim_empleado.sql
\i sql/olap_dw/dimensions/dim_producto.sql

-- 5. Tablas de hechos
\i sql/olap_dw/facts/fact_ventas_linea.sql
\i sql/olap_dw/facts/fact_inventario.sql
\i sql/olap_dw/facts/fact_envios.sql
\i sql/olap_dw/facts/fact_pagos.sql
\i sql/olap_dw/facts/fact_comisiones.sql

-- 6. Comparativa Snowflake (estructuras adicionales, opcional)
\i sql/olap_dw/comparativa/estrella_vs_copo_de_nieve.sql

-- ============================================================
-- Verificación de estructura creada
-- ============================================================
SELECT
    schemaname   AS esquema,
    tablename    AS tabla
FROM pg_tables
WHERE schemaname IN (
    'oltp_ventas','oltp_rrhh','oltp_inventario',
    'oltp_logistica','oltp_finanzas','olap'
)
ORDER BY schemaname, tablename;

DO $$
BEGIN
    RAISE NOTICE '✔ schema.sql completado — estructura lista, sin datos.';
END;
$$;
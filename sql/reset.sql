-- ============================================================
-- RESET: Ceuta Connect — Limpieza completa OLTP + OLAP
--
-- ⚠️  ADVERTENCIA: Elimina TODOS los datos, tablas y esquemas.
--     Úsalo solo en entorno de desarrollo.
--
-- Flujo de trabajo habitual:
--   psql -U postgres -d ceutaconnect -f sql/reset.sql
--   psql -U postgres -d ceutaconnect -f sql/schema.sql
--   psql -U postgres -d ceutaconnect -f sql/seeder.sql
-- ============================================================

-- Orden inverso de dependencias: OLAP primero, luego OLTP
DROP SCHEMA IF EXISTS olap              CASCADE;
DROP SCHEMA IF EXISTS oltp_finanzas     CASCADE;
DROP SCHEMA IF EXISTS oltp_logistica    CASCADE;
DROP SCHEMA IF EXISTS oltp_inventario   CASCADE;
DROP SCHEMA IF EXISTS oltp_rrhh         CASCADE;
DROP SCHEMA IF EXISTS oltp_ventas       CASCADE;

DO $$
BEGIN
    RAISE NOTICE '✔ Reset completado. Ejecuta schema.sql y luego seeder.sql para repoblar.';
END;
$$;
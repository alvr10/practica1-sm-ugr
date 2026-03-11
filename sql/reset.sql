-- ============================================================
-- RESET: Ceuta Connect – Limpieza completa de esquemas OLTP
--
-- ⚠️  ADVERTENCIA: Este script elimina TODOS los datos y tablas.
--     Úsalo solo en entorno de desarrollo.
--
-- Uso:
--   psql -U postgres -d ceutaconnect -f sql/reset.sql
--   psql -U postgres -d ceutaconnect -f sql/seeder.sql
-- ============================================================

-- CASCADE elimina tablas, índices, constraints y FK en cadena
DROP SCHEMA IF EXISTS oltp_finanzas   CASCADE;
DROP SCHEMA IF EXISTS oltp_logistica  CASCADE;
DROP SCHEMA IF EXISTS oltp_inventario CASCADE;
DROP SCHEMA IF EXISTS oltp_rrhh       CASCADE;
DROP SCHEMA IF EXISTS oltp_ventas     CASCADE;

-- Confirmación
DO $$
BEGIN
    RAISE NOTICE '✔ Reset completado. Ejecuta seeder.sql para repoblar.';
END;
$$;
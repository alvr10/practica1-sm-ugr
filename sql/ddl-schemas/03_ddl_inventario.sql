
-- ============================================================
-- ESQUEMA: oltp_inventario
-- Descripción: Inventario de Ceuta Connect
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp_inventario;

-- Tabla de proveedores
CREATE TABLE oltp_inventario.proveedores (
    proveedor_id SERIAL PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL,
    pais_origen  VARCHAR(100) NOT NULL,
    contacto     VARCHAR(150),
    email        VARCHAR(150),
    telefono     VARCHAR(30),
    cif          VARCHAR(20) UNIQUE,
    activo       BOOLEAN NOT NULL DEFAULT TRUE
);

-- Tabla de costes por producto (referencia cruzada a oltp_ventas.productos)
CREATE TABLE oltp_inventario.costes_producto (
    producto_id    INT PRIMARY KEY,  -- FK cruzada → oltp_ventas.productos
    proveedor_id   INT NOT NULL REFERENCES oltp_inventario.proveedores(proveedor_id),
    coste_unitario NUMERIC(10,2) NOT NULL CHECK (coste_unitario > 0),
    moneda         VARCHAR(10) NOT NULL DEFAULT 'EUR',
    ultima_actualizacion DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_costes_proveedor ON oltp_inventario.costes_producto(proveedor_id);

-- Tabla de stock en almacén Ceuta
CREATE TABLE oltp_inventario.stock (
    stock_id     SERIAL PRIMARY KEY,
    producto_id  INT NOT NULL,  -- FK cruzada → oltp_ventas.productos
    ubicacion    VARCHAR(50) NOT NULL DEFAULT 'Almacén Ceuta'
                 CHECK (ubicacion IN ('Almacén Ceuta','Almacén Algeciras','Almacén Málaga')),
    cantidad     INT NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    stock_minimo INT NOT NULL DEFAULT 5  CHECK (stock_minimo >= 0),
    ultima_entrada DATE,
    UNIQUE (producto_id, ubicacion)
);

CREATE INDEX idx_stock_producto ON oltp_inventario.stock(producto_id);

-- Tabla de movimientos de inventario
CREATE TABLE oltp_inventario.movimientos (
    movimiento_id SERIAL PRIMARY KEY,
    producto_id   INT NOT NULL,
    tipo          VARCHAR(20) NOT NULL
                  CHECK (tipo IN ('entrada','salida','ajuste','devolucion')),
    cantidad      INT NOT NULL CHECK (cantidad > 0),
    ubicacion     VARCHAR(50) NOT NULL,
    fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
    referencia    VARCHAR(100),   -- nº pedido, albarán, etc.
    notas         TEXT
);

CREATE INDEX idx_movimientos_producto ON oltp_inventario.movimientos(producto_id);
CREATE INDEX idx_movimientos_fecha ON oltp_inventario.movimientos(fecha);

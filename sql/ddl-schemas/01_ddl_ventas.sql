-- ============================================================
-- ESQUEMA: oltp_ventas
-- Descripción: Sistema operacional de ventas de Ceuta Connect
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp_ventas;

-- Tabla de categorías de productos tecnológicos
CREATE TABLE oltp_ventas.categorias (
    categoria_id   SERIAL PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL UNIQUE,
    descripcion    TEXT,
    activa         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_categorias_nombre ON oltp_ventas.categorias(nombre);

-- Tabla de productos de hardware tecnológico
CREATE TABLE oltp_ventas.productos (
    producto_id    SERIAL PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    sku            VARCHAR(50)  NOT NULL UNIQUE,
    categoria_id   INT NOT NULL REFERENCES oltp_ventas.categorias(categoria_id),
    precio_venta   NUMERIC(10,2) NOT NULL CHECK (precio_venta > 0),
    precio_ipsi    NUMERIC(10,2) NOT NULL CHECK (precio_ipsi > 0),
    marca          VARCHAR(100),
    activo         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_productos_categoria ON oltp_ventas.productos(categoria_id);
CREATE INDEX idx_productos_sku ON oltp_ventas.productos(sku);

-- Tabla de clientes
CREATE TABLE oltp_ventas.clientes (
    cliente_id     SERIAL PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    telefono       VARCHAR(20),
    direccion      VARCHAR(200),
    ciudad         VARCHAR(100),
    provincia      VARCHAR(100),
    codigo_postal  VARCHAR(10),
    pais           VARCHAR(100) NOT NULL DEFAULT 'España',
    cif            VARCHAR(20) UNIQUE,
    fecha_alta     DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_clientes_provincia ON oltp_ventas.clientes(provincia);
CREATE INDEX idx_clientes_email ON oltp_ventas.clientes(email);

-- Tabla de pedidos (referencia cruzada a oltp_rrhh.empleados)
CREATE TABLE oltp_ventas.pedidos (
    pedido_id      SERIAL PRIMARY KEY,
    cliente_id     INT NOT NULL REFERENCES oltp_ventas.clientes(cliente_id),
    empleado_id    INT NOT NULL,  -- FK cruzada → oltp_rrhh.empleados
    fecha_pedido   DATE NOT NULL DEFAULT CURRENT_DATE,
    estado         VARCHAR(30) NOT NULL DEFAULT 'pendiente'
                   CHECK (estado IN ('pendiente','confirmado','enviado','entregado','cancelado')),
    canal          VARCHAR(30) NOT NULL DEFAULT 'web'
                   CHECK (canal IN ('web','telefono','marketplace')),
    descuento_pct  NUMERIC(5,2) DEFAULT 0 CHECK (descuento_pct >= 0 AND descuento_pct <= 100),
    notas          TEXT
);

CREATE INDEX idx_pedidos_cliente ON oltp_ventas.pedidos(cliente_id);
CREATE INDEX idx_pedidos_fecha ON oltp_ventas.pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_empleado ON oltp_ventas.pedidos(empleado_id);

-- Tabla de detalle de pedido
CREATE TABLE oltp_ventas.detalle_pedido (
    detalle_id      SERIAL PRIMARY KEY,
    pedido_id       INT NOT NULL REFERENCES oltp_ventas.pedidos(pedido_id),
    producto_id     INT NOT NULL REFERENCES oltp_ventas.productos(producto_id),
    cantidad        INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario > 0),
    tasa_ipsi_pct   NUMERIC(5,2) NOT NULL DEFAULT 0,
    UNIQUE (pedido_id, producto_id)
);

CREATE INDEX idx_detalle_pedido ON oltp_ventas.detalle_pedido(pedido_id);
CREATE INDEX idx_detalle_producto ON oltp_ventas.detalle_pedido(producto_id);

-- ============================================================
-- ESQUEMA: oltp_logistica
-- Descripción: Logística de Ceuta Connect
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp_logistica;

-- Tabla de transportistas
CREATE TABLE oltp_logistica.transportistas (
    transportista_id SERIAL PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    cif              VARCHAR(20) UNIQUE,
    tipo_servicio    VARCHAR(50) NOT NULL
                     CHECK (tipo_servicio IN ('express','estandar','maritimo','terrestre')),
    agente_aduanas   VARCHAR(150),
    telefono         VARCHAR(30),
    email            VARCHAR(150),
    activo           BOOLEAN NOT NULL DEFAULT TRUE
);

-- Tabla de envíos (referencia cruzada a oltp_ventas.pedidos)
CREATE TABLE oltp_logistica.envios (
    envio_id          SERIAL PRIMARY KEY,
    pedido_id         INT NOT NULL UNIQUE,  -- FK cruzada → oltp_ventas.pedidos
    transportista_id  INT NOT NULL REFERENCES oltp_logistica.transportistas(transportista_id),
    fecha_salida      DATE NOT NULL,
    fecha_entrega_est DATE NOT NULL,
    fecha_entrega_real DATE,
    coste_envio       NUMERIC(10,2) NOT NULL CHECK (coste_envio >= 0),
    ciudad_destino    VARCHAR(100) NOT NULL,
    provincia_destino VARCHAR(100) NOT NULL,
    codigo_postal     VARCHAR(10),
    estado_envio      VARCHAR(30) NOT NULL DEFAULT 'en_transito'
                      CHECK (estado_envio IN ('preparando','en_transito','aduanas','entregado','devuelto')),
    peso_kg           NUMERIC(8,2) CHECK (peso_kg > 0)
);

CREATE INDEX idx_envios_pedido ON oltp_logistica.envios(pedido_id);
CREATE INDEX idx_envios_transportista ON oltp_logistica.envios(transportista_id);
CREATE INDEX idx_envios_provincia ON oltp_logistica.envios(provincia_destino);

-- Tabla de trámites aduaneros (DUA)
CREATE TABLE oltp_logistica.tramites_aduanas (
    tramite_id       SERIAL PRIMARY KEY,
    envio_id         INT NOT NULL REFERENCES oltp_logistica.envios(envio_id),
    num_dua          VARCHAR(50) NOT NULL UNIQUE,
    fecha_despacho   DATE NOT NULL,
    fecha_liberacion DATE,
    coste_tramite    NUMERIC(10,2) NOT NULL DEFAULT 0,
    incidencia       TEXT,
    horas_demora     NUMERIC(6,2) DEFAULT 0
);

CREATE INDEX idx_tramites_envio ON oltp_logistica.tramites_aduanas(envio_id);
CREATE INDEX idx_tramites_fecha ON oltp_logistica.tramites_aduanas(fecha_despacho);

-- Tabla de rutas logísticas
CREATE TABLE oltp_logistica.rutas (
    ruta_id          SERIAL PRIMARY KEY,
    transportista_id INT NOT NULL REFERENCES oltp_logistica.transportistas(transportista_id),
    origen           VARCHAR(100) NOT NULL DEFAULT 'Ceuta',
    destino          VARCHAR(100) NOT NULL,
    dias_transito    INT NOT NULL CHECK (dias_transito > 0),
    coste_base       NUMERIC(10,2) NOT NULL CHECK (coste_base >= 0),
    activa           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_rutas_transportista ON oltp_logistica.rutas(transportista_id);

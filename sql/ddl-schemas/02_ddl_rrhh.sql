-- ============================================================
-- ESQUEMA: oltp_rrhh
-- Descripción: Recursos Humanos de Ceuta Connect
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp_rrhh;

-- Tabla de departamentos internos
CREATE TABLE oltp_rrhh.departamentos (
    departamento_id SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL UNIQUE,
    descripcion     TEXT
);

-- Tabla de empleados
CREATE TABLE oltp_rrhh.empleados (
    empleado_id     SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    apellidos       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    nif             VARCHAR(15) NOT NULL UNIQUE,
    departamento_id INT NOT NULL REFERENCES oltp_rrhh.departamentos(departamento_id),
    territorio      VARCHAR(100) NOT NULL
                    CHECK (territorio IN ('Ceuta','Sur','Norte','Centro','Este','Oeste')),
    cargo           VARCHAR(100) NOT NULL,
    fecha_alta      DATE NOT NULL DEFAULT CURRENT_DATE,
    salario_base    NUMERIC(10,2) NOT NULL CHECK (salario_base > 0),
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_empleados_departamento ON oltp_rrhh.empleados(departamento_id);
CREATE INDEX idx_empleados_territorio ON oltp_rrhh.empleados(territorio);

-- Tabla de comisiones por venta
CREATE TABLE oltp_rrhh.comisiones (
    comision_id  SERIAL PRIMARY KEY,
    empleado_id  INT NOT NULL REFERENCES oltp_rrhh.empleados(empleado_id),
    pedido_id    INT NOT NULL,  -- FK cruzada → oltp_ventas.pedidos
    importe      NUMERIC(10,2) NOT NULL CHECK (importe >= 0),
    pct_aplicado NUMERIC(5,2)  NOT NULL CHECK (pct_aplicado >= 0),
    fecha        DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_comisiones_empleado ON oltp_rrhh.comisiones(empleado_id);
CREATE INDEX idx_comisiones_fecha ON oltp_rrhh.comisiones(fecha);

-- Tabla de objetivos comerciales por territorio
CREATE TABLE oltp_rrhh.objetivos (
    objetivo_id  SERIAL PRIMARY KEY,
    empleado_id  INT NOT NULL REFERENCES oltp_rrhh.empleados(empleado_id),
    anio         INT NOT NULL CHECK (anio >= 2020),
    trimestre    INT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    importe_meta NUMERIC(12,2) NOT NULL CHECK (importe_meta > 0),
    UNIQUE (empleado_id, anio, trimestre)
);

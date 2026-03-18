# Práctica 1 — Sistemas Multidimensionales

**Alumno:** Álvaro Ríos Rodríguez
**Universidad:** Universidad de Granada
**Asignatura:** Sistemas Multidimensionales

---

## Descripción del proyecto

Diseño e implementación del sistema multidimensional para **Ceuta Connect**, empresa de distribución de hardware tecnológico de alta gama con sede en Ceuta. La empresa aprovecha el régimen fiscal IPSI para ofrecer precios competitivos frente a la competencia peninsular, y enfrenta una operativa compleja por la gestión de aduanas (DUA) y los costes logísticos del Estrecho.

---

## Estructura del repositorio

```
practica1-sm-ugr/
├── README.md
├── docs/                                      ← Diagramas ER por esquema
│   ├── oltp_ventas.png
│   ├── oltp_rrhh.png
│   ├── oltp_inventario.png
│   ├── oltp_logistica.png
│   └── oltp_finanzas.png
└── sql/
    ├── schema.sql                             ← DDL puro: crea todos los esquemas y tablas
    ├── seeder.sql                             ← DML: inserta datos OLTP y dispara ETL → OLAP
    ├── reset.sql                              ← Elimina todos los esquemas (dev only)
    │
    ├── ddl-schemas/                           ← Definición de tablas OLTP por esquema
    │   ├── 01_ddl_ventas.sql
    │   ├── 02_ddl_rrhh.sql
    │   ├── 03_ddl_inventario.sql
    │   ├── 04_ddl_logistica.sql
    │   └── 05_ddl_finanzas.sql
    │
    ├── dml-schemas/                           ← Datos sintéticos OLTP por esquema
    │   ├── 01_dml_ventas.sql
    │   ├── 02_dml_rrhh.sql
    │   ├── 03_dml_inventario.sql
    │   ├── 04_dml_logistica.sql
    │   ├── 05_dml_finanzas.sql
    │   └── 06_dml_transacciones.sql           ← Pedidos, envíos, facturas, pagos
    │
    └── olap_dw/                               ← Data Warehouse dimensional (esquema olap)
        ├── 00_bus_matrix.sql                  ← Bus Matrix + CREATE SCHEMA olap
        │
        ├── dimensions/                        ← Tablas de dimensiones con lógica SCD
        │   ├── dim_fecha.sql                  ← Date Spine 2020–2030 (conformada)
        │   ├── dim_producto.sql               ← SCD Tipo 2
        │   ├── dim_cliente.sql                ← SCD Tipo 2
        │   ├── dim_empleado.sql               ← SCD Tipo 2
        │   └── dim_soporte.sql                ← SCD Tipo 1: canal, ubicacion, impuesto,
        │                                           proveedor, transportista
        ├── facts/                             ← Tablas de hechos (Star Schema)
        │   ├── fact_ventas_linea.sql          ← Granularidad: línea de pedido
        │   ├── fact_inventario.sql            ← Granularidad: movimiento de stock
        │   ├── fact_envios.sql                ← Granularidad: envío logístico
        │   ├── fact_pagos.sql                 ← Granularidad: pago recibido
        │   └── fact_comisiones.sql            ← Granularidad: comisión comercial
        │
        ├── etl/                               ← Scripts de carga OLTP → OLAP
        │   ├── etl_carga_completa.sql         ← Carga inicial (INSERT INTO … SELECT)
        │   └── etl_incremental.sql            ← Delta load con watermark (etl_control)
        │
        └── comparativa/
            └── estrella_vs_copo_de_nieve.sql  ← Normalización Snowflake sobre dim_producto
```

---

## Arquitectura OLTP — 5 Esquemas

| Esquema           | Tablas                                                   | Descripción                         |
|-------------------|----------------------------------------------------------|-------------------------------------|
| `oltp_ventas`     | categorias, productos, clientes, pedidos, detalle_pedido | Sistema de ventas online            |
| `oltp_rrhh`       | departamentos, empleados, comisiones, objetivos          | Gestión de personal y comerciales   |
| `oltp_inventario` | proveedores, costes_producto, stock, movimientos         | Control de stock en almacenes       |
| `oltp_logistica`  | transportistas, rutas, envios, tramites_aduanas          | Envíos y gestión DUA del Estrecho   |
| `oltp_finanzas`   | facturas, liquidaciones, gastos, pagos                   | Facturación IPSI/IVA y contabilidad |

### Relaciones cruzadas entre esquemas

| Origen                            | Campo         | Destino                 |
|-----------------------------------|---------------|-------------------------|
| `oltp_ventas.pedidos`             | `empleado_id` | `oltp_rrhh.empleados`   |
| `oltp_inventario.costes_producto` | `producto_id` | `oltp_ventas.productos` |
| `oltp_inventario.stock`           | `producto_id` | `oltp_ventas.productos` |
| `oltp_logistica.envios`           | `pedido_id`   | `oltp_ventas.pedidos`   |
| `oltp_finanzas.facturas`          | `pedido_id`   | `oltp_ventas.pedidos`   |
| `oltp_finanzas.facturas`          | `cliente_id`  | `oltp_ventas.clientes`  |
| `oltp_rrhh.comisiones`            | `pedido_id`   | `oltp_ventas.pedidos`   |

---

## Arquitectura OLAP — Modelo Estrella

El esquema `olap` implementa un **Star Schema** con 5 tablas de hechos y 9 dimensiones.

### Bus Matrix — Dimensiones conformadas por proceso

|                      | Ventas | Inventario | Logística | Finanzas | RRHH |
|----------------------|:------:|:----------:|:---------:|:--------:|:----:|
| `dim_fecha`          |   ✓    |     ✓      |     ✓     |    ✓     |  ✓   |
| `dim_producto`       |   ✓    |     ✓      |           |          |      |
| `dim_cliente`        |   ✓    |            |     ✓     |    ✓     |      |
| `dim_empleado`       |   ✓    |            |           |          |  ✓   |
| `dim_proveedor`      |        |     ✓      |           |          |      |
| `dim_transportista`  |        |            |     ✓     |          |      |
| `dim_canal`          |   ✓    |            |           |          |      |
| `dim_ubicacion`      |        |     ✓      |     ✓     |          |      |
| `dim_impuesto`       |   ✓    |            |           |    ✓     |      |

### Tablas de hechos

| Tabla                | Granularidad              | Medidas principales                              |
|----------------------|---------------------------|--------------------------------------------------|
| `fact_ventas_linea`  | Línea de pedido           | cantidad, importe_neto, margen_linea             |
| `fact_inventario`    | Movimiento de stock       | cantidad_movimiento, coste_total                 |
| `fact_envios`        | Envío logístico           | coste_envio, dias_retraso, coste_tramite_aduanas |
| `fact_pagos`         | Pago recibido             | importe_pago, dias_hasta_pago                    |
| `fact_comisiones`    | Comisión comercial        | importe_comision, importe_meta_trim              |

### SCD — Slowly Changing Dimensions

| Dimensión          | Tipo SCD | Atributos versionados                          |
|--------------------|----------|------------------------------------------------|
| `dim_producto`     | Tipo 2   | precio_venta, coste_unitario, categoria        |
| `dim_cliente`      | Tipo 2   | direccion, ciudad, provincia, email            |
| `dim_empleado`     | Tipo 2   | cargo, departamento, territorio, salario_base  |
| Resto              | Tipo 1   | Sobrescritura directa                          |

---

## Volumen de datos

| Esquema         | Tabla            | Registros |
|-----------------|------------------|-----------|
| oltp_ventas     | categorias       | 8         |
| oltp_ventas     | productos        | 50        |
| oltp_ventas     | clientes         | 50        |
| oltp_ventas     | pedidos          | 50        |
| oltp_ventas     | detalle_pedido   | ~100      |
| oltp_rrhh       | empleados        | 15        |
| oltp_rrhh       | objetivos        | 24        |
| oltp_rrhh       | comisiones       | 30        |
| oltp_inventario | proveedores      | 10        |
| oltp_inventario | stock            | 54        |
| oltp_inventario | movimientos      | 13        |
| oltp_logistica  | transportistas   | 10        |
| oltp_logistica  | rutas            | 20        |
| oltp_logistica  | envios           | 40        |
| oltp_logistica  | tramites_aduanas | 34        |
| oltp_finanzas   | facturas         | 40        |
| oltp_finanzas   | pagos            | 36        |
| oltp_finanzas   | gastos           | 50+       |
| oltp_finanzas   | liquidaciones    | 16        |
| **Total OLTP**  |                  | **~550+** |

---

## Cómo ejecutar

### Prerrequisitos

- PostgreSQL 14+
- Base de datos creada previamente:

```sql
CREATE DATABASE ceutaconnect;
```

### Flujo de trabajo recomendado

Desde la **raíz del repositorio**:

```bash
# 1. Crear toda la estructura (esquemas + tablas, sin datos)
psql -U postgres -d ceutaconnect -f sql/schema.sql

# 2. Poblar con datos OLTP y cargar el OLAP vía ETL
psql -U postgres -d ceutaconnect -f sql/seeder.sql

# 3. (Opcional) Borrar todo y volver a empezar
psql -U postgres -d ceutaconnect -f sql/reset.sql
```

### Ejecución manual por capas

```bash
# — DDL OLTP —
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/01_ddl_ventas.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/02_ddl_rrhh.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/03_ddl_inventario.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/04_ddl_logistica.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/05_ddl_finanzas.sql

# — DML OLTP —
psql -U postgres -d ceutaconnect -f sql/dml-schemas/01_dml_ventas.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/02_dml_rrhh.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/03_dml_inventario.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/04_dml_logistica.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/05_dml_finanzas.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/06_dml_transacciones.sql

# — ETL OLTP → OLAP —
psql -U postgres -d ceutaconnect -f sql/olap_dw/etl/etl_carga_completa.sql
```
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
/practica1-sm-ugr
├── /docs                              ← Diagramas ER y documentación
├── /sql
│   ├── seeder.sql                     ← Script maestro (ejecuta todo en orden)
│   ├── /ddl-schemas                   ← Definición de tablas por esquema
│   │   ├── 01_ddl_ventas.sql
│   │   ├── 02_ddl_rrhh.sql
│   │   ├── 03_ddl_inventario.sql
│   │   ├── 04_ddl_logistica.sql
│   │   └── 05_ddl_finanzas.sql
│   └── /dml-schemas                   ← Datos sintéticos por esquema
│       ├── 01_dml_ventas.sql
│       ├── 02_dml_rrhh.sql
│       ├── 03_dmL_inventario.sql
│       ├── 04_dml_logistica.sql
│       ├── 05_dml_finanzas.sql
│       └── 06_dml_transacciones.sql   ← Pedidos, envíos, facturas, pagos
└── README.md
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

---

## Relaciones cruzadas entre esquemas

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
| **Total**       |                  | **~550+** |

---

## Cómo ejecutar

### Prerrequisitos

- PostgreSQL 14+
- Base de datos creada previamente:

```sql
CREATE DATABASE ceutaconnect;
```

### Ejecución del seeder maestro

Desde la **raíz del repositorio**:

```bash
psql -U postgres -d ceutaconnect -f sql/seeder.sql
```

El script crea los esquemas, ejecuta todos los DDL en orden y pobla las tablas con datos sintéticos realistas. Al finalizar imprime un resumen de registros por tabla.

### Ejecución manual (archivo por archivo)

```bash
# DDL
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/01_ddl_ventas.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/02_ddl_rrhh.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/03_ddl_inventario.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/04_ddl_logistica.sql
psql -U postgres -d ceutaconnect -f sql/ddl-schemas/05_ddl_finanzas.sql

# DML
psql -U postgres -d ceutaconnect -f sql/dml-schemas/01_dml_ventas.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/02_dml_rrhh.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/03_dmL_inventario.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/04_dml_logistica.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/05_dml_finanzas.sql
psql -U postgres -d ceutaconnect -f sql/dml-schemas/06_dml_transacciones.sql
```
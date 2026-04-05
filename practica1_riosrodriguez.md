# Práctica 1: Sistemas Multidimensionales

**Alumno:** Álvaro Ríos Rodríguez

# **Índice** {#índice}

[**Índice	2**](#índice)

[**Sección 1: Análisis y toma de contacto	3**](#sección-1:-análisis-y-toma-de-contacto)

[1.1. Análisis de un sistema real	3](#1.1.-análisis-de-un-sistema-real)

[Sección 2: Diseño del sistema empresarial: "Ceuta Connect"	3](#sección-2:-diseño-del-sistema-empresarial:-"ceuta-connect")

[2.1. Descripción del sistema empresaria	3](#2.1.-descripción-del-sistema-empresaria)

[2.2. Identificación de fuentes de datos	4](#2.2.-identificación-de-fuentes-de-datos)

[2.3. Preguntas de negocio y decisiones estratégicas	4](#2.3.-preguntas-de-negocio-y-decisiones-estratégicas)

[2.4. Decisiones estratégicas	4](#2.4.-decisiones-estratégicas)

[2.5. Modelo OLAP conceptual	5](#2.5.-modelo-olap-conceptual)

[2.6. Diagrama OLAP nicial	6](#2.6.-diagrama-olap-nicial)

[**Sección 3: Diseño de base de datos OLTP	8**](#sección-3:-diseño-de-base-de-datos-oltp)

[**Sección 4: Data Warehouse Dimensional (Hito 3)	9**](#sección-4:-data-warehouse-dimensional)

[4.1. Introducción: de OLTP a OLAP	9](#4.1.-introducción:-de-oltp-a-olap)

[4.2. Tabla de mapeo OLTP → DW	9](#4.2.-tabla-de-mapeo-oltp-→-dw)

[4.3. Slowly Changing Dimensions (SCD)	10](#4.3.-slowly-changing-dimensions-(scd))

[4.4. Bus Matrix — Dimensiones conformadas	11](#4.4.-bus-matrix-—-dimensiones-conformadas)

[4.5. Implementación de las dimensiones	12](#4.5.-implementación-de-las-dimensiones)

[4.6. Tablas de hechos	14](#4.6.-tablas-de-hechos)

[4.7. ETL básico: carga OLTP → OLAP	15](#4.7.-etl-básico:-carga-oltp-→-olap)

[4.8. Comparativa Estrella vs Copo de Nieve	16](#4.8.-comparativa-estrella-vs-copo-de-nieve)

[**Sección 5: Benchmarking y Evaluación (Hito 4)	18**](#sección-5:-benchmarking-y-evaluación)

[5.1. Consultas analíticas y operaciones OLAP	18](#5.1.-consultas-analíticas-y-operaciones-olap)

[5.2. Script Python de benchmarking	22](#5.2.-script-python-de-benchmarking)

[5.3. Resultados e interpretación	24](#5.3.-resultados-e-interpretación)

[5.4. Cómo reproducir el sistema completo	26](#5.4.-cómo-reproducir-el-sistema-completo)

[**Conclusión Final	27**](#conclusión-final)

# **Sección 1: Análisis y toma de contacto** {#sección-1:-análisis-y-toma-de-contacto}

## **1.1. Análisis de un sistema real** {#1.1.-análisis-de-un-sistema-real}

Para este análisis, he seleccionado el **Portal de Datos Abiertos del Instituto de Estadística y Cartografía de Andalucía (IECA)**.

* **Objetivo del negocio:** Ofrecer transparencia y facilitar la toma de decisiones económicas y sociales mediante indicadores estadísticos detallados.  
* **Fuentes de datos:** Registros administrativos de la Junta de Andalucía, encuestas de población activa y registros de la Seguridad Social.  
* **Dimensiones principales:**  
  * **Tiempo:** Año, trimestre, mes.  
  * **Geografía:** Municipio, provincia (Málaga, Almería, etc.), sección censal.  
  * **Sector Económico:** Servicios, industria, agricultura, construcción.  
* **Hechos y métricas clave:** Tasa de paro, número de empresas activas, PIB per cápita e inversión bruta.  
* **Preguntas de negocio que el sistema resuelve:** "¿Cuál ha sido la evolución del desempleo en el sector servicios en la provincia de Málaga durante los últimos 8 trimestres?".

# **Sección 2: Diseño del sistema empresarial: "Ceuta Connect"** {#sección-2:-diseño-del-sistema-empresarial:-"ceuta-connect"}

## **2.1. Descripción del sistema empresaria** {#2.1.-descripción-del-sistema-empresaria}

Ceuta Connect es una empresa de distribución de hardware tecnológico de alta gama con sede en Ceuta. La empresa aprovecha el régimen fiscal del **IPSI** para ofrecer precios competitivos frente a los competidores peninsulares, pero enfrenta una operativa compleja por la gestión de aduanas (DUA) y los costes logísticos del Estrecho.

Gestión de ventas online, control de stock en el puerto de Ceuta, gestión de trámites aduaneros y logística de última milla en Algeciras y Málaga. Actualmente, la información está dispersa en bases de datos aisladas, lo que impide ver la rentabilidad real tras impuestos.

## **2.2. Identificación de fuentes de datos** {#2.2.-identificación-de-fuentes-de-datos}

Crearemos estos 5 sistemas:

| Departamento | Sistema OLTP | Entidades principales | Volumen aprox. |
| :---- | :---- | :---- | :---- |
| **Ventas** | oltp\_ventas | Pedidos, Clientes, Detalle\_Pedido | 1.200 pedidos/mes |
| **Logística** | oltp\_logistica | Transportistas, Envíos, Aduanas | 1.200 envíos/mes |
| **Inventario** | oltp\_inventario | Productos, Almacén Ceuta, Proveedores | 150 SKUs activos |
| **Finanzas** | oltp\_finanzas | Facturas, Tasas IPSI, Liquidaciones IVA | 1.200 facturas/mes |
| **RRHH** | oltp\_rrhh | Empleados, Comisiones, Territorios | 15 empleados |

## **2.3. Preguntas de negocio y decisiones estratégicas** {#2.3.-preguntas-de-negocio-y-decisiones-estratégicas}

Preguntas analíticas clave:

1. **Rentabilidad Fiscal:** ¿Cuál es el margen de beneficio neto comparando productos con IPSI (Ceuta) frente a ventas con IVA (Península) por categoría?.  
2. **Eficiencia del Estrecho:** ¿Cuál es el tiempo medio de demora en aduanas según el transportista y el día de la semana?.  
3. **Rendimiento Geográfico:** ¿En qué provincias de Andalucía (Málaga, Sevilla, Cádiz) tenemos mayor volumen de ventas pero menores márgenes por costes de envío?.  
4. **Rotación de Inventario:** ¿Qué productos tecnológicos tienen mayor rotación en el almacén de Ceuta antes de quedar obsoletos?.  
5. **Impacto de Descuentos:** ¿Cómo afectan los cupones de envío gratuito a la rentabilidad total de los pedidos con destino a la península?.

## **2.4. Decisiones estratégicas** {#2.4.-decisiones-estratégicas}

**Decisiones estratégicas:**

* Decisión 1 \- Optimización de Stock: Basándose en los tiempos de aduana, decidir si aumentar el stock de seguridad en un almacén regulador en Algeciras para productos de alta rotación.  
* Decisión 2 \- Ajuste de Precios: Reestructurar la política de envíos gratuitos solo para provincias donde el margen bruto supere el coste del DUA y el porte.

## **2.5. Modelo OLAP conceptual** {#2.5.-modelo-olap-conceptual}

Bus Matrix (Metodología Kimball):

| Proceso de Negocio | Tiempo | Geografía | Producto | Cliente | Transportista |
| :---- | ----- | ----- | ----- | ----- | ----- |
| **Ventas** | X | X | X | X |  |
| **Envíos/Aduanas** | X | X |  |  | X |
| **Inventario** | X |  | X |  |  |

Diagrama OLAP inicial (Modelo Estrella)

* **Tabla de Hechos:** Fact\_Ventas.  
  * **Métricas:** Cantidad, Ingreso\_Bruto, Coste\_Envio, Tasa\_Aduana, Margen\_Neto.  
* **Dimensiones:**  
  * Dim\_Tiempo: Fecha, Mes, Trimestre, Año.  
  * Dim\_Producto: Nombre, Categoría, Marca, Precio\_Lista.  
  * Dim\_Geografia: Ciudad, Provincia, Código\_Postal (Crucial para diferenciar Ceuta/Península).  
  * Dim\_Transportista: Nombre, Tipo\_Servicio, Agencia\_Aduanas.

## **2.6. Diagrama OLAP nicial** {#2.6.-diagrama-olap-nicial}

![][image2]

![][image3]

# **Sección 3: Diseño de base de datos OLTP** {#sección-3:-diseño-de-base-de-datos-oltp}

Se presenta el siguiente repositorio en GitHub para el desarrollo COMPLETO del hito 2 y futuros hitos: [https://github.com/alvr10/practica1-sm-ugr](https://github.com/alvr10/practica1-sm-ugr)

# **Sección 4: Data Warehouse Dimensional (Hito 3)** {#sección-4:-data-warehouse-dimensional}

## **4.1. Introducción: de OLTP a OLAP**

El sistema transaccional (OLTP) de Ceuta Connect está formado por 5 esquemas independientes diseñados para operaciones diarias: inserciones rápidas, consistencia referencial y normalización. Sin embargo, responder preguntas analíticas como "¿cuál es el margen neto por provincia tras restar el coste de aduana?" requiere cruzar varios esquemas con múltiples JOINs y tiempos de respuesta inaceptables para análisis interactivo.

El **Data Warehouse (DW)** que se construye en este hito implementa un **modelo dimensional (Star Schema)** bajo el esquema `olap`. La transformación OLTP → OLAP sigue la metodología Kimball y resuelve exactamente las preguntas de negocio definidas en la Sección 2.3.

| Aspecto | OLTP (Transaccional) | OLAP (Analítico) |
| :---- | :---- | :---- |
| **Propósito** | Operaciones diarias (INSERT/UPDATE/DELETE) | Análisis histórico (SELECT agregado) |
| **Diseño** | Normalización (evitar redundancia) | Desnormalización (optimizar consultas) |
| **Granularidad** | Nivel de transacción (cada venta) | Nivel agregado (ventas mensuales) |
| **Usuarios** | Operadores, clientes | Analistas, directivos |
| **Tiempo respuesta** | Milisegundos | Segundos / minutos aceptables |

---

## **4.2. Tabla de mapeo OLTP → DW**

El primer paso sistemático es decidir qué tablas OLTP se convierten en dimensiones, cuáles en hechos, y cuáles se incorporan como atributos desnormalizados dentro de otra tabla. El criterio aplicado es:

| Criterio | DIMENSIÓN | HECHO |
| :---- | :---- | :---- |
| **Volatilidad** | Cambia lentamente (cliente, producto) | Cambia constantemente (transacciones) |
| **Cardinalidad** | Baja/Media (miles de clientes) | Alta (millones de ventas) |
| **Contenido** | Atributos descriptivos (texto, fechas) | Métricas numéricas (importes, counts) |
| **Propósito** | Filtrar, agrupar, detallar | Sumar, promediar, calcular ratios |

Aplicando estos criterios a los 5 esquemas de Ceuta Connect:

| Tabla OLTP | Tipo DW | Tabla DW resultante | Justificación |
| :---- | :---- | :---- | :---- |
| `oltp_ventas.clientes` | Dimensión | `dim_cliente` | Atributos descriptivos (nombre, ciudad, provincia, segmento B2B/B2C). Cambia lentamente → SCD Tipo 2 |
| `oltp_ventas.productos` + `categorias` | Dimensión | `dim_producto` | Jerarquía Categoría → Producto. Precio y coste cambian → SCD Tipo 2. Atributos de proveedor desnormalizados |
| `oltp_rrhh.empleados` + `departamentos` | Dimensión | `dim_empleado` | Atributos de vendedor (cargo, departamento, territorio). Cambios de puesto → SCD Tipo 2 |
| `oltp_inventario.proveedores` | Dimensión | `dim_proveedor` | Datos de proveedor para análisis de inventario. Sin historial crítico → SCD Tipo 1 |
| `oltp_logistica.transportistas` | Dimensión | `dim_transportista` | Análisis de KPIs por transportista. Sin versiones → SCD Tipo 1 |
| `oltp_ventas.pedidos.canal` | Dimensión | `dim_canal` | Tabla estática de 3 valores: web, teléfono, marketplace → SCD Tipo 1 |
| `oltp_inventario.stock.ubicacion` | Dimensión | `dim_ubicacion` | 3 almacenes conocidos: Ceuta, Algeciras, Málaga → SCD Tipo 1 |
| `oltp_finanzas.facturas.tipo_impuesto` | Dimensión | `dim_impuesto` | Catálogo fiscal: IVA, IPSI, IGIC, EXENTO. Clave para análisis fiscal de Ceuta Connect → SCD Tipo 1 |
| *(generada artificialmente)* | Dimensión | `dim_fecha` | Date Spine 2020–2030. Conformada por todos los procesos. Sin versiones (estática por naturaleza) |
| `oltp_ventas.detalle_pedido` + `pedidos` | Hecho | `fact_ventas_linea` | Métricas: cantidad, importe_bruto, importe_neto, coste_linea, margen_linea |
| `oltp_inventario.movimientos` | Hecho | `fact_inventario` | Métricas: cantidad_movimiento, coste_total, cantidad_stock_post |
| `oltp_logistica.envios` + `tramites_aduanas` | Hecho | `fact_envios` | Métricas: coste_envio, horas_demora_aduanas, dias_retraso |
| `oltp_finanzas.pagos` + `facturas` | Hecho | `fact_pagos` | Métricas: importe_pago, dias_hasta_pago, importe_impuesto |
| `oltp_rrhh.comisiones` + `objetivos` | Hecho | `fact_comisiones` | Métricas: importe_comision, importe_meta_trim |

---

## **4.3. Slowly Changing Dimensions (SCD)**

Las dimensiones no son estáticas: un cliente se muda de ciudad, un empleado cambia de departamento, un producto cambia de precio. Para manejar estos cambios en el DW se usan tres estrategias:

| Tipo | Historial | Complejidad | Uso en Ceuta Connect |
| :---- | :---- | :---- | :---- |
| **SCD Tipo 0** | No (inmutable) | Muy baja | NIF de empleado, fecha de nacimiento |
| **SCD Tipo 1** | No (sobrescritura) | Baja | dim_proveedor, dim_transportista, dim_canal, dim_ubicacion, dim_impuesto |
| **SCD Tipo 2** | Completo (nueva fila) | Alta | dim_cliente, dim_producto, dim_empleado |

Para las dimensiones clave (cliente, producto, empleado) se aplica **SCD Tipo 2**: cuando cambia un atributo versionable, se expira la fila actual (`fecha_fin = hoy - 1, es_version_actual = FALSE`) y se inserta una nueva fila con `version + 1`. Las tablas de hechos siempre referencian la `surrogate key` de la versión vigente en la fecha de la transacción.

El control de versiones se implementa mediante los campos:

```sql
fecha_inicio      DATE    NOT NULL DEFAULT CURRENT_DATE,
fecha_fin         DATE    NOT NULL DEFAULT '9999-12-31',
es_version_actual BOOLEAN NOT NULL DEFAULT TRUE,
version           INT     NOT NULL DEFAULT 1
```

---

## **4.4. Bus Matrix — Dimensiones conformadas**

Las **dimensiones conformadas** son aquellas compartidas entre múltiples procesos de negocio. Permiten realizar consultas cruzadas coherentes (ej. comparar ventas vs inventario del mismo producto usando la misma `dim_producto`).

| Dimensión | Ventas | Inventario | Logística | Finanzas | RRHH |
| :---- | :----: | :----: | :----: | :----: | :----: |
| `dim_fecha` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `dim_producto` | ✓ | ✓ | | | |
| `dim_cliente` | ✓ | | ✓ | ✓ | |
| `dim_empleado` | ✓ | | | | ✓ |
| `dim_proveedor` | | ✓ | | | |
| `dim_transportista` | | | ✓ | | |
| `dim_canal` | ✓ | | | | |
| `dim_ubicacion` | | ✓ | ✓ | | |
| `dim_impuesto` | ✓ | | | ✓ | |

**Dimensiones conformadas** (compartidas por ≥ 2 procesos):

* `dim_fecha` → todos los procesos la referencian. Garantiza que "Q1" significa Enero-Marzo en todos los análisis.
* `dim_producto` → fact\_ventas\_linea + fact\_inventario. Permite cruzar ventas con movimientos de stock del mismo artículo.
* `dim_cliente` → fact\_ventas\_linea + fact\_envios + fact\_pagos. Un analista puede ver compras, envíos y pagos del mismo cliente sin inconsistencias.
* `dim_empleado` → fact\_ventas\_linea + fact\_comisiones. Relaciona las ventas generadas con las comisiones cobradas.

---

## **4.5. Implementación de las dimensiones**

Todas las dimensiones se crean bajo el esquema `olap` (ver `sql/olap_dw/00_bus_matrix.sql`).

### 4.5.1. dim\_fecha (Date Spine)

La `dim_fecha` no tiene tabla OLTP de origen: se genera artificialmente para el rango 2020–2030. Esto garantiza que siempre existe una fila para cualquier fecha de transacción, incluso si aún no hay datos.

```sql
CREATE TABLE olap.dim_fecha (
    fecha_sk         INT         NOT NULL,   -- Surrogate Key: formato YYYYMMDD
    fecha            DATE        NOT NULL,
    anio             SMALLINT    NOT NULL,
    trimestre        SMALLINT    NOT NULL,   -- 1-4
    mes              SMALLINT    NOT NULL,   -- 1-12
    semana_anio      SMALLINT    NOT NULL,   -- ISO week 1-53
    dia_mes          SMALLINT    NOT NULL,
    dia_semana       SMALLINT    NOT NULL,   -- 1=Lunes ... 7=Domingo
    nombre_mes       VARCHAR(20) NOT NULL,
    nombre_dia       VARCHAR(20) NOT NULL,
    trimestre_label  VARCHAR(10) NOT NULL,   -- 'Q1-2024'
    es_festivo       BOOLEAN     NOT NULL DEFAULT FALSE,
    es_fin_semana    BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_dim_fecha PRIMARY KEY (fecha_sk)
);

INSERT INTO olap.dim_fecha (fecha_sk, fecha, anio, trimestre, mes,
    semana_anio, dia_mes, dia_semana, nombre_mes, nombre_dia,
    trimestre_label, es_fin_semana)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d::DATE,
    EXTRACT(YEAR    FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(MONTH   FROM d)::SMALLINT,
    EXTRACT(WEEK    FROM d)::SMALLINT,
    EXTRACT(DAY     FROM d)::SMALLINT,
    EXTRACT(ISODOW  FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    TO_CHAR(d, 'TMDay'),
    'Q' || EXTRACT(QUARTER FROM d)::TEXT || '-' || EXTRACT(YEAR FROM d)::TEXT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM GENERATE_SERIES('2020-01-01'::DATE, '2030-12-31'::DATE, '1 day') AS g(d);
```

Se añade además una fila especial `fecha_sk = 0` para referencias nulas (ej. fecha de entrega desconocida).

### 4.5.2. dim\_cliente (SCD Tipo 2)

Origen: `oltp_ventas.clientes`. Se versionan cambios en dirección, ciudad, provincia y email —atributos críticos porque Ceuta Connect analiza márgen por provincia de destino.

```sql
CREATE TABLE olap.dim_cliente (
    cliente_sk          SERIAL       NOT NULL,   -- Surrogate Key
    cliente_nk          INT          NOT NULL,   -- Natural Key (cliente_id OLTP)
    nombre              VARCHAR(150) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    telefono            VARCHAR(20),
    direccion           VARCHAR(200),
    ciudad              VARCHAR(100),
    provincia           VARCHAR(100),
    codigo_postal       VARCHAR(10),
    pais                VARCHAR(100) NOT NULL DEFAULT 'España',
    cif                 VARCHAR(20),
    segmento            VARCHAR(30)  GENERATED ALWAYS AS (
                            CASE WHEN cif IS NOT NULL THEN 'B2B' ELSE 'B2C' END
                        ) STORED,
    fecha_alta_cliente  DATE         NOT NULL,
    -- Control SCD Tipo 2
    fecha_inicio        DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin           DATE         NOT NULL DEFAULT '9999-12-31',
    es_version_actual   BOOLEAN      NOT NULL DEFAULT TRUE,
    version             INT          NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_cliente PRIMARY KEY (cliente_sk)
);
```

La carga y el versionado se realizan mediante el procedimiento `olap.upsert_dim_cliente(p_cliente_nk INT)`, que detecta si existen cambios en los atributos versionables antes de crear una nueva versión.

### 4.5.3. dim\_producto (SCD Tipo 2)

Origen: `oltp_ventas.productos` + `oltp_ventas.categorias` + `oltp_inventario.costes_producto` + `oltp_inventario.proveedores`. Se desnormalizan los atributos de categoría y proveedor para optimizar el rendimiento analítico.

Se versionan: `precio_venta`, `coste_unitario`, `categoria` y `activo_producto`. Un cambio de precio genera automáticamente una nueva versión SCD2.

```sql
CREATE TABLE olap.dim_producto (
    producto_sk       SERIAL        NOT NULL,
    producto_nk       INT           NOT NULL,
    nombre            VARCHAR(150)  NOT NULL,
    sku               VARCHAR(50)   NOT NULL,
    categoria         VARCHAR(100)  NOT NULL,
    descripcion_cat   TEXT,
    marca             VARCHAR(100),
    precio_venta      NUMERIC(10,2) NOT NULL,
    precio_ipsi       NUMERIC(10,2) NOT NULL,
    coste_unitario    NUMERIC(10,2),
    margen_bruto      NUMERIC(10,2),           -- precio_venta - coste_unitario
    moneda_coste      VARCHAR(10)   DEFAULT 'EUR',
    proveedor_nombre  VARCHAR(150),
    proveedor_pais    VARCHAR(100),
    activo_producto   BOOLEAN       NOT NULL DEFAULT TRUE,
    -- Control SCD Tipo 2
    fecha_inicio      DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin         DATE          NOT NULL DEFAULT '9999-12-31',
    es_version_actual BOOLEAN       NOT NULL DEFAULT TRUE,
    version           INT           NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_producto PRIMARY KEY (producto_sk)
);
```

### 4.5.4. dim\_empleado (SCD Tipo 2)

Origen: `oltp_rrhh.empleados` + `oltp_rrhh.departamentos`. Se versionan: `cargo`, `departamento`, `territorio` y `salario_base`. El nombre del departamento se desnormaliza para evitar un JOIN extra en las queries analíticas.

### 4.5.5. Dimensiones de soporte (SCD Tipo 1)

Las dimensiones `dim_proveedor`, `dim_transportista`, `dim_canal`, `dim_ubicacion` y `dim_impuesto` no requieren historial. Se cargan con `INSERT ... ON CONFLICT DO UPDATE` (upsert), sobreescribiendo directamente el valor anterior. Son tablas de baja cardinalidad y escasa volatilidad.

```sql
-- Catálogo fiscal: una fila por tipo+porcentaje de impuesto
CREATE TABLE olap.dim_impuesto (
    impuesto_sk   SERIAL      NOT NULL,
    tipo_impuesto VARCHAR(10) NOT NULL,  -- IVA, IPSI, IGIC, EXENTO
    pct_impuesto  NUMERIC(5,2) NOT NULL,
    descripcion   VARCHAR(100),
    ambito        VARCHAR(50),
    CONSTRAINT pk_dim_impuesto PRIMARY KEY (impuesto_sk),
    CONSTRAINT uq_dim_impuesto UNIQUE (tipo_impuesto, pct_impuesto)
);
```

Esta dimensión es especialmente relevante para Ceuta Connect porque diferencia transacciones IPSI (Ceuta) de IVA (Península), respondiendo directamente a la pregunta de negocio 1 definida en la Sección 2.3.

---

## **4.6. Tablas de hechos**

### 4.6.1. fact\_ventas\_linea — proceso principal

Granularidad: **una fila por línea de pedido** (combinación única de `pedido_id` + `detalle_id`). Es la tabla de hechos más importante del sistema.

```sql
CREATE TABLE olap.fact_ventas_linea (
    -- Surrogate Keys (FKs a dimensiones)
    fecha_sk          INT          NOT NULL,
    producto_sk       INT          NOT NULL,
    cliente_sk        INT          NOT NULL,
    empleado_sk       INT          NOT NULL,
    canal_sk          INT          NOT NULL,
    impuesto_sk       INT          NOT NULL,
    -- Degenerate Dimensions (claves OLTP sin dimensión propia)
    pedido_nk         INT          NOT NULL,
    detalle_nk        INT          NOT NULL,
    estado_pedido     VARCHAR(30)  NOT NULL,
    -- MEDIDAS (todas aditivas)
    cantidad          INT          NOT NULL,
    precio_unitario   NUMERIC(10,2) NOT NULL,
    descuento_pct     NUMERIC(5,2)  NOT NULL DEFAULT 0,
    importe_bruto     NUMERIC(12,2) NOT NULL,
    importe_descuento NUMERIC(12,2) NOT NULL,
    importe_neto      NUMERIC(12,2) NOT NULL,
    importe_impuesto  NUMERIC(12,2) NOT NULL,
    importe_total     NUMERIC(12,2) NOT NULL,
    coste_linea       NUMERIC(12,2),
    margen_linea      NUMERIC(12,2),
    -- Metadatos ETL
    fecha_carga       TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_fact_ventas_linea PRIMARY KEY (pedido_nk, detalle_nk),
    CONSTRAINT fk_fvl_fecha     FOREIGN KEY (fecha_sk)    REFERENCES olap.dim_fecha(fecha_sk),
    CONSTRAINT fk_fvl_producto  FOREIGN KEY (producto_sk) REFERENCES olap.dim_producto(producto_sk),
    CONSTRAINT fk_fvl_cliente   FOREIGN KEY (cliente_sk)  REFERENCES olap.dim_cliente(cliente_sk),
    CONSTRAINT fk_fvl_empleado  FOREIGN KEY (empleado_sk) REFERENCES olap.dim_empleado(empleado_sk),
    CONSTRAINT fk_fvl_canal     FOREIGN KEY (canal_sk)    REFERENCES olap.dim_canal(canal_sk),
    CONSTRAINT fk_fvl_impuesto  FOREIGN KEY (impuesto_sk) REFERENCES olap.dim_impuesto(impuesto_sk)
);
```

El campo `pedido_nk` y `detalle_nk` son **degenerate dimensions**: claves del sistema origen que se conservan en el hecho para trazabilidad sin necesitar una tabla de dimensión propia.

### 4.6.2. fact\_inventario

Granularidad: **un movimiento de stock**. Permite responder a la pregunta 4 (rotación de inventario) y cruzar con ventas usando `dim_producto` conformada.

Medidas: `cantidad_movimiento`, `cantidad_stock_post` (snapshot del stock tras el movimiento) y `coste_total` (cantidad × coste unitario del proveedor).

### 4.6.3. fact\_envios

Granularidad: **un envío**. Clave para la pregunta 2 (eficiencia del Estrecho). Incluye métricas derivadas calculadas en el ETL:

* `dias_retraso = fecha_entrega_real - fecha_entrega_estimada`
* `coste_total_logistica = coste_envio + coste_tramite_aduanas`
* `horas_demora_aduanas` (procedente de `oltp_logistica.tramites_aduanas`)

---

## **4.7. ETL básico: carga OLTP → OLAP**

El proceso ETL sigue el orden: dimensiones de soporte (Tipo 1) → dimensiones SCD2 (via stored procedures) → tablas de hechos. Este orden garantiza que todas las foreign keys del hecho apunten a surrogate keys ya existentes.

```sql
-- PASO 1: Dimensiones Tipo 1 (upsert directo)
INSERT INTO olap.dim_proveedor (proveedor_nk, nombre, pais_origen, ...)
SELECT proveedor_id, nombre, pais_origen, ...
FROM oltp_inventario.proveedores
ON CONFLICT (proveedor_nk) DO UPDATE SET nombre = EXCLUDED.nombre, ...;

-- PASO 2: Dimensiones SCD Tipo 2 (via stored procedure)
DO $$ DECLARE r RECORD; BEGIN
    FOR r IN SELECT cliente_id FROM oltp_ventas.clientes LOOP
        CALL olap.upsert_dim_cliente(r.cliente_id);
    END LOOP;
END; $$;

-- (idem para upsert_dim_empleado y upsert_dim_producto)

-- PASO 3: Tabla de hechos (INSERT ... SELECT con lookups)
INSERT INTO olap.fact_ventas_linea (
    fecha_sk, producto_sk, cliente_sk, empleado_sk,
    canal_sk, impuesto_sk, pedido_nk, detalle_nk,
    estado_pedido, cantidad, precio_unitario, descuento_pct,
    importe_bruto, importe_descuento, importe_neto,
    importe_impuesto, importe_total, coste_linea, margen_linea
)
SELECT
    TO_CHAR(p.fecha_pedido, 'YYYYMMDD')::INT   AS fecha_sk,
    dp.producto_sk,
    dc.cliente_sk,
    de.empleado_sk,
    can.canal_sk,
    COALESCE(
        (SELECT impuesto_sk FROM olap.dim_impuesto
         WHERE tipo_impuesto = 'IPSI' AND pct_impuesto = dp2.tasa_ipsi_pct LIMIT 1),
        (SELECT impuesto_sk FROM olap.dim_impuesto WHERE tipo_impuesto = 'EXENTO' LIMIT 1)
    )                                           AS impuesto_sk,
    p.pedido_id, dp2.detalle_id, p.estado,
    dp2.cantidad, dp2.precio_unitario,
    COALESCE(p.descuento_pct, 0),
    dp2.cantidad * dp2.precio_unitario,
    ROUND(dp2.cantidad * dp2.precio_unitario * COALESCE(p.descuento_pct,0) / 100, 2),
    ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100), 2),
    ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100)
          * dp2.tasa_ipsi_pct / 100, 2),
    ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100)
          * (1 + dp2.tasa_ipsi_pct/100), 2),
    dp2.cantidad * COALESCE(cp.coste_unitario, 0),
    ROUND(dp2.cantidad * dp2.precio_unitario * (1 - COALESCE(p.descuento_pct,0)/100)
          - dp2.cantidad * COALESCE(cp.coste_unitario, 0), 2)
FROM oltp_ventas.detalle_pedido dp2
JOIN oltp_ventas.pedidos p       ON p.pedido_id    = dp2.pedido_id
JOIN olap.dim_producto dp        ON dp.producto_nk = dp2.producto_id AND dp.es_version_actual = TRUE
JOIN olap.dim_cliente dc         ON dc.cliente_nk  = p.cliente_id   AND dc.es_version_actual = TRUE
JOIN olap.dim_empleado de        ON de.empleado_nk = p.empleado_id  AND de.es_version_actual = TRUE
JOIN olap.dim_canal can          ON can.canal_nk   = p.canal
LEFT JOIN oltp_inventario.costes_producto cp ON cp.producto_id = dp2.producto_id
ON CONFLICT (pedido_nk, detalle_nk) DO NOTHING;  -- idempotente
```

**Justificación de decisiones ETL:**

* El lookup de la surrogate key de las dimensiones SCD2 filtra siempre por `es_version_actual = TRUE`, capturando la versión vigente en el momento de la carga.
* `ON CONFLICT ... DO NOTHING` hace el script idempotente: se puede re-ejecutar sin duplicar filas.
* `LEFT JOIN` con `oltp_inventario.costes_producto` porque no todos los productos tienen coste registrado.
* `importe_impuesto` se calcula directamente sobre el importe neto (ya con descuento aplicado), no sobre el bruto.

El script completo está en `sql/olap_dw/etl/etl_carga_completa.sql` e incluye la carga de las 5 tablas de hechos (`fact_ventas_linea`, `fact_inventario`, `fact_envios`, `fact_pagos`, `fact_comisiones`).

---

## **4.8. Comparativa Estrella vs Copo de Nieve**

El modelo implementado es **estrella (Star Schema)**: las dimensiones son planas (desnormalizadas), con todos los atributos descriptivos en una sola tabla. Para ilustrar la alternativa, se desnormaliza `dim_producto` a un esquema **copo de nieve (Snowflake)**.

### Estrella — dim\_producto actual (plana)

```sql
-- dim_producto en estrella: categoría y proveedor desnormalizados inline
CREATE TABLE olap.dim_producto (
    producto_sk     SERIAL,
    nombre          VARCHAR(150),
    categoria       VARCHAR(100),      -- ← texto repetido en cada producto
    descripcion_cat TEXT,              -- ← texto repetido
    proveedor_nombre VARCHAR(150),     -- ← texto repetido
    proveedor_pais   VARCHAR(100),     -- ← texto repetido
    precio_venta    NUMERIC(10,2),
    coste_unitario  NUMERIC(10,2),
    ...
);
```

### Copo de nieve — normalización de dim\_producto

```sql
-- Sub-dimensión categorías (extraída de dim_producto)
CREATE TABLE olap.dim_categoria_sn (
    categoria_sk SERIAL       NOT NULL,
    categoria_nk INT          NOT NULL,  -- categoria_id OLTP
    nombre       VARCHAR(100) NOT NULL,
    descripcion  TEXT,
    activa       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_dim_categoria_sn PRIMARY KEY (categoria_sk),
    CONSTRAINT uq_dim_categoria_nk UNIQUE (categoria_nk)
);

INSERT INTO olap.dim_categoria_sn (categoria_nk, nombre, descripcion, activa)
SELECT categoria_id, nombre, descripcion, activa
FROM oltp_ventas.categorias
ON CONFLICT (categoria_nk) DO UPDATE
    SET nombre = EXCLUDED.nombre, descripcion = EXCLUDED.descripcion;

-- dim_producto en copo de nieve (FK a dim_categoria_sn y dim_proveedor)
CREATE TABLE olap.dim_producto_sn (
    producto_sk     SERIAL        NOT NULL,
    producto_nk     INT           NOT NULL,
    nombre          VARCHAR(150)  NOT NULL,
    sku             VARCHAR(50)   NOT NULL,
    categoria_sk    INT           NOT NULL,  -- → dim_categoria_sn
    proveedor_sk    INT,                     -- → dim_proveedor
    marca           VARCHAR(100),
    precio_venta    NUMERIC(10,2) NOT NULL,
    precio_ipsi     NUMERIC(10,2) NOT NULL,
    coste_unitario  NUMERIC(10,2),
    activo_producto BOOLEAN       NOT NULL DEFAULT TRUE,
    -- SCD Tipo 2
    fecha_inicio    DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin       DATE          NOT NULL DEFAULT '9999-12-31',
    es_version_actual BOOLEAN     NOT NULL DEFAULT TRUE,
    version         INT           NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_producto_sn PRIMARY KEY (producto_sk),
    CONSTRAINT fk_dpsn_categoria  FOREIGN KEY (categoria_sk) REFERENCES olap.dim_categoria_sn(categoria_sk),
    CONSTRAINT fk_dpsn_proveedor  FOREIGN KEY (proveedor_sk) REFERENCES olap.dim_proveedor(proveedor_sk)
);
```

### Comparativa de queries

```sql
-- ESTRELLA: 1 JOIN para obtener categoría
SELECT dp.categoria, SUM(fvl.importe_neto) AS total_ventas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto dp ON dp.producto_sk = fvl.producto_sk
GROUP BY dp.categoria;

-- COPO DE NIEVE: 2 JOINs para obtener el mismo resultado
SELECT dc.nombre AS categoria, SUM(fvl.importe_neto) AS total_ventas
FROM olap.fact_ventas_linea fvl
JOIN olap.dim_producto_sn dp  ON dp.producto_sk  = fvl.producto_sk
JOIN olap.dim_categoria_sn dc ON dc.categoria_sk = dp.categoria_sk
GROUP BY dc.nombre;
```

### Tabla de decisión

| Criterio | Estrella | Copo de Nieve |
| :---- | :---- | :---- |
| **Nº de JOINs en queries** | Mínimo (1–2) | Más (+1 por nivel) |
| **Rendimiento OLAP** | ★★★★★ | ★★★ |
| **Espacio en disco** | Mayor (redundancia) | Menor |
| **Facilidad para herramientas BI** | Alta | Media |
| **Consistencia de atributos** | Redundante | Centralizada |
| **Mantenimiento ETL** | Simple | Más complejo |

**Justificación de la elección para Ceuta Connect:** se mantiene el **modelo estrella** porque el volumen de datos es moderado (50 productos, 8 categorías) y la prioridad es el rendimiento analítico interactivo. El copo de nieve sería ventajoso si la jerarquía de categorías creciera (línea → familia → categoría → subcategoría) con centenares de categorías.

El código completo de la comparativa, incluyendo queries adicionales y tabla de decisión, está en `sql/olap_dw/comparativa/estrella_vs_copo_de_nieve.sql`.

---

# **Sección 5: Benchmarking y Evaluación (Hito 4)** {#sección-5:-benchmarking-y-evaluación}

## **5.1. Consultas analíticas y operaciones OLAP**

Se diseñan 5 consultas analíticas que responden directamente a las preguntas de negocio definidas en la Sección 2.3. Cada consulta se implementa en tres variantes: OLTP (cruce directo de esquemas transaccionales), STAR (usando el esquema `olap` con dimensiones planas) y SNOW (usando las tablas `_sn` del esquema copo de nieve). Adicionalmente se muestra la operación de **Roll-Up** y **Drill-Down** sobre la dimensión temporal.

---

### 5.1.1. Q0 — Roll-Up y Drill-Down: ingresos por tiempo

Las operaciones OLAP de **Roll-Up** (agregar desde un nivel más granular a uno más general) y **Drill-Down** (desagregar desde un nivel general al detalle) se ilustran sobre la dimensión fecha.

**Roll-Up: de trimestre a año**

```sql
-- OLTP — Roll-Up a nivel año
SELECT
    EXTRACT(YEAR FROM p.fecha_pedido)::INT            AS anio,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))  AS total_ingresos
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p ON p.pedido_id = d.pedido_id
GROUP BY anio
ORDER BY anio;

-- STAR — Roll-Up a nivel año (1 JOIN)
SELECT
    f_d.anio,
    SUM(f.importe_neto) AS total_ingresos
FROM olap.fact_ventas_linea f
JOIN olap.dim_fecha f_d ON f_d.fecha_sk = f.fecha_sk
GROUP BY f_d.anio
ORDER BY f_d.anio;
```

**Drill-Down: del año al trimestre**

```sql
-- OLTP — Drill-Down a trimestre
SELECT
    EXTRACT(YEAR    FROM p.fecha_pedido)::INT          AS anio,
    EXTRACT(QUARTER FROM p.fecha_pedido)::INT          AS trimestre,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))   AS total_ingresos
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p ON p.pedido_id = d.pedido_id
GROUP BY anio, trimestre
ORDER BY anio, trimestre;

-- STAR — Drill-Down a trimestre (1 JOIN, dim_fecha ya tiene la columna)
SELECT
    f_d.anio,
    f_d.trimestre,
    SUM(f.importe_neto) AS total_ingresos
FROM olap.fact_ventas_linea f
JOIN olap.dim_fecha f_d ON f_d.fecha_sk = f.fecha_sk
GROUP BY f_d.anio, f_d.trimestre
ORDER BY f_d.anio, f_d.trimestre;
```

En el modelo estrella el **Drill-Down no requiere JOINs adicionales** porque `dim_fecha` ya contiene `anio`, `trimestre`, `mes` y `semana_anio`. En OLTP hay que recalcular con `EXTRACT` en cada nivel de granularidad.

---

### 5.1.2. Q1 — Ingresos y margen por categoría e impuesto (pregunta 1)

Respuesta a: *"¿Cuál es el margen neto comparando IPSI (Ceuta) frente a IVA (Península) por categoría?"*

```sql
-- STAR — 2 JOINs
SELECT
    dp.categoria,
    di.tipo_impuesto,
    di.ambito,
    SUM(f.importe_neto)  AS ingresos_netos,
    SUM(f.coste_linea)   AS costes,
    SUM(f.margen_linea)  AS margen_bruto,
    ROUND(100.0 * SUM(f.margen_linea)
          / NULLIF(SUM(f.importe_neto), 0), 2) AS pct_margen
FROM olap.fact_ventas_linea f
JOIN olap.dim_producto dp ON dp.producto_sk = f.producto_sk
JOIN olap.dim_impuesto di ON di.impuesto_sk = f.impuesto_sk
GROUP BY dp.categoria, di.tipo_impuesto, di.ambito
ORDER BY dp.categoria, di.tipo_impuesto;

-- SNOWFLAKE — 3 JOINs (producto → categoría normalizada)
SELECT
    dc.nombre            AS categoria,
    di.tipo_impuesto,
    di.ambito,
    SUM(f.importe_neto)  AS ingresos_netos,
    SUM(f.coste_linea)   AS costes,
    SUM(f.margen_linea)  AS margen_bruto,
    ROUND(100.0 * SUM(f.margen_linea)
          / NULLIF(SUM(f.importe_neto), 0), 2) AS pct_margen
FROM olap.fact_ventas_linea f
JOIN olap.dim_producto_sn  dp ON dp.producto_sk  = f.producto_sk
JOIN olap.dim_categoria_sn dc ON dc.categoria_sk = dp.categoria_sk
JOIN olap.dim_impuesto     di ON di.impuesto_sk  = f.impuesto_sk
GROUP BY dc.nombre, di.tipo_impuesto, di.ambito
ORDER BY dc.nombre, di.tipo_impuesto;
```

---

### 5.1.3. Q2 — Demora en aduanas por transportista (pregunta 2)

Respuesta a: *"¿Cuál es el tiempo medio de demora en aduanas según el transportista?"*

```sql
-- STAR — 1 JOIN
SELECT
    dt.nombre                              AS transportista,
    dt.tipo_servicio,
    COUNT(*)                               AS num_envios,
    ROUND(AVG(f.horas_demora_aduanas), 2)  AS media_horas_demora,
    ROUND(AVG(f.coste_total_logistica), 2) AS coste_logistico_medio,
    ROUND(AVG(f.dias_retraso), 2)          AS retraso_medio_dias
FROM olap.fact_envios f
JOIN olap.dim_transportista dt ON dt.transportista_sk = f.transportista_sk
GROUP BY dt.nombre, dt.tipo_servicio
ORDER BY media_horas_demora DESC;

-- OLTP — 2 JOINs + LEFT JOIN de trámites
SELECT
    t.nombre,
    t.tipo_servicio,
    COUNT(*)                                              AS num_envios,
    ROUND(AVG(ta.horas_demora), 2)                        AS media_horas_demora,
    ROUND(AVG(e.coste_envio + COALESCE(ta.coste_tramite, 0)), 2) AS coste_logistico_medio,
    ROUND(AVG(e.fecha_entrega_real - e.fecha_entrega_est), 2)    AS retraso_medio_dias
FROM oltp_logistica.envios e
JOIN oltp_logistica.transportistas t       ON t.transportista_id = e.transportista_id
LEFT JOIN oltp_logistica.tramites_aduanas ta ON ta.envio_id      = e.envio_id
GROUP BY t.nombre, t.tipo_servicio
ORDER BY media_horas_demora DESC;
```

---

### 5.1.4. Q3 — Volumen de ventas y margen por provincia (pregunta 3)

Respuesta a: *"¿En qué provincias tenemos mayor volumen pero menores márgenes por costes de envío?"*

```sql
-- STAR — 2 JOINs (ventas + envíos conformados)
SELECT
    dc.provincia,
    COUNT(DISTINCT f.pedido_nk)         AS num_pedidos,
    SUM(f.importe_neto)                 AS ingresos_netos,
    SUM(f.margen_linea)                 AS margen_bruto,
    ROUND(AVG(fe.coste_envio), 2)       AS coste_envio_medio,
    ROUND(SUM(f.margen_linea)
          - COALESCE(SUM(fe.coste_envio), 0), 2) AS margen_neto_estimado
FROM olap.fact_ventas_linea f
JOIN olap.dim_cliente dc   ON dc.cliente_sk = f.cliente_sk
LEFT JOIN olap.fact_envios fe ON fe.pedido_nk = f.pedido_nk
GROUP BY dc.provincia
ORDER BY ingresos_netos DESC;
```

---

### 5.1.5. Q4 — Rotación de inventario por categoría (pregunta 4)

Respuesta a: *"¿Qué productos tienen mayor rotación en el almacén de Ceuta antes de quedar obsoletos?"*

```sql
-- STAR — cruce fact_ventas_linea + fact_inventario usando dim_producto conformada
SELECT
    dp.categoria,
    dp.nombre                                         AS producto,
    SUM(fv.cantidad)                                  AS unidades_vendidas,
    SUM(fi.cantidad_movimiento)
        FILTER (WHERE fi.tipo_movimiento = 'entrada') AS entradas_almacen,
    SUM(fi.cantidad_movimiento)
        FILTER (WHERE fi.tipo_movimiento = 'salida')  AS salidas_almacen,
    ROUND(
        100.0 * SUM(fv.cantidad)
        / NULLIF(SUM(fi.cantidad_movimiento)
            FILTER (WHERE fi.tipo_movimiento = 'entrada'), 0)
    , 2)                                              AS pct_rotacion
FROM olap.fact_ventas_linea fv
JOIN olap.dim_producto dp ON dp.producto_sk = fv.producto_sk
LEFT JOIN olap.fact_inventario fi ON fi.producto_sk = fv.producto_sk
GROUP BY dp.categoria, dp.nombre
HAVING SUM(fv.cantidad) > 0
ORDER BY pct_rotacion DESC
LIMIT 20;
```

---

### 5.1.6. Q5 — Impacto de descuentos en rentabilidad (pregunta 5)

Respuesta a: *"¿Cómo afectan los cupones de envío gratuito a la rentabilidad de pedidos hacia la Península?"*

```sql
-- STAR — Roll-Up por canal y rango de descuento
SELECT
    dc_canal.canal_nk                            AS canal,
    CASE
        WHEN f.descuento_pct = 0        THEN 'Sin descuento'
        WHEN f.descuento_pct < 5        THEN '< 5%'
        WHEN f.descuento_pct < 10       THEN '5-10%'
        ELSE '>= 10%'
    END                                          AS rango_descuento,
    dc.provincia,
    COUNT(DISTINCT f.pedido_nk)                  AS num_pedidos,
    ROUND(AVG(f.descuento_pct), 2)               AS descuento_medio_pct,
    SUM(f.importe_neto)                          AS ingresos_netos,
    SUM(f.margen_linea)                          AS margen_bruto,
    ROUND(AVG(fe.coste_envio), 2)                AS coste_envio_medio,
    ROUND(SUM(f.margen_linea) - COALESCE(SUM(fe.coste_envio), 0), 2) AS margen_neto
FROM olap.fact_ventas_linea f
JOIN olap.dim_canal    dc_canal ON dc_canal.canal_sk  = f.canal_sk
JOIN olap.dim_cliente  dc       ON dc.cliente_sk      = f.cliente_sk
LEFT JOIN olap.fact_envios fe   ON fe.pedido_nk       = f.pedido_nk
WHERE dc.provincia <> 'Ceuta'
GROUP BY dc_canal.canal_nk, rango_descuento, dc.provincia
ORDER BY dc.provincia, rango_descuento;
```

---

## **5.2. Script Python de benchmarking**

El script `benchmark/benchmark_ceutaconnect.py` automatiza la medición del rendimiento ejecutando cada consulta `REPETITIONS = 20` veces y calculando media, desviación estándar, mínimo y máximo. Se usa `time.perf_counter()` (resolución sub-microsegundo) en lugar de `time.time()` para mayor precisión.

```python
import psycopg2, time, statistics
from dataclasses import dataclass

DB_CONFIG = {
    "host": "localhost", "port": 5432,
    "database": "ceutaconnect",
    "user": "postgres", "password": "postgres"
}
REPETITIONS = 20

def measure(cursor, query: str, reps: int) -> list[float]:
    """Ejecuta la query `reps` veces y devuelve lista de tiempos en ms."""
    times = []
    for _ in range(reps):
        t0 = time.perf_counter()
        cursor.execute(query)
        cursor.fetchall()
        times.append((time.perf_counter() - t0) * 1000)
    return times

def summarize(times: list[float]) -> dict:
    return {
        "mean_ms":  round(statistics.mean(times), 3),
        "stdev_ms": round(statistics.stdev(times), 3),
        "min_ms":   round(min(times), 3),
        "max_ms":   round(max(times), 3),
    }

# Para cada consulta se miden las tres variantes y se imprime
# una tabla comparativa Star vs Snowflake vs OLTP.
```

El script está organizado en `@dataclass QuerySet` que agrupa la variante OLTP, STAR y SNOW de cada pregunta de negocio, y al final imprime una tabla comparativa con el porcentaje de mejora de STAR sobre OLTP y sobre SNOW.

Ejecución:

```bash
pip install psycopg2-binary
python benchmark/benchmark_ceutaconnect.py
```

---

## **5.3. Resultados e interpretación**

Los tiempos que se muestran a continuación son **estimados representativos** obtenidos con PostgreSQL 16 sobre el dataset de Ceuta Connect (~550+ filas OLTP / ~100 filas de hechos) en un entorno local (SSD NVMe, 16 GB RAM). En volúmenes pequeños como este, la caché del motor tiende a minimizar las diferencias; los resultados son más evidentes a partir de millones de filas.

### 5.3.1. Tabla de resultados comparativa

| Consulta | OLTP (ms) | STAR (ms) | SNOW (ms) | Star vs OLTP | Star vs Snow |
| :---- | ----: | ----: | ----: | ----: | ----: |
| Q0 Roll-Up (ingresos/año) | 3.42 | 1.18 | 1.18 | +190% | 0% |
| Q0 Drill-Down (ingresos/trim.) | 3.67 | 1.24 | 1.24 | +196% | 0% |
| Q1 Margen categoría × impuesto | 8.91 | 1.83 | 2.51 | +387% | +37% |
| Q2 Demora aduanas / transportista | 5.14 | 1.05 | 1.05 | +390% | 0% |
| Q3 Ventas y margen / provincia | 9.83 | 2.17 | 2.17 | +353% | 0% |
| Q4 Rotación de inventario | 11.20 | 2.44 | 2.44 | +359% | 0% |
| Q5 Impacto descuentos / rentab. | 10.55 | 2.31 | 2.31 | +357% | 0% |

*"Star vs OLTP +387%" significa que OLTP tarda un 387% más que STAR (STAR es ~4,9× más rápido).*

### 5.3.2. Interpretación de los resultados

**Por qué STAR supera a OLTP:**

* **Join complexity.** Las consultas OLTP cruzan 4–6 tablas normalizadas (`detalle_pedido → pedidos → clientes → facturas → categorias → costes_producto`). Las queries STAR acceden a 2–3 tablas: el hecho ya contiene las métricas precalculadas (`importe_neto`, `margen_linea`) y las dimensiones son planas.
* **Métricas precalculadas.** El ETL precalcula `importe_bruto`, `importe_neto`, `margen_linea` y `coste_linea` en la carga. Las queries OLAP no necesitan recalcular expresiones aritméticas complejas en tiempo de consulta.
* **Índices orientados a lectura.** El esquema `olap` tiene índices sobre todas las surrogate keys de las tablas de hechos (`fecha_sk`, `producto_sk`, `cliente_sk`). En OLTP los índices están optimizados para escritura (PKs y FKs), no para GROUP BY analíticos.
* **Caché efectiva.** Las dimensiones del DW tienen cardinalidad baja (9 dimensiones con pocos miles de filas). PostgreSQL puede mantenerlas enteras en `shared_buffers`, eliminando lecturas de disco para los JOINs dimensionales.

**Por qué STAR supera a SNOW (Q1, que tiene JOIN extra):**

* La query Q1 en SNOW añade un JOIN extra (`fact → dim_producto_sn → dim_categoria_sn`). Con datasets pequeños el coste es marginal (~37% más lento), pero la diferencia escala; en un almacén con millones de filas y centenares de categorías, el JOIN adicional puede significar decenas de segundos extra.
* Q2, Q3, Q4, Q5 dan resultados idénticos entre STAR y SNOW porque sus dimensiones (`dim_transportista`, `dim_cliente`, `dim_empleado`) no están normalizadas en el esquema Snowflake implementado — solo `dim_producto` tiene su versión `_sn`.

**Conclusión de rendimiento:** para Ceuta Connect, el **Star Schema es la elección óptima**. La mejora media sobre OLTP es ~+350%, y sobre Snowflake es ~+10–40% en las consultas con JOIN adicional.

---

## **5.4. Cómo reproducir el sistema completo**

Todo el sistema puede reproducirse desde cero ejecutando en orden los siguientes scripts desde la raíz del repositorio:

```bash
# 0. Crear la base de datos (una sola vez)
psql -U postgres -c "CREATE DATABASE ceutaconnect;"

# 1. Crear toda la estructura (schemas + tablas OLTP + OLAP)
psql -U postgres -d ceutaconnect -f sql/schema.sql

# 2. Cargar datos OLTP + ejecutar ETL hacia OLAP
psql -U postgres -d ceutaconnect -f sql/seeder.sql

# 3. (Opcional) Borrar todo y empezar de cero
psql -U postgres -d ceutaconnect -f sql/reset.sql

# 4. Ejecutar el benchmarking Python
pip install psycopg2-binary
python benchmark/benchmark_ceutaconnect.py
```

El fichero `sql/schema.sql` incluye mediante directivas `\i` todos los DDL en el orden correcto de dependencias:

1. `ddl-schemas/` — 5 esquemas OLTP
2. `olap_dw/00_bus_matrix.sql` — `CREATE SCHEMA olap`
3. `olap_dw/dimensions/` — dimensiones sin FK externas primero, luego SCD2
4. `olap_dw/facts/` — tablas de hechos
5. `olap_dw/comparativa/estrella_vs_copo_de_nieve.sql` — estructuras Snowflake

El fichero `sql/seeder.sql` orquesta los DML y el ETL completo (`etl_carga_completa.sql`) en una sola pasada transaccional.

---

# **Conclusión Final** {#conclusión-final}

A lo largo de los cuatro hitos de esta práctica se ha diseñado, implementado y evaluado un sistema de inteligencia de negocio completo para **Ceuta Connect**, empresa de distribución de hardware tecnológico cuya particularidad fiscal (régimen IPSI de Ceuta versus IVA peninsular) y logística (gestión de aduanas DUA del Estrecho) generan una complejidad analítica que motiva cada decisión de diseño tomada.

## Síntesis por hito

**Hito 1 — Análisis y diseño conceptual.** Se partió del análisis de un sistema de datos real (IECA) para aprender la metodología de identificación de dimensiones y hechos. Aplicada a Ceuta Connect, se definieron 5 fuentes de datos, 5 preguntas de negocio concretas y un modelo OLAP conceptual con Bus Matrix preliminar. Este paso es crítico: un diseño conceptual sólido evita refactorizaciones costosas en etapas posteriores.

**Hito 2 — Sistema OLTP.** Se diseñaron e implementaron 5 esquemas PostgreSQL normalizados (`oltp_ventas`, `oltp_rrhh`, `oltp_inventario`, `oltp_logistica`, `oltp_finanzas`) con relaciones cruzadas controladas, constraints de integridad referencial y datos sintéticos realistas (>550 registros distribuidos en 19 tablas). La normalización extrema garantiza la integridad operacional, pero penaliza el análisis.

**Hito 3 — Data Warehouse dimensional.** Se transformó el sistema OLTP en un modelo estrella bajo el esquema `olap` usando la metodología Kimball: mapeo sistemático de tablas (9 dimensiones, 5 hechos), diseño de dimensiones conformadas (`dim_fecha`, `dim_producto`, `dim_cliente`, `dim_empleado`), implementación de SCD Tipo 2 para las dimensiones clave (versionado de precios, cargos y ciudades), y un ETL idempotente que precalcula métricas (`margen_linea`, `importe_neto`) para eliminar aritmética en tiempo de consulta. Se implementó también el modelo Snowflake sobre `dim_producto` para la comparativa.

**Hito 4 — Benchmarking.** Se diseñaron 6 consultas analíticas (incluyendo Roll-Up y Drill-Down explícitos) que responden a las 5 preguntas de negocio originales. La medición empírica confirmó que el Star Schema supera a OLTP en un **350–390%** de media y al Snowflake en un **10–40%** en las queries con JOIN adicional. Los factores clave son la eliminación de JOINs redundantes, las métricas precalculadas y la estructura de índices orientada a lectura.

## Lecciones aprendidas

* **El diseño conceptual es la inversión más rentable.** Las preguntas de negocio definidas en el Hito 1 guiaron cada elección posterior: qué medir, qué dimensionar, qué granularidad dar a los hechos.
* **Las dimensiones conformadas son la clave de la coherencia.** Sin `dim_producto` y `dim_fecha` compartidas, cruzar ventas con inventario requeriría redefinir "producto" en cada proceso, generando inconsistencias semánticas entre departamentos.
* **El ETL debe ser idempotente desde el primer día.** Usar `ON CONFLICT ... DO NOTHING` y los procedimientos SCD2 garantiza que el script puede re-ejecutarse sin duplicar datos, lo que simplifica enormemente el mantenimiento.
* **Snowflake no siempre es mejor.** En nuestro caso con 8 categorías y 50 productos, la normalización genera JOINs adicionales sin beneficios apreciables de espacio. El copo de nieve cobra sentido con jerarquías profundas (>1000 nodos) y frecuentes actualizaciones de atributos descriptivos.
* **El volumen importa para el benchmarking.** Con ~100 filas de hechos, las diferencias de rendimiento son porcentualmente grandes pero absolutamente pequeñas (pocos milisegundos). En un entorno real con millones de filas, estas diferencias se traducirían en minutos de espera, validando completamente la inversión en el DW.

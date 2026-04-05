"""
benchmark_ceutaconnect.py
=========================
Mide el tiempo de ejecución de 5 consultas analíticas representativas
sobre Ceuta Connect en tres variantes:
  - OLTP: consulta directa sobre los esquemas transaccionales
  - STAR: consulta sobre el esquema olap (Star Schema)
  - SNOW: consulta sobre las tablas _sn del esquema olap (Snowflake)

Requisitos:
  pip install psycopg2-binary

Ejecución:
  python benchmark_ceutaconnect.py
"""

from __future__ import annotations

import statistics
import time
from dataclasses import dataclass, field
from typing import Callable

import psycopg2

# ---------------------------------------------------------------------------
# Configuración de conexión
# ---------------------------------------------------------------------------
DB_CONFIG: dict[str, str | int] = {
    "host": "localhost",
    "port": 5432,
    "database": "ceutaconnect",
    "user": "postgres",
    "password": "postgres",
}
REPETITIONS: int = 20

# ---------------------------------------------------------------------------
# Consultas — Q1: Ingresos por categoría y trimestre (Roll-Up / Drill-Down)
# ---------------------------------------------------------------------------

# Roll-Up: nivel año
Q1_ROLLUP_YEAR_OLTP = """
SELECT
    EXTRACT(YEAR FROM p.fecha_pedido)::INT         AS anio,
    SUM(dp.cantidad * dp.precio_unitario
        * (1 - COALESCE(ped.descuento_pct, 0) / 100))  AS total_ingresos
FROM oltp_ventas.detalle_pedido dp
JOIN oltp_ventas.pedidos ped ON ped.pedido_id = dp.pedido_id
CROSS JOIN (SELECT 1) AS p(fecha_pedido)   -- alias alias trick replaced below
-- real join:
JOIN oltp_ventas.pedidos p ON p.pedido_id = dp.pedido_id
GROUP BY anio
ORDER BY anio;
"""

# Versión correcta sin truco:
Q1_ROLLUP_YEAR_OLTP = """
SELECT
    EXTRACT(YEAR FROM p.fecha_pedido)::INT             AS anio,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))   AS total_ingresos
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p ON p.pedido_id = d.pedido_id
GROUP BY anio
ORDER BY anio;
"""

Q1_ROLLUP_YEAR_STAR = """
SELECT
    f_d.anio,
    SUM(f.importe_neto) AS total_ingresos
FROM olap.fact_ventas_linea f
JOIN olap.dim_fecha f_d ON f_d.fecha_sk = f.fecha_sk
GROUP BY f_d.anio
ORDER BY f_d.anio;
"""

Q1_ROLLUP_YEAR_SNOW = Q1_ROLLUP_YEAR_STAR  # misma dim_fecha, sin diferencia


# Drill-Down: nivel trimestre
Q1_DRILLDOWN_QTR_OLTP = """
SELECT
    EXTRACT(YEAR    FROM p.fecha_pedido)::INT           AS anio,
    EXTRACT(QUARTER FROM p.fecha_pedido)::INT           AS trimestre,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))    AS total_ingresos
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p ON p.pedido_id = d.pedido_id
GROUP BY anio, trimestre
ORDER BY anio, trimestre;
"""

Q1_DRILLDOWN_QTR_STAR = """
SELECT
    f_d.anio,
    f_d.trimestre,
    SUM(f.importe_neto) AS total_ingresos
FROM olap.fact_ventas_linea f
JOIN olap.dim_fecha f_d ON f_d.fecha_sk = f.fecha_sk
GROUP BY f_d.anio, f_d.trimestre
ORDER BY f_d.anio, f_d.trimestre;
"""

Q1_DRILLDOWN_QTR_SNOW = Q1_DRILLDOWN_QTR_STAR


# ---------------------------------------------------------------------------
# Q2: Margen bruto por categoría (pregunta de negocio 1 — IPSI vs IVA)
# ---------------------------------------------------------------------------
Q2_OLTP = """
SELECT
    cat.nombre                                          AS categoria,
    di.tipo_impuesto,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))    AS ingresos_netos,
    SUM(d.cantidad * COALESCE(cp.coste_unitario, 0))    AS costes,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))
    - SUM(d.cantidad * COALESCE(cp.coste_unitario, 0)) AS margen
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p        ON p.pedido_id   = d.pedido_id
JOIN oltp_ventas.productos pr     ON pr.producto_id = d.producto_id
JOIN oltp_ventas.categorias cat   ON cat.categoria_id = pr.categoria_id
JOIN oltp_finanzas.facturas fi    ON fi.pedido_id   = p.pedido_id
LEFT JOIN oltp_inventario.costes_producto cp ON cp.producto_id = d.producto_id
JOIN (VALUES ('IVA'), ('IPSI'), ('IGIC'), ('EXENTO')) AS di(tipo_impuesto)
    ON di.tipo_impuesto = fi.tipo_impuesto
GROUP BY cat.nombre, di.tipo_impuesto
ORDER BY cat.nombre, di.tipo_impuesto;
"""

Q2_STAR = """
SELECT
    dp.categoria,
    di.tipo_impuesto,
    SUM(f.importe_neto)    AS ingresos_netos,
    SUM(f.coste_linea)     AS costes,
    SUM(f.margen_linea)    AS margen
FROM olap.fact_ventas_linea f
JOIN olap.dim_producto dp  ON dp.producto_sk  = f.producto_sk
JOIN olap.dim_impuesto di  ON di.impuesto_sk  = f.impuesto_sk
GROUP BY dp.categoria, di.tipo_impuesto
ORDER BY dp.categoria, di.tipo_impuesto;
"""

Q2_SNOW = """
SELECT
    dc.nombre               AS categoria,
    di.tipo_impuesto,
    SUM(f.importe_neto)     AS ingresos_netos,
    SUM(f.coste_linea)      AS costes,
    SUM(f.margen_linea)     AS margen
FROM olap.fact_ventas_linea f
JOIN olap.dim_producto_sn dp   ON dp.producto_sk  = f.producto_sk
JOIN olap.dim_categoria_sn dc  ON dc.categoria_sk = dp.categoria_sk
JOIN olap.dim_impuesto di      ON di.impuesto_sk  = f.impuesto_sk
GROUP BY dc.nombre, di.tipo_impuesto
ORDER BY dc.nombre, di.tipo_impuesto;
"""

# ---------------------------------------------------------------------------
# Q3: Tiempo medio de demora en aduanas por transportista (pregunta 2)
# ---------------------------------------------------------------------------
Q3_OLTP = """
SELECT
    t.nombre                              AS transportista,
    t.tipo_servicio,
    COUNT(*)                              AS num_envios,
    ROUND(AVG(ta.horas_demora), 2)        AS media_horas_demora,
    ROUND(AVG(e.coste_envio + COALESCE(ta.coste_tramite, 0)), 2) AS coste_logistico_medio
FROM oltp_logistica.envios e
JOIN oltp_logistica.transportistas t  ON t.transportista_id = e.transportista_id
LEFT JOIN oltp_logistica.tramites_aduanas ta ON ta.envio_id  = e.envio_id
GROUP BY t.nombre, t.tipo_servicio
ORDER BY media_horas_demora DESC;
"""

Q3_STAR = """
SELECT
    dt.nombre               AS transportista,
    dt.tipo_servicio,
    COUNT(*)                AS num_envios,
    ROUND(AVG(f.horas_demora_aduanas), 2)  AS media_horas_demora,
    ROUND(AVG(f.coste_total_logistica), 2) AS coste_logistico_medio
FROM olap.fact_envios f
JOIN olap.dim_transportista dt ON dt.transportista_sk = f.transportista_sk
GROUP BY dt.nombre, dt.tipo_servicio
ORDER BY media_horas_demora DESC;
"""

Q3_SNOW = Q3_STAR   # dim_transportista no tiene sub-dimensión en Snowflake

# ---------------------------------------------------------------------------
# Q4: Volumen de ventas y margen por provincia (pregunta 3)
# ---------------------------------------------------------------------------
Q4_OLTP = """
SELECT
    cl.provincia,
    COUNT(DISTINCT p.pedido_id)             AS num_pedidos,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))    AS ingresos_netos,
    SUM(d.cantidad * COALESCE(cp.coste_unitario, 0))    AS costes,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))
    - SUM(d.cantidad * COALESCE(cp.coste_unitario, 0))  AS margen,
    ROUND(AVG(COALESCE(e.coste_envio, 0)), 2)           AS coste_envio_medio
FROM oltp_ventas.detalle_pedido d
JOIN oltp_ventas.pedidos p          ON p.pedido_id   = d.pedido_id
JOIN oltp_ventas.clientes cl        ON cl.cliente_id = p.cliente_id
LEFT JOIN oltp_inventario.costes_producto cp ON cp.producto_id = d.producto_id
LEFT JOIN oltp_logistica.envios e   ON e.pedido_id   = p.pedido_id
GROUP BY cl.provincia
ORDER BY ingresos_netos DESC;
"""

Q4_STAR = """
SELECT
    dc.provincia,
    COUNT(DISTINCT f.pedido_nk)         AS num_pedidos,
    SUM(f.importe_neto)                 AS ingresos_netos,
    SUM(f.coste_linea)                  AS costes,
    SUM(f.margen_linea)                 AS margen,
    ROUND(AVG(fe.coste_envio), 2)       AS coste_envio_medio
FROM olap.fact_ventas_linea f
JOIN olap.dim_cliente dc    ON dc.cliente_sk = f.cliente_sk
LEFT JOIN olap.fact_envios fe ON fe.pedido_nk = f.pedido_nk
GROUP BY dc.provincia
ORDER BY ingresos_netos DESC;
"""

Q4_SNOW = Q4_STAR   # dim_cliente no tiene Snowflake en nuestro modelo

# ---------------------------------------------------------------------------
# Q5: Ranking de empleados — ventas vs comisiones vs objetivo (pregunta RRHH)
# ---------------------------------------------------------------------------
Q5_OLTP = """
SELECT
    e.nombre || ' ' || e.apellidos       AS empleado,
    e.territorio,
    COUNT(DISTINCT p.pedido_id)           AS num_pedidos,
    SUM(d.cantidad * d.precio_unitario
        * (1 - COALESCE(p.descuento_pct, 0) / 100))  AS ingresos_generados,
    SUM(c.importe)                        AS comisiones_cobradas,
    ROUND(100.0 * SUM(c.importe)
          / NULLIF(SUM(d.cantidad * d.precio_unitario
              * (1 - COALESCE(p.descuento_pct, 0) / 100)), 0), 2) AS pct_comision_real
FROM oltp_rrhh.empleados e
JOIN oltp_ventas.pedidos p        ON p.empleado_id = e.empleado_id
JOIN oltp_ventas.detalle_pedido d ON d.pedido_id   = p.pedido_id
LEFT JOIN oltp_rrhh.comisiones c  ON c.empleado_id = e.empleado_id
                                  AND c.pedido_id  = p.pedido_id
GROUP BY e.nombre, e.apellidos, e.territorio
ORDER BY ingresos_generados DESC;
"""

Q5_STAR = """
SELECT
    de.nombre_completo              AS empleado,
    de.territorio,
    COUNT(DISTINCT f.pedido_nk)     AS num_pedidos,
    SUM(f.importe_neto)             AS ingresos_generados,
    SUM(fc.importe_comision)        AS comisiones_cobradas,
    ROUND(100.0 * SUM(fc.importe_comision)
          / NULLIF(SUM(f.importe_neto), 0), 2)   AS pct_comision_real
FROM olap.fact_ventas_linea f
JOIN olap.dim_empleado de    ON de.empleado_sk = f.empleado_sk
LEFT JOIN olap.fact_comisiones fc ON fc.empleado_sk = f.empleado_sk
                                 AND fc.pedido_nk   = f.pedido_nk
GROUP BY de.nombre_completo, de.territorio
ORDER BY ingresos_generados DESC;
"""

Q5_SNOW = Q5_STAR   # dim_empleado no tiene Snowflake en nuestro modelo

# ---------------------------------------------------------------------------
# Estructura de datos de consultas
# ---------------------------------------------------------------------------
@dataclass
class QuerySet:
    name: str
    oltp: str
    star: str
    snow: str


QUERIES: list[QuerySet] = [
    QuerySet(
        "Q1-RollUp (ingresos/año)",
        Q1_ROLLUP_YEAR_OLTP,
        Q1_ROLLUP_YEAR_STAR,
        Q1_ROLLUP_YEAR_SNOW,
    ),
    QuerySet(
        "Q1-DrillDown (ingresos/trimestre)",
        Q1_DRILLDOWN_QTR_OLTP,
        Q1_DRILLDOWN_QTR_STAR,
        Q1_DRILLDOWN_QTR_SNOW,
    ),
    QuerySet(
        "Q2 (margen por categoría e impuesto)",
        Q2_OLTP,
        Q2_STAR,
        Q2_SNOW,
    ),
    QuerySet(
        "Q3 (demora aduanas por transportista)",
        Q3_OLTP,
        Q3_STAR,
        Q3_SNOW,
    ),
    QuerySet(
        "Q4 (ventas y margen por provincia)",
        Q4_OLTP,
        Q4_STAR,
        Q4_SNOW,
    ),
    QuerySet(
        "Q5 (ranking empleados ventas vs comisiones)",
        Q5_OLTP,
        Q5_STAR,
        Q5_SNOW,
    ),
]

# ---------------------------------------------------------------------------
# Motor de medición
# ---------------------------------------------------------------------------
def measure(cursor: psycopg2.extensions.cursor, query: str, reps: int) -> list[float]:
    times: list[float] = []
    for _ in range(reps):
        t0 = time.perf_counter()
        cursor.execute(query)
        cursor.fetchall()
        times.append((time.perf_counter() - t0) * 1000)  # ms
    return times


def summarize(times: list[float]) -> dict[str, float]:
    return {
        "mean_ms": round(statistics.mean(times), 3),
        "stdev_ms": round(statistics.stdev(times), 3) if len(times) > 1 else 0.0,
        "min_ms": round(min(times), 3),
        "max_ms": round(max(times), 3),
    }


# ---------------------------------------------------------------------------
# Presentación de resultados
# ---------------------------------------------------------------------------
COL = 28

def print_header() -> None:
    print("\n" + "=" * 90)
    print(" BENCHMARK CEUTA CONNECT — Star vs Snowflake vs OLTP")
    print("=" * 90)
    print(f"{'Consulta':<{COL}} {'Modelo':<8} {'Media (ms)':>10} {'StdDev':>8} {'Min':>8} {'Max':>8}")
    print("-" * 90)


def print_row(query_name: str, model: str, stats: dict[str, float]) -> None:
    print(
        f"{query_name:<{COL}} {model:<8} "
        f"{stats['mean_ms']:>10.3f} {stats['stdev_ms']:>8.3f} "
        f"{stats['min_ms']:>8.3f} {stats['max_ms']:>8.3f}"
    )


def print_comparison_table(results: list[dict]) -> None:
    print("\n" + "=" * 90)
    print(" TABLA COMPARATIVA STAR vs SNOWFLAKE vs OLTP (media en ms)")
    print("=" * 90)
    header = f"{'Consulta':<{COL}} {'OLTP':>10} {'STAR':>10} {'SNOW':>10} {'Star vs OLTP':>14} {'Star vs Snow':>14}"
    print(header)
    print("-" * 90)
    for r in results:
        oltp_ms = r["oltp"]["mean_ms"]
        star_ms = r["star"]["mean_ms"]
        snow_ms = r["snow"]["mean_ms"]
        vs_oltp = f"{(oltp_ms / star_ms - 1) * 100:+.1f}%" if star_ms else "N/A"
        vs_snow = f"{(snow_ms / star_ms - 1) * 100:+.1f}%" if star_ms else "N/A"
        print(
            f"{r['name']:<{COL}} {oltp_ms:>10.3f} {star_ms:>10.3f} {snow_ms:>10.3f} "
            f"{vs_oltp:>14} {vs_snow:>14}"
        )
    print("=" * 90)
    print("  Star vs OLTP: positivo = OLTP es más lento (Star gana)")
    print("  Star vs Snow: positivo = Snow es más lento (Star gana)")


# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------
def main() -> None:
    conn = psycopg2.connect(**DB_CONFIG)
    conn.set_session(readonly=True, autocommit=True)
    cur = conn.cursor()

    print_header()
    all_results: list[dict] = []

    for qs in QUERIES:
        row: dict = {"name": qs.name, "oltp": {}, "star": {}, "snow": {}}

        for model, query in (("OLTP", qs.oltp), ("STAR", qs.star), ("SNOW", qs.snow)):
            try:
                times = measure(cur, query, REPETITIONS)
                stats = summarize(times)
                print_row(qs.name, model, stats)
                row[model.lower()] = stats
            except Exception as exc:  # noqa: BLE001
                print(f"  ERROR en {qs.name} [{model}]: {exc}")
                conn.rollback()
                row[model.lower()] = {"mean_ms": 0.0, "stdev_ms": 0.0, "min_ms": 0.0, "max_ms": 0.0}

        print("-" * 90)
        all_results.append(row)

    print_comparison_table(all_results)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()

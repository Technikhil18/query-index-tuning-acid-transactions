-- Run after setup_and_seed.sql and BEFORE create_indexes.sql.
SET search_path TO index_tuning_demo, public;

-- Baseline query: selective tenant/status/date filter.
-- Save the complete EXPLAIN output in optimization_report.md.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, SETTINGS)
SELECT order_id, customer_id, total_amount, created_at
FROM orders
WHERE tenant_id = 41
  AND status = 'pending'
  AND created_at >= TIMESTAMPTZ '2025-01-10 00:00:00+00'
  AND created_at <  TIMESTAMPTZ '2025-01-15 00:00:00+00'
ORDER BY created_at DESC;

-- Baseline inventory lookup: before product_id index (PK exists, so this is
-- expected to use the primary-key index already). It is included as a contrast,
-- not as the main before/after benchmark.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
SELECT product_id, product_name, stock_quantity
FROM inventory
WHERE product_id = 25000;

-- Baseline partial-index use case. Before the partial index, PostgreSQL may
-- choose a sequential scan because no suitable status-specific index exists.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, SETTINGS)
SELECT order_id, customer_id, created_at
FROM orders
WHERE status = 'pending'
  AND customer_id = 120
ORDER BY created_at DESC
LIMIT 20;

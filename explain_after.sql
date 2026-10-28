-- Run after create_indexes.sql. Compare plans with explain_before.sql.
SET search_path TO index_tuning_demo, public;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, SETTINGS)
SELECT order_id, customer_id, total_amount, created_at
FROM orders
WHERE tenant_id = 41
  AND status = 'pending'
  AND created_at >= TIMESTAMPTZ '2025-01-10 00:00:00+00'
  AND created_at <  TIMESTAMPTZ '2025-01-15 00:00:00+00'
ORDER BY created_at DESC;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, SETTINGS)
SELECT order_id, customer_id, created_at
FROM orders
WHERE status = 'pending'
  AND customer_id = 120
ORDER BY created_at DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
SELECT transaction_id, quantity_change, transaction_type, created_at
FROM inventory_transactions
WHERE product_id = 25000
ORDER BY created_at DESC
LIMIT 20;

-- Optional repeatable timing helper: run each query several times manually.
-- First execution may include cold-cache I/O; subsequent runs may be faster.
-- Record planning time, execution time, scan type, actual rows, and shared buffers.

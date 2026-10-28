-- Run after saving baseline plans.
SET search_path TO index_tuning_demo, public;

-- 1) Composite B-tree index for equality predicates followed by a date range/order.
CREATE INDEX idx_orders_tenant_status_created
    ON orders USING BTREE (tenant_id, status, created_at DESC);

-- 2) Partial B-tree index for the frequently queried pending orders only.
CREATE INDEX idx_orders_pending_customer_created
    ON orders USING BTREE (customer_id, created_at DESC)
    WHERE status = 'pending';

-- 3) B-tree index on inventory history for product-specific transaction lookups.
CREATE INDEX idx_inventory_transactions_product_created
    ON inventory_transactions USING BTREE (product_id, created_at DESC);

-- Refresh planner statistics after index creation.
ANALYZE orders;
ANALYZE inventory_transactions;

-- List project indexes for proof/documentation.
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'index_tuning_demo'
ORDER BY tablename, indexname;

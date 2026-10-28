# Query Index Tuning & Execution Plan Report

## 1. Objective
Analyze query plans on a simulated dataset of 100,000 orders and 50,000 inventory items. Compare unindexed and indexed plans, test B-tree/composite/partial indexes, and demonstrate safe ACID transactions for inventory updates.

## 2. Environment
Fill in after running the scripts.

- PostgreSQL version: `________________`
- OS / machine: `________________`
- Database client: `________________`
- Date tested: `________________`
- Dataset row counts:
  - customers: 5,000
  - orders: 100,000
  - inventory: 50,000
  - inventory_transactions: 10,000

## 3. Test Query
```sql
SELECT order_id, customer_id, total_amount, created_at
FROM index_tuning_demo.orders
WHERE tenant_id = 41
  AND status = 'pending'
  AND created_at >= TIMESTAMPTZ '2025-01-10 00:00:00+00'
  AND created_at <  TIMESTAMPTZ '2025-01-15 00:00:00+00'
ORDER BY created_at DESC;
```

## 4. Indexes Created

| Index | Type | Purpose |
|---|---|---|
| `idx_orders_tenant_status_created` | Composite B-tree | Equality filters on tenant/status, followed by date filtering and descending order |
| `idx_orders_pending_customer_created` | Partial B-tree | Smaller index for `status = 'pending'` queries by customer and date |
| `idx_inventory_transactions_product_created` | Composite B-tree | Product-specific transaction history ordered by timestamp |

PostgreSQL partial indexes contain only rows matching their `WHERE` predicate. The query must imply that predicate (here, `status = 'pending'`) for the planner to consider the partial index.

## 5. Before/After Evidence

Paste the complete output from `EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, SETTINGS)` into the sections below. Do not invent execution times; they vary by system and cache state.

### Baseline plan — before indexes
Paste output from `explain_before.sql` here:

```text
PASTE ACTUAL EXPLAIN OUTPUT HERE
```

- Scan type observed: `________________`
- Planning time: `________ ms`
- Execution time: `________ ms`
- Actual rows returned: `________`
- Shared hit/read buffers: `________________`

### Optimized plan — after indexes
Paste output from `explain_after.sql` here:

```text
PASTE ACTUAL EXPLAIN OUTPUT HERE
```

- Scan type observed: `________________`
- Planning time: `________ ms`
- Execution time: `________ ms`
- Actual rows returned: `________`
- Shared hit/read buffers: `________________`

### Timing comparison

| Metric | Before | After |
|---|---:|---:|
| Execution time (ms) | Fill from plan | Fill from plan |
| Shared buffer hits | Fill from plan | Fill from plan |
| Shared buffer reads | Fill from plan | Fill from plan |
| Scan type | Fill from plan | Fill from plan |

Improvement percentage (if before time is non-zero):

`((before_ms - after_ms) / before_ms) * 100 = ______ %`

For a fairer comparison, run each query multiple times, note the first (possibly cold-cache) run separately, and compare repeated runs. Use the same query and data in both tests.

## 6. How to Read the Plan
- `Seq Scan`: PostgreSQL checks rows from the table sequentially. This can be appropriate for small tables or queries returning a large share of rows.
- `Index Scan`: PostgreSQL uses an index to locate matching rows and fetch table rows.
- `Bitmap Index Scan` + `Bitmap Heap Scan`: PostgreSQL collects matching row locations from an index and visits heap pages in a batch.
- `actual time`: measured execution time for plan nodes; the top-level `Execution Time` is the overall query time.
- `rows`: estimated row count in the plan; `actual rows` is what was produced at runtime.
- `Buffers`: shared buffer hits/reads help indicate data access. A lower execution time is not guaranteed on every run because cache, load, and planner decisions vary.
- `EXPLAIN ANALYZE` executes the statement. The scripts use SELECT queries for benchmarking to avoid changing data.

## 7. ACID Transaction Evidence
Run `transaction_scripts.sql` and record:

- Sale transaction changed stock only when enough stock existed: `PASS / FAIL`
- Audit row inserted for successful sale: `PASS / FAIL`
- Rollback restored product 101 stock: `PASS / FAIL`
- Concurrent conditional updates did not drive stock below zero: `PASS / FAIL`

### ACID summary
- **Atomicity:** all related changes succeed together or are rolled back.
- **Consistency:** constraints enforce valid stock quantities.
- **Isolation:** row locks and conditional updates protect against concurrent stock decrements.
- **Durability:** committed changes persist.

## 8. Conclusion
Complete this section after testing. Describe which plan changed, whether the composite/partial indexes were selected, the measured timing difference, and any cases where PostgreSQL correctly chose a sequential scan. An index is not automatically faster for every query; index usefulness depends on selectivity, table size, and data distribution.

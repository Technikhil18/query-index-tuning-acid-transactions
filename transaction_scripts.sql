-- ACID transaction examples for inventory.
-- Run in a TEST database only.
SET search_path TO index_tuning_demo, public;

-- A) SAFE inventory sale.
-- The row lock prevents another transaction from changing this product's stock
-- between validation and decrement. The CHECK constraint prevents negative stock.
-- IMPORTANT: inspect the UPDATE ... RETURNING result. If it returns zero rows,
-- issue ROLLBACK instead of COMMIT.

BEGIN;

SELECT product_id, stock_quantity
FROM inventory
WHERE product_id = 100
FOR UPDATE;

WITH updated_stock AS (
    UPDATE inventory
    SET stock_quantity = stock_quantity - 3,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = 100
      AND stock_quantity >= 3
    RETURNING product_id, stock_quantity
)
INSERT INTO inventory_transactions
    (product_id, quantity_change, transaction_type, reference_note)
SELECT product_id, -3, 'sale', 'Demo sale transaction'
FROM updated_stock
RETURNING product_id, quantity_change, transaction_type;

-- The audit row is inserted only if the conditional stock update succeeds.
-- If UPDATE matches no row, the INSERT also inserts zero rows.
-- In an application, check the RETURNING result and ROLLBACK if no row is returned;
-- COMMIT only when the stock change and audit insert both succeed.
COMMIT;


-- B) ROLLBACK demonstration: the inventory change is undone.
-- Run this block separately to observe rollback behavior.
BEGIN;

UPDATE inventory
SET stock_quantity = stock_quantity - 1,
    updated_at = CURRENT_TIMESTAMP
WHERE product_id = 101
  AND stock_quantity >= 1
RETURNING product_id, stock_quantity;

-- Intentional rollback for demonstration:
ROLLBACK;

-- Verify stock for product 101 is unchanged from its value before block B.
SELECT product_id, stock_quantity
FROM inventory
WHERE product_id = 101;


-- C) Safe one-statement conditional decrement pattern.
-- This atomic UPDATE is often the simplest safe approach for a single-row stock
-- decrement. If no row is returned, the product is missing or stock is insufficient.
BEGIN;

UPDATE inventory
SET stock_quantity = stock_quantity - 2,
    updated_at = CURRENT_TIMESTAMP
WHERE product_id = 102
  AND stock_quantity >= 2
RETURNING product_id, stock_quantity;

-- Application should COMMIT only when one row is returned; otherwise ROLLBACK.
-- The following COMMIT is a placeholder for the success path:
COMMIT;


-- D) Two-session concurrency test (manual).
-- Session A:
--   BEGIN;
--   SELECT stock_quantity FROM index_tuning_demo.inventory
--     WHERE product_id = 103 FOR UPDATE;
--   UPDATE index_tuning_demo.inventory
--     SET stock_quantity = stock_quantity - 4
--     WHERE product_id = 103 AND stock_quantity >= 4
--     RETURNING stock_quantity;
--   -- Do NOT commit yet.
--
-- Session B (while Session A is still open):
--   BEGIN;
--   UPDATE index_tuning_demo.inventory
--     SET stock_quantity = stock_quantity - 4
--     WHERE product_id = 103 AND stock_quantity >= 4
--     RETURNING stock_quantity;
--   -- Session B waits for A's row lock. After A commits, B rechecks the
--   -- condition; if insufficient stock remains, it returns zero rows.
--   ROLLBACK; -- or COMMIT only if the UPDATE returned one row.
--
-- Session A:
--   COMMIT;
--
-- ACID notes:
-- Atomicity: stock decrement and transaction log insert belong in one transaction.
-- Consistency: CHECK (stock_quantity >= 0) preserves the stock invariant.
-- Isolation: row locks/atomic conditional UPDATE serialize competing updates.
-- Durability: COMMIT persists successful changes according to PostgreSQL settings.

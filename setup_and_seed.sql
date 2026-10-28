-- Project: Query Index Tuning, Execution Plans & ACID Transactions
-- PostgreSQL 12+
-- WARNING: Drops only this demo schema. Do not run against a database with data you need.

DROP SCHEMA IF EXISTS index_tuning_demo CASCADE;
CREATE SCHEMA index_tuning_demo;
SET search_path TO index_tuning_demo, public;

CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name TEXT NOT NULL,
    region TEXT NOT NULL
);

CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id INTEGER NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')),
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL,
    notes TEXT
);

CREATE TABLE inventory (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES inventory(product_id),
    quantity_change INTEGER NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('sale', 'restock', 'adjustment')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_note TEXT
);

-- Seed 5,000 customers.
INSERT INTO customers (customer_name, region)
SELECT
    'Customer ' || g,
    (ARRAY['North', 'South', 'East', 'West', 'Central'])[((g - 1) % 5) + 1]
FROM generate_series(1, 5000) AS g;

-- Seed 100,000 orders. Data is intentionally distributed to allow selective filters.
INSERT INTO orders (tenant_id, customer_id, status, total_amount, created_at, notes)
SELECT
    ((g - 1) % 500) + 1,
    ((g - 1) % 5000) + 1,
    CASE
        WHEN g % 20 = 0 THEN 'pending'
        WHEN g % 10 = 0 THEN 'cancelled'
        WHEN g % 3 = 0 THEN 'shipped'
        ELSE 'paid'
    END,
    (10 + ((g * 37) % 200000) / 100.0)::NUMERIC(10,2),
    TIMESTAMPTZ '2025-01-01 00:00:00+00' + (g % 6000000) * INTERVAL '1 minute',
    CASE WHEN g % 7 = 0 THEN 'Priority order' ELSE NULL END
FROM generate_series(1, 100000) AS g;

-- Seed 50,000 inventory rows.
INSERT INTO inventory (product_id, product_name, stock_quantity, updated_at)
SELECT
    g,
    'Product ' || g,
    10 + (g % 500),
    CURRENT_TIMESTAMP - (g % 365) * INTERVAL '1 day'
FROM generate_series(1, 50000) AS g;

-- Seed a small amount of inventory history.
INSERT INTO inventory_transactions (product_id, quantity_change, transaction_type, reference_note)
SELECT
    ((g - 1) % 50000) + 1,
    CASE WHEN g % 2 = 0 THEN -1 ELSE 5 END,
    CASE WHEN g % 2 = 0 THEN 'sale' ELSE 'restock' END,
    'Seed transaction ' || g
FROM generate_series(1, 10000) AS g;

ANALYZE customers;
ANALYZE orders;
ANALYZE inventory;
ANALYZE inventory_transactions;

-- Row-count verification
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'inventory_transactions', COUNT(*) FROM inventory_transactions;

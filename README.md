# Query Index Tuning, Execution Plans & ACID Transactions

A PostgreSQL project demonstrating query performance analysis on 50,000+ simulated rows, B-tree/composite/partial indexes, and safe inventory transactions.

## Technology
- PostgreSQL 12+ (recommended: PostgreSQL 15+)
- SQL scripts can be run in `psql` or a PostgreSQL GUI such as pgAdmin.
- This project uses PostgreSQL because it supports partial indexes and `EXPLAIN (ANALYZE, BUFFERS)`.

## Files
- `setup_and_seed.sql` — creates the demo schema and generates 100,000 orders spread across multiple weeks plus 50,000 inventory rows.
- `explain_before.sql` — captures plans before indexes are created.
- `create_indexes.sql` — creates B-tree, composite, and partial indexes.
- `explain_after.sql` — captures plans after indexing.
- `transaction_scripts.sql` — safe stock decrement, audit insert, rollback demonstration, and concurrency notes.
- `optimization_report.md` — report template and steps for recording actual plans/timings.

## Run in order
Open a PostgreSQL database you can use for practice, then execute these scripts in order:

1. `setup_and_seed.sql`
2. `explain_before.sql`
3. `create_indexes.sql`
4. `explain_after.sql`
5. `transaction_scripts.sql`

Example using `psql`:
```bash
psql -U postgres -d your_database -f setup_and_seed.sql
psql -U postgres -d your_database -f explain_before.sql
psql -U postgres -d your_database -f create_indexes.sql
psql -U postgres -d your_database -f explain_after.sql
psql -U postgres -d your_database -f transaction_scripts.sql
```

Replace `your_database` with your database name. Do not run these scripts against production data.

## Important
- `EXPLAIN ANALYZE` actually executes the query. Use it only for safe SELECT statements in this project.
- Query plans depend on PostgreSQL version, hardware, cache state, and data distribution. Do not copy made-up timing numbers into your report; record your own results.
- The planner may choose a sequential scan for small tables or low-selectivity predicates even when an index exists. The report explains how to interpret that outcome.
- For the concurrency demo, run the two-session steps in `transaction_scripts.sql` in separate database sessions.

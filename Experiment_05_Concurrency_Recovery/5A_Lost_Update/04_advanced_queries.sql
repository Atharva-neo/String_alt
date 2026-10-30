-- Experiment 5A - examiner follow-ups (two-terminal scripts; same convention: "-- S1>" terminal 1, "-- S2>" terminal 2). Not executed by tools/run_sql.py.

-- ### ADV 1: Lost update prevented with SERIALIZABLE instead of FOR UPDATE
-- Under SERIALIZABLE a plain SELECT becomes a locking read. Both sessions take S locks, both then want X locks => one of them is the deadlock victim (error 1213) and must retry.
-- S1> SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;  S2> SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- S1> START TRANSACTION; SELECT qty FROM Stock WHERE item_id = 1;   S2> START TRANSACTION; SELECT qty FROM Stock WHERE item_id = 1;
-- S1> UPDATE Stock SET qty = 70 WHERE item_id = 1;   (waits for S2's S lock)   S2> UPDATE Stock SET qty = 50 WHERE item_id = 1;   -> ERROR 1213 deadlock, S1 proceeds

-- ### ADV 2: Optimistic locking with a version column (no long locks)
-- ALTER TABLE Stock ADD COLUMN version INT NOT NULL DEFAULT 0;
-- S1> SELECT qty, version FROM Stock WHERE item_id = 1;           -- 100, 0
-- S2> SELECT qty, version FROM Stock WHERE item_id = 1;           -- 100, 0
-- S1> UPDATE Stock SET qty = 70, version = version + 1 WHERE item_id = 1 AND version = 0;   -- 1 row affected
-- S2> UPDATE Stock SET qty = 50, version = version + 1 WHERE item_id = 1 AND version = 0;   -- 0 rows affected => conflict detected, S2 re-reads and retries

-- ### ADV 3: Which statements take which locks?
-- SELECT (RR, plain)       : no lock, consistent snapshot read
-- SELECT ... FOR SHARE     : shared (S) row lock          UPDATE / DELETE / SELECT ... FOR UPDATE : exclusive (X) row lock
-- LOCK TABLES t READ|WRITE : table-level lock held by the session, released by UNLOCK TABLES (or session end)

-- ### ADV 4: Show who is waiting for whom
-- SELECT * FROM performance_schema.data_lock_waits;      SELECT * FROM sys.innodb_lock_waits\G

# Expected output - Experiment_05_Concurrency_Recovery / 5A_Lost_Update

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Multi-session demonstration (`run_demo.py`, real connections)

> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.

### Task 1 - Stock is an InnoDB table; autocommit is switched off in both sessions

admin> SELECT table_name, engine FROM information_schema.tables WHERE table_schema = 'stock_5a'
+------------+--------+
| TABLE_NAME | ENGINE |
+------------+--------+
| stock      | InnoDB |
+------------+--------+
1 row in set
admin> SELECT * FROM Stock
+---------+---------------+-----+
| item_id | item_name     | qty |
+---------+---------------+-----+
|       1 | Printer Paper | 100 |
|       2 | Toner         |  20 |
+---------+---------------+-----+
2 rows in set
S1> SET autocommit = 0
OK
S2> SET autocommit = 0
OK
S1> SELECT @@autocommit AS autocommit
+------------+
| autocommit |
+------------+
|          0 |
+------------+
1 row in set

#### Task 2 - Isolation level of both sessions

S1> SELECT @@transaction_isolation AS isolation
+-----------------+
| isolation       |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set
S2> SELECT @@transaction_isolation AS isolation
+-----------------+
| isolation       |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set

#### Task 3 - READ UNCOMMITTED in both sessions: the lost update

S1> SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
OK
S2> SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
OK
S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S1> SELECT qty FROM Stock WHERE item_id = 1
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S2> SELECT qty FROM Stock WHERE item_id = 1
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
-- both sessions now hold the value 100 in their head
S1> UPDATE Stock SET qty = 70 WHERE item_id = 1
OK, 1 row affected
-- S2 computes 100 - 50 = 50 from its stale read; the row is X-locked by S1, so S2 waits
S2> UPDATE Stock SET qty = 50 WHERE item_id = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> COMMIT
OK
admin> SELECT item_id, qty FROM Stock WHERE item_id = 1
+---------+-----+
| item_id | qty |
+---------+-----+
|       1 |  50 |
+---------+-----+
1 row in set
-- FINAL qty = 50, but 100 - 30 - 50 = 20 was expected: S1's update of -30 was overwritten = LOST UPDATE

#### Task 4 - Schedule (time-line table) of the transactions of Task 3

| Step | S1 | S2 |
|---|---|---|
| 6 | SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED |  |
| 7 |  | SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED |
| 8 | START TRANSACTION |  |
| 9 |  | START TRANSACTION |
| 10 | SELECT qty FROM Stock WHERE item_id = 1 |  |
| 11 |  | SELECT qty FROM Stock WHERE item_id = 1 |
| 12 | UPDATE Stock SET qty = 70 WHERE item_id = 1 |  |
| 13 |  | UPDATE Stock SET qty = 50 WHERE item_id = 1 |
| 14 | COMMIT |  |
| 15 |  | COMMIT |
-- Operation sequence: R1(X) R2(X) W1(X) C1 W2(X) C2

#### Task 5 - Reset to 100, repeat with SELECT ... FOR UPDATE (exclusive lock on the read)

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 1 row affected
S1> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S2> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S1> SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S2> SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE
   [STILL RUNNING - blocked, waiting for a lock]
S1> UPDATE Stock SET qty = 70 WHERE item_id = 1
OK, 1 row affected
S1> COMMIT
OK
S2> (the blocked statement finishes)
+-----+
| qty |
+-----+
|  70 |
+-----+
1 row in set
-- S2 now reads the COMMITTED 70 (not the stale 100) and computes 70 - 50 = 20
S2> UPDATE Stock SET qty = 20 WHERE item_id = 1
OK, 1 row affected
S2> COMMIT
OK
admin> SELECT item_id, qty FROM Stock WHERE item_id = 1
+---------+-----+
| item_id | qty |
+---------+-----+
|       1 |  20 |
+---------+-----+
1 row in set
-- FINAL qty = 20: no update was lost

#### Task 6 - Reset, relative updates: UPDATE Stock SET qty = qty - 30 / qty - 50

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 1 row affected
S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S1> UPDATE Stock SET qty = qty - 30 WHERE item_id = 1
OK, 1 row affected
S2> UPDATE Stock SET qty = qty - 50 WHERE item_id = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> COMMIT
OK
admin> SELECT item_id, qty FROM Stock WHERE item_id = 1
+---------+-----+
| item_id | qty |
+---------+-----+
|       1 |  20 |
+---------+-----+
1 row in set
-- FINAL qty = 20 again - and with a single statement per transaction; no explicit locking code is needed

#### Task 7 - Shared lock: S1 holds LOCK IN SHARE MODE, S2 may read but not write

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 1 row affected
S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S1> SELECT qty FROM Stock WHERE item_id = 1 LOCK IN SHARE MODE
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S2> SELECT qty FROM Stock WHERE item_id = 1
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S2> UPDATE Stock SET qty = qty - 1 WHERE item_id = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> ROLLBACK
OK

#### Task 8 - LOCK TABLES Stock WRITE in S1: S2 is blocked until UNLOCK TABLES

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 0 rows affected
S1> LOCK TABLES Stock WRITE
OK
S1> UPDATE Stock SET qty = qty - 30 WHERE item_id = 1
OK, 1 row affected
S2> SELECT qty FROM Stock WHERE item_id = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> COMMIT
OK
S1> UNLOCK TABLES
OK
S2> (the blocked statement finishes)
+-----+
| qty |
+-----+
|  70 |
+-----+
1 row in set
S2> COMMIT
OK

#### Task 9 - LOCK TABLES Stock READ: even the locking session cannot update

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 1 row affected
S1> LOCK TABLES Stock READ
OK
S1> SELECT qty FROM Stock WHERE item_id = 1
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S1> UPDATE Stock SET qty = qty - 1 WHERE item_id = 1
ERROR 1099 (HY000): Table 'Stock' was locked with a READ lock and can't be updated
S2> SELECT qty FROM Stock WHERE item_id = 1
+-----+
| qty |
+-----+
| 100 |
+-----+
1 row in set
S2> UPDATE Stock SET qty = qty - 1 WHERE item_id = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> UNLOCK TABLES
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> ROLLBACK
OK

#### Task 10 - Lock-wait timeout: S1 stays open, S2 gives up

admin> UPDATE Stock SET qty = 100 WHERE item_id = 1
OK, 0 rows affected
S1> START TRANSACTION
OK
S1> UPDATE Stock SET qty = qty - 1 WHERE item_id = 1
OK, 1 row affected
S2> SET SESSION innodb_lock_wait_timeout = 2
OK
S2> SELECT @@innodb_lock_wait_timeout AS timeout_seconds
+-----------------+
| timeout_seconds |
+-----------------+
|               2 |
+-----------------+
1 row in set
S2> START TRANSACTION
OK
-- S2 waits 2 seconds for S1's lock, then fails (default timeout is 50 s):
S2> UPDATE Stock SET qty = qty - 2 WHERE item_id = 1
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
S1> ROLLBACK
OK
S2> ROLLBACK
OK

#### Task 11 - Conflict serializability of the schedule of Task 3 (precedence graph)

Schedule: Task 3 (READ UNCOMMITTED, lost update)
  R1(X) R2(X) W1(X) W2(X)
  precedence edges: T1 -> T2, T2 -> T1
  cycle found: T1 -> T2 -> T1  => NOT conflict serializable
Schedule: Task 5 (SELECT ... FOR UPDATE, T2 reads after T1 committed)
  R1(X) W1(X) R2(X) W2(X)
  precedence edges: T1 -> T2
  no cycle => conflict serializable, equivalent serial order: T1 , T2

#### Task 12 - Why two-phase locking prevents the lost update

-- T1: lock-X(X) [growing] ... R1 W1 ... COMMIT -> release all locks [shrinking, strict 2PL]
-- T2: lock-X(X) must WAIT until T1 releases it, so R2 can only happen after W1/C1 -> schedule R1 W1 C1 R2 W2 = serial order T1, T2.
-- The interleaving R1 R2 W1 W2 of Task 3 needs both transactions to read X without the exclusive lock, which 2PL forbids.

(session scripts written)

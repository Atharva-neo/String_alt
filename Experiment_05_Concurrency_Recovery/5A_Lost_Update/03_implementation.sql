-- Experiment 5A - Lost update on stock : the 12 tasks as two-terminal scripts.
-- Open TWO terminals:   mysql -u root -p stock_5a     (Session 1)   and   mysql -u root -p stock_5a   (Session 2)
-- Lines starting with "-- S1>" go to terminal 1, lines starting with "-- S2>" go to terminal 2, strictly in the order shown.
-- run_demo.py replays exactly this with two real connections (its transcript is in 05_expected_output.md); session1.sql / session2.sql are the same steps per terminal.
/* @CONCEPTS
* **Lost update**: two transactions read the same value, both compute a new value from their stale read, the later write overwrites the earlier one.
* **Locks**: `FOR UPDATE` = exclusive (X) lock on the rows read; `LOCK IN SHARE MODE` / `FOR SHARE` = shared (S) lock (others may read, nobody may write); `LOCK TABLES t WRITE|READ` = table lock.
* `UPDATE t SET qty = qty - 30` is a single atomic read-modify-write inside the server, so it never loses an update.
* **Conflict serializability**: build the precedence graph (edge Ti -> Tj when an operation of Ti conflicts with a later one of Tj); a cycle means the schedule is not serializable.
* **Two-phase locking (2PL)**: a growing phase (acquire locks) then a shrinking phase (release). Strict 2PL holds X locks until COMMIT (what InnoDB does), guaranteeing serializable behaviour.
* A statement waiting for a lock fails after `innodb_lock_wait_timeout` seconds (default 50) with error 1205.
*/

-- ### TASK 1: Create Stock with InnoDB and insert the data; disable autocommit in both sessions
-- With autocommit ON every statement commits immediately, so no interleaving of two transactions would be possible.
-- S1> SET autocommit = 0;
-- S2> SET autocommit = 0;

-- ### TASK 2: Check the current isolation level in both sessions
-- Default is REPEATABLE-READ.
-- S1> SELECT @@transaction_isolation;
-- S2> SELECT @@transaction_isolation;

-- ### TASK 3: READ UNCOMMITTED in both; S1 reads qty, S2 reads qty, S1 sets 100-30, S2 sets 100-50, commit both
-- Both read 100. S1 writes 70 and commits; S2 (still working with its stale 100) writes 50 and commits. Final qty = 50, S1's -30 has vanished: LOST UPDATE.
-- S1> SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- S2> SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- S1> START TRANSACTION;
-- S2> START TRANSACTION;
-- S1> SELECT qty FROM Stock WHERE item_id = 1;
-- S2> SELECT qty FROM Stock WHERE item_id = 1;
-- S1> UPDATE Stock SET qty = 70 WHERE item_id = 1;      -- 100 - 30
-- S2> UPDATE Stock SET qty = 50 WHERE item_id = 1;      -- 100 - 50  (waits for S1's row lock)
-- S1> COMMIT;
-- S2> COMMIT;

-- ### TASK 4: Schedule (time-line table) of the two transactions of Task 3
-- The time-line is printed by run_demo.py (table with one column per session): R1(X) R2(X) W1(X) C1 W2(X) C2.

-- ### TASK 5: Reset qty to 100 and repeat with SELECT ... FOR UPDATE in both sessions
-- S1> UPDATE Stock SET qty = 100 WHERE item_id = 1; COMMIT;   (reset)
-- S1> START TRANSACTION;  S2> START TRANSACTION;
-- S1> SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE;     -- S1 gets the X lock
-- S2> SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE;     -- S2 WAITS
-- S1> UPDATE Stock SET qty = 70 WHERE item_id = 1;  COMMIT;
-- S2> (unblocks, reads the committed 70)  UPDATE Stock SET qty = 20 WHERE item_id = 1;  COMMIT;     -- final 20 = correct

-- ### TASK 6: Reset and repeat using UPDATE Stock SET qty = qty - 30 (atomic read-modify-write) and compare
-- Both transactions issue a relative update; the second waits for the first row lock and then applies its decrement to the new value: 100 - 30 - 50 = 20.

-- ### TASK 7: LOCK IN SHARE MODE in S1: S2 can read but not update
-- S1> SELECT qty FROM Stock WHERE item_id = 1 LOCK IN SHARE MODE;      (FOR SHARE in MySQL 8)
-- S2> SELECT qty FROM Stock WHERE item_id = 1;      -- works
-- S2> UPDATE Stock SET qty = qty - 1 WHERE item_id = 1;   -- blocks until S1 commits

-- ### TASK 8: LOCK TABLES Stock WRITE in S1: S2 is blocked until UNLOCK TABLES
-- S1> LOCK TABLES Stock WRITE;   ...   S2> SELECT ... (blocked)   S1> UNLOCK TABLES;

-- ### TASK 9: LOCK TABLES Stock READ: S1 itself cannot update
-- S1> LOCK TABLES Stock READ;  S1> UPDATE ... -> ERROR 1099 (table was locked with a READ lock and can't be updated)

-- ### TASK 10: Lock-wait timeout (innodb_lock_wait_timeout) by leaving S1 open
-- S1 holds the row lock without committing; S2 waits and fails with ERROR 1205 after the timeout (set to 2 s for the demo).

-- ### TASK 11: Is the schedule of Task 3 conflict serializable? (precedence graph)
-- Operations: R1(X) R2(X) W1(X) W2(X). R2(X) before W1(X) gives T2 -> T1; R1(X) before W2(X) gives T1 -> T2: the graph has a cycle, so it is NOT conflict serializable.
-- The Task 5 schedule (S2 only reads after S1's commit) produces only T1 -> T2: serializable (order T1, T2).

-- ### TASK 12: How two-phase locking prevents the lost update
-- Under (strict) 2PL T2 must obtain an exclusive lock on X before reading it for update; T1 keeps its X lock until COMMIT, so T2's read happens after T1's write.
-- The interleaving R1 R2 W1 W2 is impossible; only a serial-equivalent order (T1 then T2) can occur. SELECT ... FOR UPDATE is how the application asks InnoDB for that lock.

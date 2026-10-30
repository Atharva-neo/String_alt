# Expected output - Experiment_05_Concurrency_Recovery / 5C_Deadlocks

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Multi-session demonstration (`run_demo.py`, real connections)

> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.

### Task 1 - Create Account, insert the data, open two sessions

admin> SELECT * FROM Account
+--------+----------+
| acc_no | balance  |
+--------+----------+
|      1 | 10000.00 |
|      2 | 10000.00 |
+--------+----------+
2 rows in set
S1> START TRANSACTION
OK
S2> START TRANSACTION
OK

#### Task 2 - S1 debits account 1

S1> UPDATE Account SET balance = balance - 500 WHERE acc_no = 1
OK, 1 row affected

#### Task 3 - S2 debits account 2

S2> UPDATE Account SET balance = balance - 300 WHERE acc_no = 2
OK, 1 row affected

#### Task 4 - S1 wants account 2, S2 wants account 1: capture the deadlock error

-- S1 now waits for the lock S2 holds on row 2 ...
S1> UPDATE Account SET balance = balance + 500 WHERE acc_no = 2
   [STILL RUNNING - blocked, waiting for a lock]
-- ... and S2 requests the lock S1 holds on row 1 => cycle: InnoDB detects it at once.
S2> UPDATE Account SET balance = balance + 300 WHERE acc_no = 1
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
S1> (the blocked statement finishes)
OK, 1 row affected

#### Task 5 - Who was rolled back, who commits, final balances

-- The session that printed ERROR 1213 was the victim: its whole transaction (also the earlier UPDATE) is already rolled back. The survivor commits:
S1> COMMIT
OK
S2> COMMIT
OK
admin> SELECT * FROM Account
+--------+----------+
| acc_no | balance  |
+--------+----------+
|      1 |  9500.00 |
|      2 | 10500.00 |
+--------+----------+
2 rows in set
-- Only the survivor's two updates are visible (see its row changes above); the victim's changes are gone.

#### Task 6 - SHOW ENGINE INNODB STATUS - LATEST DETECTED DEADLOCK

2026-10-30 10:43:04 0x58f4
*** (1) TRANSACTION:
TRANSACTION 7229, ACTIVE 1 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1128, 2 row lock(s), undo log entries 1
MySQL thread id 792, OS thread handle 21200, query id 6226 localhost 127.0.0.1 root updating
UPDATE Account SET balance = balance + 500 WHERE acc_no = 2

*** (1) HOLDS THE LOCK(S):
RECORD LOCKS space id 239 page no 4 n bits 72 index PRIMARY of table `deadlock_5c`.`account` trx id 7229 lock_mode X locks rec but not gap


*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 239 page no 4 n bits 72 index PRIMARY of table `deadlock_5c`.`account` trx id 7229 lock_mode X locks rec but not gap waiting


*** (2) TRANSACTION:
TRANSACTION 7230, ACTIVE 1 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1128, 2 row lock(s), undo log entries 1
MySQL thread id 793, OS thread handle 18560, query id 6228 localhost 127.0.0.1 root updating
UPDATE Account SET balance = balance + 300 WHERE acc_no = 1

*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 239 page no 4 n bits 72 index PRIMARY of table `deadlock_5c`.`account` trx id 7230 lock_mode X locks rec but not gap


*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 239 page no 4 n bits 72 index PRIMARY of table `deadlock_5c`.`account` trx id 7230 lock_mode X locks rec but not gap waiting

*** WE ROLL BACK TRANSACTION (2)

=> Victim: transaction (2) was rolled back (see '*** WE ROLL BACK TRANSACTION' above)

#### Task 7 - Wait-for graph

wait-for edges: T1 -> T2, T2 -> T1
  cycle: T1 -> T2 -> T1  => DEADLOCK

#### Task 8 - Same lock order in both sessions (account 1 then 2): no deadlock

S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S1> UPDATE Account SET balance = balance - 500 WHERE acc_no = 1
OK, 1 row affected
S2> UPDATE Account SET balance = balance - 300 WHERE acc_no = 1
   [STILL RUNNING - blocked, waiting for a lock]
S1> UPDATE Account SET balance = balance + 500 WHERE acc_no = 2
OK, 1 row affected
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> UPDATE Account SET balance = balance + 300 WHERE acc_no = 2
OK, 1 row affected
S2> COMMIT
OK
admin> SELECT * FROM Account
+--------+----------+
| acc_no | balance  |
+--------+----------+
|      1 |  9200.00 |
|      2 | 10800.00 |
+--------+----------+
2 rows in set
-- Both transfers completed: 1 = 10000-500-300, 2 = 10000+500+300. S2 simply waited.

#### Task 9 - Procedure transfer_retry: retry once when error 1213 occurs

admin> CREATE PROCEDURE transfer_retry(IN f INT, IN t INT, IN amt DECIMAL(12,2), OUT attempts_used INT)
BEGIN
    DECLARE ok INT DEFAULT 0;
    SET attempts_used = 0;
    retry_loop: LOOP
        SET attempts_used = attempts_used + 1;
        BEGIN
            DECLARE EXIT HANDLER FOR 1213 BEGIN ROLLBACK; END;      -- 1213 = ER_LOCK_DEADLOCK: undo and fall out of this block
            START TRANSACTION;
            UPDATE Account SET balance = balance - amt WHERE acc_no = f;
            UPDATE Account SET balance = balance + amt WHERE acc_no = t;
            COMMIT;
            SET ok = 1;
        END;
        IF ok = 1 THEN
            LEAVE retry_loop;
        END IF;
        IF attempts_used >= 2 THEN                                   -- first try + ONE retry only
            SIGNAL SQLSTATE '40001' SET MESSAGE_TEXT = 'Transfer failed: deadlock persisted after one retry';
        END IF;
    END LOOP;
END
OK
-- S1 does heavier work (two updates) so InnoDB picks the lighter transaction - S2, running the procedure - as the victim.
S1> START TRANSACTION
OK
S1> UPDATE Account SET balance = balance - 100 WHERE acc_no = 2
OK, 1 row affected
S1> UPDATE Account SET balance = balance - 100 WHERE acc_no = 2
OK, 1 row affected
S2> CALL transfer_retry(1, 2, 100, @attempts)
   [STILL RUNNING - blocked, waiting for a lock]
-- The procedure holds row 1 and waits for row 2. S1 now asks for row 1 => deadlock, the procedure's transaction is the victim and retries:
S1> UPDATE Account SET balance = balance + 200 WHERE acc_no = 1
OK, 1 row affected
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK
S2> SELECT @attempts AS attempts_used
+---------------+
| attempts_used |
+---------------+
|             2 |
+---------------+
1 row in set
admin> SELECT * FROM Account
+--------+----------+
| acc_no | balance  |
+--------+----------+
|      1 | 10100.00 |
|      2 |  9900.00 |
+--------+----------+
2 rows in set
-- attempts_used = 2: first try deadlocked and was rolled back, the retry succeeded. 1 = 10000+200-100, 2 = 10000-200+100.

#### Task 10 - Deadlock with three accounts and three sessions

S1> START TRANSACTION
OK
S2> START TRANSACTION
OK
S3> START TRANSACTION
OK
S1> UPDATE Account SET balance = balance - 1 WHERE acc_no = 1
OK, 1 row affected
S1> UPDATE Account SET balance = balance - 1 WHERE acc_no = 1
OK, 1 row affected
S2> UPDATE Account SET balance = balance - 1 WHERE acc_no = 2
OK, 1 row affected
S2> UPDATE Account SET balance = balance - 1 WHERE acc_no = 2
OK, 1 row affected
S3> UPDATE Account SET balance = balance - 1 WHERE acc_no = 3
OK, 1 row affected
S1> UPDATE Account SET balance = balance + 1 WHERE acc_no = 2
   [STILL RUNNING - blocked, waiting for a lock]
S2> UPDATE Account SET balance = balance + 1 WHERE acc_no = 3
   [STILL RUNNING - blocked, waiting for a lock]
-- S3 closes the cycle T1 -> T2 -> T3 -> T1 (S3 has done the least work and becomes the victim):
S3> UPDATE Account SET balance = balance + 1 WHERE acc_no = 1
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
S3> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> COMMIT
OK
S1> (the blocked statement finishes)
OK, 1 row affected
S1> COMMIT
OK
wait-for edges: T1 -> T2, T2 -> T3, T3 -> T1
  cycle: T1 -> T2 -> T3 -> T1  => DEADLOCK

#### Task 11 - Wait-die and wound-wait with timestamps T1 < T2

Example: T1 (timestamp 1, older) and T2 (timestamp 2, younger). T1 holds lock on A, T2 holds lock on B.
Event 1: T1 requests B (held by T2).   Event 2: T2 requests A (held by T1).

WAIT-DIE   (non-preemptive: older waits, younger dies)
  Event 1: T1 is older -> T1 WAITS for T2
  Event 2: T2 is younger -> T2 DIES (aborts, restarts later with its ORIGINAL timestamp)
  Result: no cycle can ever form, because waiting is only allowed in one age direction.

WOUND-WAIT (preemptive: older wounds the younger holder, younger waits)
  Event 1: T1 is older -> T1 WOUNDS T2 (T2 is aborted and rolled back, T1 takes B)
  Event 2: T2 restarts with its ORIGINAL timestamp and now WAITS for T1
  Result: no cycle can ever form, because waiting is only allowed in one age direction.

Compare with InnoDB: it does not prevent deadlocks; it detects the cycle and aborts the cheapest transaction (victim).

#### Task 12 - Four ways to reduce deadlocks

Four ways to reduce deadlocks in an application:
 1. Lock rows in a consistent global order (e.g. always the lower account number first) - Task 8 shows no deadlock then.
 2. Keep transactions short and never wait for user input inside a transaction; commit as early as possible.
 3. Acquire all needed locks up front: SELECT ... WHERE acc_no IN (1,2) ORDER BY acc_no FOR UPDATE, then update.
 4. Use proper indexes so that statements lock only the rows they need (fewer gap/next-key locks), and prefer READ COMMITTED when gap locks are not needed.
 5. (bonus) Catch error 1213 and retry the whole transaction (Task 9).

(session scripts written)

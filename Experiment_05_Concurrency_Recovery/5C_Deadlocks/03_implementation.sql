-- Experiment 5C - Deadlock : 12 tasks as two/three-terminal scripts (replayed by run_demo.py).
/* @CONCEPTS
* **Deadlock**: a cycle of transactions each waiting for a lock held by the next. InnoDB detects the cycle immediately, rolls back ONE transaction (the victim, usually the one that did less work) and returns **ERROR 1213 (40001) Deadlock found when trying to get lock; try restarting transaction**. The other transaction continues.
* **Wait-for graph**: node per transaction, edge Ti -> Tj when Ti waits for a lock held by Tj. A cycle = deadlock.
* **Prevention by ordering**: if every transaction locks rows in the same order (account 1 then 2) no cycle can form.
* **Timestamp schemes** (T1 older than T2): *wait-die* (non-preemptive): an older requester waits, a younger requester dies (aborts/restarts). *wound-wait* (preemptive): an older requester wounds (aborts) the younger holder, a younger requester waits.
* Application rule: catch 1213 and **retry the whole transaction**.
*/

-- ### TASK 1: Create Account and insert the data; open two sessions
-- S1> START TRANSACTION;  (and likewise in S2)

-- ### TASK 2: S1 debits account 1
-- S1> START TRANSACTION; UPDATE Account SET balance = balance - 500 WHERE acc_no = 1;     -- S1 holds the X lock on row 1

-- ### TASK 3: S2 debits account 2
-- S2> START TRANSACTION; UPDATE Account SET balance = balance - 300 WHERE acc_no = 2;     -- S2 holds the X lock on row 2

-- ### TASK 4: S1 updates account 2 and S2 updates account 1 - capture the deadlock error
-- S1> UPDATE Account SET balance = balance + 500 WHERE acc_no = 2;      -- waits for S2
-- S2> UPDATE Account SET balance = balance + 300 WHERE acc_no = 1;      -- waits for S1 => cycle => ERROR 1213 for the victim

-- ### TASK 5: Which transaction was rolled back, which committed; final balances
-- The victim lost all its changes; the survivor can COMMIT. Final balances show only the survivor's transfer.

-- ### TASK 6: SHOW ENGINE INNODB STATUS - identify the victim in LATEST DETECTED DEADLOCK
-- The section lists both transactions, the locks they hold / wait for, and ends with "*** WE ROLL BACK TRANSACTION (n)".

-- ### TASK 7: Wait-for graph of the deadlock
-- T1 -> T2 (T1 waits for row 2 held by T2) and T2 -> T1 : a cycle. Printed by run_demo.py.

-- ### TASK 8: Both sessions lock rows in the same order (account 1 then 2): no deadlock
-- S2 simply waits for S1 on row 1; when S1 commits, S2 continues.

-- ### TASK 9: Procedure that retries a transfer once on deadlock (error 1213)
-- The retry loop wraps the transaction in a BEGIN...END block with an EXIT HANDLER FOR 1213 that rolls back and counts the attempt.
-- delimiter $$  CREATE PROCEDURE transfer_retry(IN f INT, IN t INT, IN amt DECIMAL(12,2)) ...  $$  (full text in run_demo.py / 05_expected_output.md)

-- ### TASK 10: Deadlock with three accounts and three sessions
-- S1 locks 1 and wants 2; S2 locks 2 and wants 3; S3 locks 3 and wants 1 => T1 -> T2 -> T3 -> T1.

-- ### TASK 11: Wait-die and wound-wait with timestamps T1 < T2
-- Printed by run_demo.py for the example "T1 holds A, T2 holds B; T1 requests B, then T2 requests A".

-- ### TASK 12: Four ways to reduce deadlocks in an application
-- (1) acquire locks in a consistent global order, (2) keep transactions short and do not wait for the user inside a transaction, (3) lock what you need up front (SELECT ... FOR UPDATE ORDER BY pk), (4) use good indexes so fewer rows are locked, (5) catch 1213 and retry.

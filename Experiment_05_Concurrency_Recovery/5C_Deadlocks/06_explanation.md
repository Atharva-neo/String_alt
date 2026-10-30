# Explanation - 5C Deadlocks

## ER / structure diagram

```mermaid
flowchart LR
    T1["T1: holds row 1"] -- "waits for row 2" --> T2["T2: holds row 2"]
    T2 -- "waits for row 1" --> T1
```

## Concepts used

* **Deadlock**: a cycle of transactions each waiting for a lock held by the next. InnoDB detects the cycle immediately, rolls back ONE transaction (the victim, usually the one that did less work) and returns **ERROR 1213 (40001) Deadlock found when trying to get lock; try restarting transaction**. The other transaction continues.
* **Wait-for graph**: node per transaction, edge Ti -> Tj when Ti waits for a lock held by Tj. A cycle = deadlock.
* **Prevention by ordering**: if every transaction locks rows in the same order (account 1 then 2) no cycle can form.
* **Timestamp schemes** (T1 older than T2): *wait-die* (non-preemptive): an older requester waits, a younger requester dies (aborts/restarts). *wound-wait* (preemptive): an older requester wounds (aborts) the younger holder, a younger requester waits.
* Application rule: catch 1213 and **retry the whole transaction**.

## Task-by-task logic


### Core tasks (from the PDF)

**Task 1 - Create Account and insert the data; open two sessions**  


**Task 2 - S1 debits account 1**  


**Task 3 - S2 debits account 2**  


**Task 4 - S1 updates account 2 and S2 updates account 1 - capture the deadlock error**  


**Task 5 - Which transaction was rolled back, which committed; final balances**  
The victim lost all its changes; the survivor can COMMIT. Final balances show only the survivor's transfer.

**Task 6 - SHOW ENGINE INNODB STATUS - identify the victim in LATEST DETECTED DEADLOCK**  
The section lists both transactions, the locks they hold / wait for, and ends with "*** WE ROLL BACK TRANSACTION (n)".

**Task 7 - Wait-for graph of the deadlock**  
T1 -> T2 (T1 waits for row 2 held by T2) and T2 -> T1 : a cycle. Printed by run_demo.py.

**Task 8 - Both sessions lock rows in the same order (account 1 then 2): no deadlock**  
S2 simply waits for S1 on row 1; when S1 commits, S2 continues.

**Task 9 - Procedure that retries a transfer once on deadlock (error 1213)**  
The retry loop wraps the transaction in a BEGIN...END block with an EXIT HANDLER FOR 1213 that rolls back and counts the attempt. delimiter $$  CREATE PROCEDURE transfer_retry(IN f INT, IN t INT, IN amt DECIMAL(12,2)) ...  $$  (full text in run_demo.py / 05_expected_output.md)

**Task 10 - Deadlock with three accounts and three sessions**  
S1 locks 1 and wants 2; S2 locks 2 and wants 3; S3 locks 3 and wants 1 => T1 -> T2 -> T3 -> T1.

**Task 11 - Wait-die and wound-wait with timestamps T1 < T2**  
Printed by run_demo.py for the example "T1 holds A, T2 holds B; T1 requests B, then T2 requests A".

**Task 12 - Four ways to reduce deadlocks in an application**  
(1) acquire locks in a consistent global order, (2) keep transactions short and do not wait for the user inside a transaction, (3) lock what you need up front (SELECT ... FOR UPDATE ORDER BY pk), (4) use good indexes so fewer rows are locked, (5) catch 1213 and retry.


### Advanced / examiner-style queries

**Adv 1 - Where do I see the latest deadlock without SHOW ENGINE INNODB STATUS?**  
Enable logging of every deadlock to the error log:  SET GLOBAL innodb_print_all_deadlocks = ON;

**Adv 2 - Turn deadlock detection off (and rely on timeouts)**  
SET GLOBAL innodb_deadlock_detect = OFF;  -- then a deadlock only ends with ERROR 1205 after innodb_lock_wait_timeout; used on extremely hot rows

**Adv 3 - Which statements block whom right now?**  
SELECT * FROM sys.innodb_lock_waits\G SELECT * FROM performance_schema.data_lock_waits;

**Adv 4 - Deadlock caused by a gap lock (not only by row locks)**  


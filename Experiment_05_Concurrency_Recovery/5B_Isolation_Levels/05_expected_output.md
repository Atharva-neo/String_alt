# Expected output - Experiment_05_Concurrency_Recovery / 5B_Isolation_Levels

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Multi-session demonstration (`run_demo.py`, real connections)

> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.

### Task 1 - Seats table and two sessions

admin> SELECT * FROM Seats
+---------+--------+
| seat_no | status |
+---------+--------+
| A1      | Free   |
| A2      | Free   |
| A3      | Booked |
+---------+--------+
3 rows in set

#### Task 2 - Isolation level of the session

S1> SELECT @@transaction_isolation AS isolation
+-----------------+
| isolation       |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set

#### Task 3 - Dirty read: S2 under READ UNCOMMITTED reads S1's uncommitted booking of A1

S2> SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
OK
S1> START TRANSACTION
OK
S1> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1'
OK, 1 row affected
S2> START TRANSACTION
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'
+---------+--------+
| seat_no | status |
+---------+--------+
| A1      | Booked |
+---------+--------+
1 row in set
-- S2 sees 'Booked' - data S1 has NOT committed (dirty read). Now S1 rolls back:
S1> ROLLBACK
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'
+---------+--------+
| seat_no | status |
+---------+--------+
| A1      | Free   |
+---------+--------+
1 row in set
-- The 'Booked' S2 saw never existed.
S2> COMMIT
OK

#### Task 4 - Same experiment under READ COMMITTED: no dirty read

S2> SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
OK
S1> START TRANSACTION
OK
S1> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1'
OK, 1 row affected
S2> START TRANSACTION
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'
+---------+--------+
| seat_no | status |
+---------+--------+
| A1      | Free   |
+---------+--------+
1 row in set
-- S2 still sees 'Free' - only committed data is visible.
S1> ROLLBACK
OK
S2> COMMIT
OK

#### Task 5 - Non-repeatable read under READ COMMITTED

S2> SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
OK
S2> START TRANSACTION
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'
+---------+--------+
| seat_no | status |
+---------+--------+
| A2      | Free   |
+---------+--------+
1 row in set
S1> START TRANSACTION
OK
S1> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'
OK, 1 row affected
S1> COMMIT
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'
+---------+--------+
| seat_no | status |
+---------+--------+
| A2      | Booked |
+---------+--------+
1 row in set
-- Same query, same transaction, different answer: NON-REPEATABLE READ.
S2> COMMIT
OK

#### Task 6 - Non-repeatable read under REPEATABLE READ: prevented

S2> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S2> START TRANSACTION
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'
+---------+--------+
| seat_no | status |
+---------+--------+
| A2      | Free   |
+---------+--------+
1 row in set
S1> START TRANSACTION
OK
S1> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'
OK, 1 row affected
S1> COMMIT
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'
+---------+--------+
| seat_no | status |
+---------+--------+
| A2      | Free   |
+---------+--------+
1 row in set
-- S2 keeps seeing its snapshot ('Free'). After S2 ends its transaction it sees the new value:
S2> COMMIT
OK
S2> SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'
+---------+--------+
| seat_no | status |
+---------+--------+
| A2      | Booked |
+---------+--------+
1 row in set
S2> COMMIT
OK

#### Task 7 - Phantom: S2 counts free seats twice while S1 inserts A4 - REPEATABLE READ

S2> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S2> START TRANSACTION
OK
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          2 |
+------------+
1 row in set
S1> START TRANSACTION
OK
S1> INSERT INTO Seats VALUES ('A4', 'Free')
OK, 1 row affected
S1> COMMIT
OK
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          2 |
+------------+
1 row in set
-- A plain SELECT still shows 2: InnoDB's REPEATABLE READ snapshot hides the phantom. A LOCKING read reads the latest committed data and exposes it:
S2> SELECT COUNT(*) AS free_seats_locking_read FROM Seats WHERE status = 'Free' FOR UPDATE
+-------------------------+
| free_seats_locking_read |
+-------------------------+
|                       3 |
+-------------------------+
1 row in set
S2> COMMIT
OK
-- For comparison under READ COMMITTED even the plain count shows the phantom:
S2> SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
OK
S2> START TRANSACTION
OK
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          2 |
+------------+
1 row in set
S1> START TRANSACTION
OK
S1> INSERT INTO Seats VALUES ('A4', 'Free')
OK, 1 row affected
S1> COMMIT
OK
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          3 |
+------------+
1 row in set
S2> COMMIT
OK

#### Task 8 - Phantom attempt under SERIALIZABLE: S1's INSERT is blocked

S2> SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE
OK
S2> START TRANSACTION
OK
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          2 |
+------------+
1 row in set
S1> START TRANSACTION
OK
S1> INSERT INTO Seats VALUES ('A4', 'Free')
   [STILL RUNNING - blocked, waiting for a lock]
S2> SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'
+------------+
| free_seats |
+------------+
|          2 |
+------------+
1 row in set
-- S2 still sees 2 and S1 is still waiting. Once S2 commits, S1's insert goes through:
S2> COMMIT
OK
S1> (the blocked statement finishes)
OK, 1 row affected
S1> COMMIT
OK

#### Task 9 - Two users book A2 at once - SELECT ... FOR UPDATE prevents double booking

S1> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S2> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S1> START TRANSACTION
OK
S1> SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE
+--------+
| status |
+--------+
| Free   |
+--------+
1 row in set
S2> START TRANSACTION
OK
S2> SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE
   [STILL RUNNING - blocked, waiting for a lock]
S1> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'
OK, 1 row affected
S1> COMMIT
OK
S2> (the blocked statement finishes)
+--------+
| status |
+--------+
| Booked |
+--------+
1 row in set
-- S2 now sees 'Booked': the application tells user 2 that the seat is taken. Nothing is double booked.
S2> ROLLBACK
OK
-- Alternative without a separate SELECT: a conditional UPDATE and a check of the affected rows:
S2> UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2' AND status = 'Free'
OK, 0 rows affected
S2> ROLLBACK
OK

#### Task 10 - SET SESSION versus SET GLOBAL

S1> SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
OK
S2> SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK
S1> SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level
+----------------+-----------------+
| session_level  | global_level    |
+----------------+-----------------+
| READ-COMMITTED | REPEATABLE-READ |
+----------------+-----------------+
1 row in set
-- SET GLOBAL (the demo restores it at the end):
admin> SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED
OK
S2> SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level
+-----------------+----------------+
| session_level   | global_level   |
+-----------------+----------------+
| REPEATABLE-READ | READ-COMMITTED |
+-----------------+----------------+
1 row in set
S3> SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level
+----------------+----------------+
| session_level  | global_level   |
+----------------+----------------+
| READ-COMMITTED | READ-COMMITTED |
+----------------+----------------+
1 row in set
-- S2 (opened before) keeps its own level; the NEW session S3 inherited the new global level.
admin> SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ
OK

#### Task 11 - Isolation level x anomaly - measured with real sessions

| Isolation level | Dirty read | Non-repeatable read | Phantom read |
|---|---|---|---|
| READ UNCOMMITTED | **occurred** | **occurred** | **occurred** |
| READ COMMITTED | prevented | **occurred** | **occurred** |
| REPEATABLE READ | prevented | prevented | prevented for plain reads; **visible with FOR UPDATE** |
| SERIALIZABLE | prevented (reader blocked) | prevented (writer blocked) | prevented (insert blocked) |

#### Task 12 - Recommendation for a seat-booking system

Recommendation for a seat-booking system: keep InnoDB's default REPEATABLE READ (or READ COMMITTED) and protect the booking step itself with a row lock:
  START TRANSACTION; SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE; -- refuse if not 'Free'; UPDATE ...; COMMIT;
Why: (1) READ UNCOMMITTED is never acceptable - users would be shown seats that are never really booked (dirty read).
(2) The dangerous anomaly in booking is the check-then-act race (two users see 'Free' and both book); isolation levels below SERIALIZABLE do not stop it,
    but FOR UPDATE (or the conditional UPDATE ... WHERE status='Free' + ROW_COUNT()) does, with row-level locking only on the seat being bought.
(3) SERIALIZABLE would also work but turns every read into a locking read, gap locks block unrelated inserts and deadlocks become frequent => poor throughput.
(4) REPEATABLE READ gives a stable view while one customer looks at the seat map; READ COMMITTED gives a fresher view and fewer gap locks - both are fine with FOR UPDATE.

(session scripts written)

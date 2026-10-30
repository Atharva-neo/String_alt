# Expected output - Experiment_04_Triggers_Procedures_ACID / 4D_Ticket_Booking

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Show_Seats and Booking and insert the data

```sql
SELECT * FROM Show_Seats;
SELECT COUNT(*) AS bookings FROM Booking;
```

**Output**

```text
SELECT * FROM Show_Seats

+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         3 |
|       2 | Movie B | 21:00:00  |        50 |
+---------+---------+-----------+-----------+
2 rows in set

SELECT COUNT(*) AS bookings FROM Booking

+----------+
| bookings |
+----------+
|        0 |
+----------+
1 row in set
```

### Task 2 - AFTER INSERT trigger on Booking that reduces available by seats

```sql
DELIMITER $$
CREATE TRIGGER trg_booking_reserve AFTER INSERT ON Booking FOR EACH ROW
BEGIN
    UPDATE Show_Seats SET available = available - NEW.seats WHERE show_id = NEW.show_id;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d';
```

**Output**

```text
CREATE TRIGGER trg_booking_reserve AFTER INSERT ON Booking FOR EACH ROW
BEGIN
    UPDATE Show_Seats SET available = available - NEW.seats WHERE show_id = NEW.show_id;
END

Query OK, 0 rows affected

SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d'

+---------------------+---------------+--------------------+
| TRIGGER_NAME        | ACTION_TIMING | EVENT_MANIPULATION |
+---------------------+---------------+--------------------+
| trg_booking_reserve | AFTER         | INSERT             |
+---------------------+---------------+--------------------+
1 row in set
```

### Task 3 - AFTER UPDATE trigger that restores seats when status changes to 'Cancelled'

```sql
DELIMITER $$
CREATE TRIGGER trg_booking_cancel AFTER UPDATE ON Booking FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        UPDATE Show_Seats SET available = available + OLD.seats WHERE show_id = OLD.show_id;
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name;
```

**Output**

```text
CREATE TRIGGER trg_booking_cancel AFTER UPDATE ON Booking FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        UPDATE Show_Seats SET available = available + OLD.seats WHERE show_id = OLD.show_id;
    END IF;
END

Query OK, 0 rows affected

SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name

+---------------------+---------------+--------------------+
| TRIGGER_NAME        | ACTION_TIMING | EVENT_MANIPULATION |
+---------------------+---------------+--------------------+
| trg_booking_cancel  | AFTER         | UPDATE             |
| trg_booking_reserve | AFTER         | INSERT             |
+---------------------+---------------+--------------------+
2 rows in set
```

**Why this output is correct:** The condition OLD.status <> 'Cancelled' prevents restoring the same seats twice.

### Task 4 - BEFORE INSERT trigger that blocks booking when seats > available

```sql
DELIMITER $$
CREATE TRIGGER trg_booking_guard BEFORE INSERT ON Booking FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Show_Seats WHERE show_id = NEW.show_id;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Show not found';
    END IF;
    IF NEW.seats > v_avail THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available';
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name;
```

**Output**

```text
CREATE TRIGGER trg_booking_guard BEFORE INSERT ON Booking FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Show_Seats WHERE show_id = NEW.show_id;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Show not found';
    END IF;
    IF NEW.seats > v_avail THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available';
    END IF;
END

Query OK, 0 rows affected

SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name

+---------------------+---------------+--------------------+
| TRIGGER_NAME        | ACTION_TIMING | EVENT_MANIPULATION |
+---------------------+---------------+--------------------+
| trg_booking_cancel  | AFTER         | UPDATE             |
| trg_booking_guard   | BEFORE        | INSERT             |
| trg_booking_reserve | AFTER         | INSERT             |
+---------------------+---------------+--------------------+
3 rows in set
```

**Why this output is correct:** The guard reads the current availability; if the request is bigger it SIGNALs and the INSERT never happens.

### Task 5 - Book 2 seats for show 1, then try 2 more - error

```sql
INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Aarav', 2);
SELECT * FROM Show_Seats WHERE show_id = 1;
INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Bhumi', 2);
SELECT booking_id, customer, seats, status FROM Booking;
SELECT * FROM Show_Seats WHERE show_id = 1;
```

**Output**

```text
INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Aarav', 2)

Query OK, 1 row affected

SELECT * FROM Show_Seats WHERE show_id = 1

+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         1 |
+---------+---------+-----------+-----------+
1 row in set

INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Bhumi', 2)

ERROR 1644 (45000) at line 3: Not enough seats available
SELECT booking_id, customer, seats, status FROM Booking

+------------+----------+-------+--------+
| booking_id | customer | seats | status |
+------------+----------+-------+--------+
|          1 | Aarav    |     2 | Booked |
+------------+----------+-------+--------+
1 row in set

SELECT * FROM Show_Seats WHERE show_id = 1

+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         1 |
+---------+---------+-----------+-----------+
1 row in set
```

**Why this output is correct:** Show 1 has 3 seats. After the first booking 1 seat is left, so a request for 2 is rejected by trg_booking_guard.

### Task 6 - Cancel the first booking and show seats restored

```sql
UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1;
SELECT booking_id, customer, seats, status FROM Booking;
SELECT * FROM Show_Seats WHERE show_id = 1;
```

**Output**

```text
UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT booking_id, customer, seats, status FROM Booking

+------------+----------+-------+-----------+
| booking_id | customer | seats | status    |
+------------+----------+-------+-----------+
|          1 | Aarav    |     2 | Cancelled |
+------------+----------+-------+-----------+
1 row in set

SELECT * FROM Show_Seats WHERE show_id = 1

+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         3 |
+---------+---------+-----------+-----------+
1 row in set
```

**Why this output is correct:** Changing status to 'Cancelled' fires trg_booking_cancel: available 1 -> 3.

### Task 7 - Procedure book_ticket(show, cust, n) as a transaction

```sql
DELIMITER $$
CREATE PROCEDURE book_ticket(IN p_show INT, IN p_cust VARCHAR(30), IN p_n INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO Booking (show_id, customer, seats) VALUES (p_show, p_cust, p_n);
    COMMIT;
END$$
DELIMITER ;
CALL book_ticket(2, 'Meera', 4);
SELECT * FROM Show_Seats;
CALL book_ticket(1, 'Zoya', 9);
SELECT booking_id, show_id, customer, seats, status FROM Booking;
```

**Output**

```text
CREATE PROCEDURE book_ticket(IN p_show INT, IN p_cust VARCHAR(30), IN p_n INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO Booking (show_id, customer, seats) VALUES (p_show, p_cust, p_n);
    COMMIT;
END

Query OK, 0 rows affected

CALL book_ticket(2, 'Meera', 4)

Query OK, 0 rows affected

SELECT * FROM Show_Seats

+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         3 |
|       2 | Movie B | 21:00:00  |        46 |
+---------+---------+-----------+-----------+
2 rows in set

CALL book_ticket(1, 'Zoya', 9)

ERROR 1644 (45000) at line 16: Not enough seats available
SELECT booking_id, show_id, customer, seats, status FROM Booking

+------------+---------+----------+-------+-----------+
| booking_id | show_id | customer | seats | status    |
+------------+---------+----------+-------+-----------+
|          1 |       1 | Aarav    |     2 | Cancelled |
|          2 |       2 | Meera    |     4 | Booked    |
+------------+---------+----------+-------+-----------+
2 rows in set
```

**Why this output is correct:** START TRANSACTION, INSERT (the triggers reserve the seats), COMMIT. Any error (guard trigger, unknown show, CHECK) triggers the handler: ROLLBACK + RESIGNAL.

### Task 8 - Function revenue(show_id) at 200 per seat

```sql
DELIMITER $$
CREATE FUNCTION revenue(p_show INT) RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
    DECLARE v_seats INT;
    SELECT COALESCE(SUM(seats), 0) INTO v_seats FROM Booking WHERE show_id = p_show AND status = 'Booked';
    RETURN v_seats * 200;
END$$
DELIMITER ;
SELECT show_id, movie, revenue(show_id) AS revenue FROM Show_Seats;
```

**Output**

```text
CREATE FUNCTION revenue(p_show INT) RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
    DECLARE v_seats INT;
    SELECT COALESCE(SUM(seats), 0) INTO v_seats FROM Booking WHERE show_id = p_show AND status = 'Booked';
    RETURN v_seats * 200;
END

Query OK, 0 rows affected

SELECT show_id, movie, revenue(show_id) AS revenue FROM Show_Seats

+---------+---------+---------+
| show_id | movie   | revenue |
+---------+---------+---------+
|       1 | Movie A |    0.00 |
|       2 | Movie B |  800.00 |
+---------+---------+---------+
2 rows in set
```

**Why this output is correct:** Only 'Booked' rows count, cancelled bookings earn nothing. Show 2: 4 seats x 200 = 800; show 1: 0 (its only booking was cancelled).

### Task 9 - Procedure show_report() printing seats booked and available per show using a cursor

```sql
DELIMITER $$
CREATE PROCEDURE show_report()
BEGIN
    DECLARE v_show INT;
    DECLARE v_movie VARCHAR(30);
    DECLARE v_avail INT;
    DECLARE v_booked INT;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT show_id, movie, available FROM Show_Seats ORDER BY show_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    rep: LOOP
        FETCH cur INTO v_show, v_movie, v_avail;
        IF done = 1 THEN
            LEAVE rep;
        END IF;
        SELECT COALESCE(SUM(seats), 0) INTO v_booked FROM Booking WHERE show_id = v_show AND status = 'Booked';
        SELECT CONCAT('Show ', v_show, ' (', v_movie, '): booked ', v_booked, ', available ', v_avail) AS report;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
CALL show_report();
```

**Output**

```text
CREATE PROCEDURE show_report()
BEGIN
    DECLARE v_show INT;
    DECLARE v_movie VARCHAR(30);
    DECLARE v_avail INT;
    DECLARE v_booked INT;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT show_id, movie, available FROM Show_Seats ORDER BY show_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    rep: LOOP
        FETCH cur INTO v_show, v_movie, v_avail;
        IF done = 1 THEN
            LEAVE rep;
        END IF;
        SELECT COALESCE(SUM(seats), 0) INTO v_booked FROM Booking WHERE show_id = v_show AND status = 'Booked';
        SELECT CONCAT('Show ', v_show, ' (', v_movie, '): booked ', v_booked, ', available ', v_avail) AS report;
    END LOOP;
    CLOSE cur;
END

Query OK, 0 rows affected

CALL show_report()

+-----------------------------------------+
| report                                  |
+-----------------------------------------+
| Show 1 (Movie A): booked 0, available 3 |
+-----------------------------------------+
1 row in set

+------------------------------------------+
| report                                   |
+------------------------------------------+
| Show 2 (Movie B): booked 4, available 46 |
+------------------------------------------+
1 row in set

Query OK, 0 rows affected
```

### Task 10 - Two bookings in one transaction with a SAVEPOINT between; roll back the second

```sql
START TRANSACTION;
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 2);
SAVEPOINT after_first;
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 3);
SELECT customer, seats FROM Booking WHERE customer = 'Rohan';
SELECT available FROM Show_Seats WHERE show_id = 2;
ROLLBACK TO SAVEPOINT after_first;
COMMIT;
SELECT customer, seats FROM Booking WHERE customer = 'Rohan';
SELECT available FROM Show_Seats WHERE show_id = 2;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 2)

Query OK, 1 row affected

SAVEPOINT after_first

Query OK, 0 rows affected

INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 3)

Query OK, 1 row affected

SELECT customer, seats FROM Booking WHERE customer = 'Rohan'

+----------+-------+
| customer | seats |
+----------+-------+
| Rohan    |     2 |
| Rohan    |     3 |
+----------+-------+
2 rows in set

SELECT available FROM Show_Seats WHERE show_id = 2

+-----------+
| available |
+-----------+
|        41 |
+-----------+
1 row in set

ROLLBACK TO SAVEPOINT after_first

Query OK, 0 rows affected

COMMIT

Query OK, 0 rows affected

SELECT customer, seats FROM Booking WHERE customer = 'Rohan'

+----------+-------+
| customer | seats |
+----------+-------+
| Rohan    |     2 |
+----------+-------+
1 row in set

SELECT available FROM Show_Seats WHERE show_id = 2

+-----------+
| available |
+-----------+
|        44 |
+-----------+
1 row in set
```

**Why this output is correct:** Both inserts reduce seats of show 2 (46 -> 44 -> 41); ROLLBACK TO SAVEPOINT undoes only the second one (and its seat reduction made by the trigger).

### Task 11 - Transaction with two bookings, kill the session before COMMIT, reconnect - nothing saved (atomicity)

```sql
SELECT 'see run_demo.py: Task 11' AS note;
```

**Output**

```text
SELECT 'see run_demo.py: Task 11' AS note

+--------------------------+
| note                     |
+--------------------------+
| see run_demo.py: Task 11 |
+--------------------------+
1 row in set
```

**Why this output is correct:** A killed/disconnected session is rolled back by the server. This needs two connections, so it is done by run_demo.py (see the multi-session section below).

### Task 12 - How each ACID property was demonstrated (evidence queries)

```sql
SELECT s.show_id, s.movie, s.available, COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS booked,
       s.available + COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS capacity_check
FROM Show_Seats s LEFT JOIN Booking b ON b.show_id = s.show_id GROUP BY s.show_id, s.movie, s.available;
SELECT 'Atomicity' AS property, 'Tasks 5, 10, 11 - failed / rolled back bookings leave no trace' AS demonstrated_by UNION ALL
SELECT 'Consistency', 'CHECK + guard trigger; available + booked = capacity (query above)' UNION ALL
SELECT 'Isolation', 'Task 11: other connection sees no uncommitted rows; 4A Task 10 lock wait' UNION ALL
SELECT 'Durability', 'Committed bookings persist after restart (4A DURABILITY.md)';
```

**Output**

```text
SELECT s.show_id, s.movie, s.available, COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS booked,
       s.available + COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS capacity_check
FROM Show_Seats s LEFT JOIN Booking b ON b.show_id = s.show_id GROUP BY s.show_id, s.movie, s.available

+---------+---------+-----------+--------+----------------+
| show_id | movie   | available | booked | capacity_check |
+---------+---------+-----------+--------+----------------+
|       1 | Movie A |         3 |      0 |              3 |
|       2 | Movie B |        44 |      6 |             50 |
+---------+---------+-----------+--------+----------------+
2 rows in set

SELECT 'Atomicity' AS property, 'Tasks 5, 10, 11 - failed / rolled back bookings leave no trace' AS demonstrated_by UNION ALL
SELECT 'Consistency', 'CHECK + guard trigger; available + booked = capacity (query above)' UNION ALL
SELECT 'Isolation', 'Task 11: other connection sees no uncommitted rows; 4A Task 10 lock wait' UNION ALL
SELECT 'Durability', 'Committed bookings persist after restart (4A DURABILITY.md)'

+-------------+--------------------------------------------------------------------------+
| property    | demonstrated_by                                                          |
+-------------+--------------------------------------------------------------------------+
| Atomicity   | Tasks 5, 10, 11 - failed / rolled back bookings leave no trace           |
| Consistency | CHECK + guard trigger; available + booked = capacity (query above)       |
| Isolation   | Task 11: other connection sees no uncommitted rows; 4A Task 10 lock wait |
| Durability  | Committed bookings persist after restart (4A DURABILITY.md)              |
+-------------+--------------------------------------------------------------------------+
4 rows in set
```

**Why this output is correct:** A: Task 5 failed booking left no row, Task 10 savepoint rollback, Task 11 killed session.  C: CHECK(available>=0) + guard trigger => the invariant below holds. I: Task 11 second connection saw nothing of the uncommitted bookings (and 4A Task 10).  D: committed rows survive a restart (4A DURABILITY.md). Invariant check: available + booked seats must equal the original capacity (3 and 50) for every show.


## Advanced / examiner-style queries

### Adv 1 - Cancel an already cancelled booking - seats are NOT restored twice

```sql
START TRANSACTION;
SELECT available FROM Show_Seats WHERE show_id = 1;
UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1;
SELECT available FROM Show_Seats WHERE show_id = 1;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

SELECT available FROM Show_Seats WHERE show_id = 1

+-----------+
| available |
+-----------+
|         3 |
+-----------+
1 row in set

UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1

Query OK, 0 rows affected
Rows matched: 1  Changed: 0  Warnings: 0

SELECT available FROM Show_Seats WHERE show_id = 1

+-----------+
| available |
+-----------+
|         3 |
+-----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 2 - Book exactly the remaining seats, then one more

```sql
START TRANSACTION;
CALL book_ticket(1, 'Last', 3);
SELECT available FROM Show_Seats WHERE show_id = 1;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

CALL book_ticket(1, 'Last', 3)

Query OK, 0 rows affected

SELECT available FROM Show_Seats WHERE show_id = 1

+-----------+
| available |
+-----------+
|         0 |
+-----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 3 - Zero or negative seats

```sql
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Bad', 0);
```

**Output**

```text
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Bad', 0)

ERROR 3819 (HY000) at line 1: Check constraint 'chk_booking_seats' is violated.
```

**Why this output is correct:** Error 3819 (chk_booking_seats) - the CHECK fires after the BEFORE trigger.

### Adv 4 - Invalid status value

```sql
UPDATE Booking SET status = 'Pending' WHERE booking_id = 1;
```

**Output**

```text
UPDATE Booking SET status = 'Pending' WHERE booking_id = 1

ERROR 3819 (HY000) at line 1: Check constraint 'chk_booking_status' is violated.
```

**Why this output is correct:** Error 3819 (chk_booking_status).

### Adv 5 - Revenue of all shows combined

```sql
SELECT SUM(revenue(show_id)) AS total_revenue FROM Show_Seats;
```

**Output**

```text
SELECT SUM(revenue(show_id)) AS total_revenue FROM Show_Seats

+---------------+
| total_revenue |
+---------------+
|       1800.00 |
+---------------+
1 row in set
```

### Adv 6 - Booking for an unknown show

```sql
INSERT INTO Booking (show_id, customer, seats) VALUES (9, 'Ghost', 1);
```

**Output**

```text
INSERT INTO Booking (show_id, customer, seats) VALUES (9, 'Ghost', 1)

ERROR 1644 (45000) at line 1: Show not found
```

**Why this output is correct:** The FK / guard trigger refuses it (error 1644 'Show not found' from the guard).


## Multi-session demonstration (`run_demo.py`, real connections)

> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.

admin> CREATE TRIGGER trg_booking_reserve AFTER INSERT ON Booking FOR EACH ROW
BEGIN UPDATE Show_Seats SET available = available - NEW.seats WHERE show_id = NEW.show_id; END
OK
admin> CREATE TRIGGER trg_booking_guard BEFORE INSERT ON Booking FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Show_Seats WHERE show_id = NEW.show_id;
    IF NEW.seats > v_avail THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available'; END IF;
END
OK

#### Task 11 - Kill the session before COMMIT (atomicity)

S2> SELECT * FROM Show_Seats
+---------+---------+-----------+-----------+
| show_id | movie   | show_time | available |
+---------+---------+-----------+-----------+
|       1 | Movie A | 18:00:00  |         3 |
|       2 | Movie B | 21:00:00  |        50 |
+---------+---------+-----------+-----------+
2 rows in set
S1> START TRANSACTION
OK
S1> INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 3)
OK, 1 row affected
S1> INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 2)
OK, 1 row affected
S1> SELECT customer, seats FROM Booking
+----------+-------+
| customer | seats |
+----------+-------+
| Neel     |     3 |
| Neel     |     2 |
+----------+-------+
2 rows in set
S1> SELECT show_id, available FROM Show_Seats WHERE show_id = 2
+---------+-----------+
| show_id | available |
+---------+-----------+
|       2 |        45 |
+---------+-----------+
1 row in set
-- S2 (another connection) cannot see the uncommitted rows (isolation):
S2> SELECT COUNT(*) AS visible_bookings FROM Booking
+------------------+
| visible_bookings |
+------------------+
|                0 |
+------------------+
1 row in set
S2> SELECT show_id, available FROM Show_Seats WHERE show_id = 2
+---------+-----------+
| show_id | available |
+---------+-----------+
|       2 |        50 |
+---------+-----------+
1 row in set
admin> KILL 702;   -- connection S1 is terminated without COMMIT (crash simulation)
OK
-- Reconnect as a brand new session S3 and look at the data: the server rolled the dead transaction back.
S3> SELECT COUNT(*) AS bookings FROM Booking
+----------+
| bookings |
+----------+
|        0 |
+----------+
1 row in set
S3> SELECT show_id, available FROM Show_Seats WHERE show_id = 2
+---------+-----------+
| show_id | available |
+---------+-----------+
|       2 |        50 |
+---------+-----------+
1 row in set
-- Seats are untouched: 50 available - the transaction was atomic (all or nothing).

(session scripts written)

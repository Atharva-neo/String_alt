# Expected output - Experiment_04_Triggers_Procedures_ACID / 4C_Library_Fines

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Book and Issue and insert the data

```sql
SELECT * FROM Book;
SELECT * FROM Issue;
```

**Output**

```text
SELECT * FROM Book

+---------+-------+-----------+
| book_id | title | available |
+---------+-------+-----------+
| B1      | DBMS  |         2 |
| B2      | ML    |         1 |
| B3      | DAA   |         0 |
+---------+-------+-----------+
3 rows in set

SELECT * FROM Issue

+----------+---------+--------+------------+------------+-------------+------+
| issue_id | book_id | member | issue_date | due_date   | return_date | fine |
+----------+---------+--------+------------+------------+-------------+------+
|        1 | B1      | Riya   | 2026-10-01 | 2026-10-15 | NULL        |    0 |
|        2 | B2      | Amit   | 2026-10-05 | 2026-10-19 | NULL        |    0 |
+----------+---------+--------+------------+------------+-------------+------+
2 rows in set
```

### Task 2 - BEFORE UPDATE trigger on Issue: fine = 5 x days late when return_date is filled

```sql
DELIMITER $$
CREATE TRIGGER trg_issue_fine BEFORE UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        SET NEW.fine = 5 * GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0);
    END IF;
END$$
DELIMITER ;
SHOW TRIGGERS LIKE 'Issue';
```

**Output**

```text
CREATE TRIGGER trg_issue_fine BEFORE UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        SET NEW.fine = 5 * GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0);
    END IF;
END

Query OK, 0 rows affected

SHOW TRIGGERS LIKE 'Issue'

+----------------+--------+-------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| Trigger        | Event  | Table | Statement                                                                                                                                                                  | Timing | Created                | sql_mode                                                                                                              | Definer        | character_set_client | collation_connection | Database Collation |
+----------------+--------+-------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| trg_issue_fine | UPDATE | issue | BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        SET NEW.fine = 5 * GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0);
    END IF;
END | BEFORE | 2026-10-30 10:42:28.44 | ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION | root@localhost | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+----------------+--------+-------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** Fires only when return_date goes from NULL to a date. GREATEST(..., 0) avoids negative fines for early returns.

### Task 3 - AFTER UPDATE trigger that increments available when a book is returned

```sql
DELIMITER $$
CREATE TRIGGER trg_issue_return AFTER UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Book SET available = available + 1 WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'library_4c';
```

**Output**

```text
CREATE TRIGGER trg_issue_return AFTER UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Book SET available = available + 1 WHERE book_id = NEW.book_id;
    END IF;
END

Query OK, 0 rows affected

SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'library_4c'

+------------------+---------------+--------------------+
| TRIGGER_NAME     | ACTION_TIMING | EVENT_MANIPULATION |
+------------------+---------------+--------------------+
| trg_issue_fine   | BEFORE        | UPDATE             |
| trg_issue_return | AFTER         | UPDATE             |
+------------------+---------------+--------------------+
2 rows in set
```

### Task 4 - Procedure issue_book(IN b, IN m): check availability, insert with due_date = issue_date + 14 days, decrement available; error if 0

```sql
DELIMITER $$
CREATE PROCEDURE issue_book(IN b VARCHAR(5), IN m VARCHAR(30))
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Book WHERE book_id = b FOR UPDATE;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found';
    END IF;
    IF v_avail <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not available';
    END IF;
    INSERT INTO Issue (book_id, member, issue_date, due_date)
    VALUES (b, m, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
    UPDATE Book SET available = available - 1 WHERE book_id = b;
END$$
DELIMITER ;
SHOW PROCEDURE STATUS WHERE Db = 'library_4c';
```

**Output**

```text
CREATE PROCEDURE issue_book(IN b VARCHAR(5), IN m VARCHAR(30))
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Book WHERE book_id = b FOR UPDATE;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found';
    END IF;
    IF v_avail <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not available';
    END IF;
    INSERT INTO Issue (book_id, member, issue_date, due_date)
    VALUES (b, m, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
    UPDATE Book SET available = available - 1 WHERE book_id = b;
END

Query OK, 0 rows affected

SHOW PROCEDURE STATUS WHERE Db = 'library_4c'

+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| Db         | Name       | Type      | Definer        | Modified            | Created             | Security_type | Comment | character_set_client | collation_connection | Database Collation |
+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| library_4c | issue_book | PROCEDURE | root@localhost | 2026-10-30 10:42:28 | 2026-10-30 10:42:28 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** FOR UPDATE locks the book row so two members cannot take the last copy at the same time.

### Task 5 - Return book 1 on 2026-10-20 and show the fine

```sql
UPDATE Issue SET return_date = '2026-10-20' WHERE issue_id = 1;
SELECT issue_id, book_id, member, due_date, return_date, fine FROM Issue WHERE issue_id = 1;
SELECT * FROM Book;
```

**Output**

```text
UPDATE Issue SET return_date = '2026-10-20' WHERE issue_id = 1

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT issue_id, book_id, member, due_date, return_date, fine FROM Issue WHERE issue_id = 1

+----------+---------+--------+------------+-------------+------+
| issue_id | book_id | member | due_date   | return_date | fine |
+----------+---------+--------+------------+-------------+------+
|        1 | B1      | Riya   | 2026-10-15 | 2026-10-20  |   25 |
+----------+---------+--------+------------+-------------+------+
1 row in set

SELECT * FROM Book

+---------+-------+-----------+
| book_id | title | available |
+---------+-------+-----------+
| B1      | DBMS  |         3 |
| B2      | ML    |         1 |
| B3      | DAA   |         0 |
+---------+-------+-----------+
3 rows in set
```

**Why this output is correct:** Due 2026-10-15, returned 2026-10-20 = 5 days late => fine 25. The AFTER trigger raises B1.available from 2 to 3.

### Task 6 - Call issue_book('B3','Sneha') and show the error

```sql
CALL issue_book('B3', 'Sneha');
SELECT COUNT(*) AS issues_for_sneha FROM Issue WHERE member = 'Sneha';
```

**Output**

```text
CALL issue_book('B3', 'Sneha')

ERROR 1644 (45000) at line 1: Book not available
SELECT COUNT(*) AS issues_for_sneha FROM Issue WHERE member = 'Sneha'

+------------------+
| issues_for_sneha |
+------------------+
|                0 |
+------------------+
1 row in set
```

**Why this output is correct:** B3 has 0 copies available, so the procedure signals 'Book not available' and inserts nothing.

### Task 7 - Function total_fine(member) returning the fine paid by a member

```sql
DELIMITER $$
CREATE FUNCTION total_fine(p_member VARCHAR(30)) RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COALESCE(SUM(fine), 0) INTO v_total FROM Issue WHERE member = p_member;
    RETURN v_total;
END$$
DELIMITER ;
SELECT total_fine('Riya') AS riya, total_fine('Amit') AS amit;
```

**Output**

```text
CREATE FUNCTION total_fine(p_member VARCHAR(30)) RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COALESCE(SUM(fine), 0) INTO v_total FROM Issue WHERE member = p_member;
    RETURN v_total;
END

Query OK, 0 rows affected

SELECT total_fine('Riya') AS riya, total_fine('Amit') AS amit

+------+------+
| riya | amit |
+------+------+
|   25 |    0 |
+------+------+
1 row in set
```

### Task 8 - Procedure overdue_list() with a cursor: books not returned past the due date

```sql
DELIMITER $$
CREATE PROCEDURE overdue_list()
BEGIN
    DECLARE v_book VARCHAR(5);
    DECLARE v_member VARCHAR(30);
    DECLARE v_due DATE;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT book_id, member, due_date FROM Issue WHERE return_date IS NULL AND due_date < CURRENT_DATE ORDER BY due_date;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_book, v_member, v_due;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SELECT CONCAT('Book ', v_book, ' held by ', v_member, ' is overdue by ', DATEDIFF(CURRENT_DATE, v_due), ' days (due ', v_due, ')') AS overdue;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
CALL overdue_list();
```

**Output**

```text
CREATE PROCEDURE overdue_list()
BEGIN
    DECLARE v_book VARCHAR(5);
    DECLARE v_member VARCHAR(30);
    DECLARE v_due DATE;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT book_id, member, due_date FROM Issue WHERE return_date IS NULL AND due_date < CURRENT_DATE ORDER BY due_date;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_book, v_member, v_due;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SELECT CONCAT('Book ', v_book, ' held by ', v_member, ' is overdue by ', DATEDIFF(CURRENT_DATE, v_due), ' days (due ', v_due, ')') AS overdue;
    END LOOP;
    CLOSE cur;
END

Query OK, 0 rows affected

CALL overdue_list()

+-------------------------------------------------------------+
| overdue                                                     |
+-------------------------------------------------------------+
| Book B2 held by Amit is overdue by 11 days (due 2026-10-19) |
+-------------------------------------------------------------+
1 row in set

Query OK, 0 rows affected
```

**Why this output is correct:** Loops over unreturned issues whose due_date is before today and prints one line per book. (Output depends on today's date.)

### Task 9 - Transaction: issue B1 and B2 to Sneha, SAVEPOINT after B1, ROLLBACK TO the savepoint, COMMIT

```sql
START TRANSACTION;
CALL issue_book('B1', 'Sneha');
SAVEPOINT after_b1;
CALL issue_book('B2', 'Sneha');
SELECT book_id, member FROM Issue WHERE member = 'Sneha';
ROLLBACK TO SAVEPOINT after_b1;
COMMIT;
SELECT issue_id, book_id, member FROM Issue WHERE member = 'Sneha';
SELECT * FROM Book;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

CALL issue_book('B1', 'Sneha')

Query OK, 1 row affected

SAVEPOINT after_b1

Query OK, 0 rows affected

CALL issue_book('B2', 'Sneha')

Query OK, 1 row affected

SELECT book_id, member FROM Issue WHERE member = 'Sneha'

+---------+--------+
| book_id | member |
+---------+--------+
| B1      | Sneha  |
| B2      | Sneha  |
+---------+--------+
2 rows in set

ROLLBACK TO SAVEPOINT after_b1

Query OK, 0 rows affected

COMMIT

Query OK, 0 rows affected

SELECT issue_id, book_id, member FROM Issue WHERE member = 'Sneha'

+----------+---------+--------+
| issue_id | book_id | member |
+----------+---------+--------+
|        3 | B1      | Sneha  |
+----------+---------+--------+
1 row in set

SELECT * FROM Book

+---------+-------+-----------+
| book_id | title | available |
+---------+-------+-----------+
| B1      | DBMS  |         2 |
| B2      | ML    |         1 |
| B3      | DAA   |         0 |
+---------+-------+-----------+
3 rows in set
```

**Why this output is correct:** Only the B1 issue survives: B1.available goes 3 -> 2, B2.available stays 1 because its issue and decrement were rolled back.

### Task 10 - Trigger that blocks issuing more than 3 books to one member

```sql
DELIMITER $$
CREATE TRIGGER trg_issue_limit BEFORE INSERT ON Issue FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Issue WHERE member = NEW.member AND return_date IS NULL) >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limit reached: a member can hold at most 3 books';
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
CALL issue_book('B1', 'Sneha');
CALL issue_book('B2', 'Sneha');
CALL issue_book('B1', 'Sneha');
SELECT member, COUNT(*) AS unreturned FROM Issue WHERE member = 'Sneha' AND return_date IS NULL GROUP BY member;
ROLLBACK;
```

**Output**

```text
CREATE TRIGGER trg_issue_limit BEFORE INSERT ON Issue FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Issue WHERE member = NEW.member AND return_date IS NULL) >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limit reached: a member can hold at most 3 books';
    END IF;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

CALL issue_book('B1', 'Sneha')

Query OK, 1 row affected

CALL issue_book('B2', 'Sneha')

Query OK, 1 row affected

CALL issue_book('B1', 'Sneha')

ERROR 1644 (45000) at line 12: Limit reached: a member can hold at most 3 books
SELECT member, COUNT(*) AS unreturned FROM Issue WHERE member = 'Sneha' AND return_date IS NULL GROUP BY member

+--------+------------+
| member | unreturned |
+--------+------------+
| Sneha  |          3 |
+--------+------------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** BEFORE INSERT counts the member's unreturned books; with 3 already out the 4th INSERT is rejected before it is written. Sneha already holds B1 (Task 9); two more are issued, the next one is blocked. Run in a transaction that is rolled back.

### Task 11 - Show all triggers with SHOW TRIGGERS

```sql
SHOW TRIGGERS\G
```

**Output**

```text
SHOW TRIGGERS

*************************** 1. row ***************************
             Trigger: trg_issue_limit
               Event: INSERT
               Table: issue
           Statement: BEGIN
    IF (SELECT COUNT(*) FROM Issue WHERE member = NEW.member AND return_date IS NULL) >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limit reached: a member can hold at most 3 books';
    END IF;
END
              Timing: BEFORE
             Created: 2026-10-30 10:42:29.97
            sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
             Definer: root@localhost
character_set_client: utf8mb4
collation_connection: utf8mb4_0900_ai_ci
  Database Collation: utf8mb4_0900_ai_ci
*************************** 2. row ***************************
             Trigger: trg_issue_fine
               Event: UPDATE
               Table: issue
           Statement: BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        SET NEW.fine = 5 * GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0);
    END IF;
END
              Timing: BEFORE
             Created: 2026-10-30 10:42:28.44
            sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
             Definer: root@localhost
character_set_client: utf8mb4
collation_connection: utf8mb4_0900_ai_ci
  Database Collation: utf8mb4_0900_ai_ci
*************************** 3. row ***************************
             Trigger: trg_issue_return
               Event: UPDATE
               Table: issue
           Statement: BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Book SET available = available + 1 WHERE book_id = NEW.book_id;
    END IF;
END
              Timing: AFTER
             Created: 2026-10-30 10:42:28.64
            sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
             Definer: root@localhost
character_set_client: utf8mb4
collation_connection: utf8mb4_0900_ai_ci
  Database Collation: utf8mb4_0900_ai_ci
3 rows in set
```

### Task 12 - Drop procedure overdue_list and verify

```sql
DROP PROCEDURE overdue_list;
SHOW PROCEDURE STATUS WHERE Db = 'library_4c' AND Name = 'overdue_list';
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'library_4c' ORDER BY routine_name;
CALL overdue_list();
```

**Output**

```text
DROP PROCEDURE overdue_list

Query OK, 0 rows affected

SHOW PROCEDURE STATUS WHERE Db = 'library_4c' AND Name = 'overdue_list'

Empty set

SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'library_4c' ORDER BY routine_name

+--------------+
| ROUTINE_NAME |
+--------------+
| issue_book   |
| total_fine   |
+--------------+
2 rows in set

CALL overdue_list()

ERROR 1305 (42000) at line 4: PROCEDURE library_4c.overdue_list does not exist
```

**Why this output is correct:** After DROP PROCEDURE the routine disappears from the catalogue and calling it fails with error 1305.


## Advanced / examiner-style queries

### Adv 1 - Early return gives no fine

```sql
START TRANSACTION;
CALL issue_book('B2', 'Zoya');
UPDATE Issue SET return_date = CURRENT_DATE WHERE member = 'Zoya';
SELECT member, due_date, return_date, fine FROM Issue WHERE member = 'Zoya';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

CALL issue_book('B2', 'Zoya')

Query OK, 1 row affected

UPDATE Issue SET return_date = CURRENT_DATE WHERE member = 'Zoya'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT member, due_date, return_date, fine FROM Issue WHERE member = 'Zoya'

+--------+------------+-------------+------+
| member | due_date   | return_date | fine |
+--------+------------+-------------+------+
| Zoya   | 2026-11-13 | 2026-10-30  |    0 |
+--------+------------+-------------+------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 2 - A return date is filled only once - second update does not re-charge the fine

```sql
START TRANSACTION;
SELECT available FROM Book WHERE book_id = 'B1';
UPDATE Issue SET return_date = '2026-10-25' WHERE issue_id = 1;
SELECT fine FROM Issue WHERE issue_id = 1;
SELECT available FROM Book WHERE book_id = 'B1';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

SELECT available FROM Book WHERE book_id = 'B1'

+-----------+
| available |
+-----------+
|         2 |
+-----------+
1 row in set

UPDATE Issue SET return_date = '2026-10-25' WHERE issue_id = 1

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT fine FROM Issue WHERE issue_id = 1

+------+
| fine |
+------+
|   25 |
+------+
1 row in set

SELECT available FROM Book WHERE book_id = 'B1'

+-----------+
| available |
+-----------+
|         2 |
+-----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** The trigger condition OLD.return_date IS NULL protects against double counting; B1.available is also not incremented twice.

### Adv 3 - Members and the number of unreturned books they hold

```sql
SELECT member, COUNT(*) AS holding FROM Issue WHERE return_date IS NULL GROUP BY member;
```

**Output**

```text
SELECT member, COUNT(*) AS holding FROM Issue WHERE return_date IS NULL GROUP BY member

+--------+---------+
| member | holding |
+--------+---------+
| Amit   |       1 |
| Sneha  |       1 |
+--------+---------+
2 rows in set
```

### Adv 4 - Return an Issue record for a book to make it available again, then issue B3 successfully

```sql
START TRANSACTION;
UPDATE Book SET available = 1 WHERE book_id = 'B3';
CALL issue_book('B3', 'Sneha');
SELECT * FROM Book WHERE book_id = 'B3';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Book SET available = 1 WHERE book_id = 'B3'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

CALL issue_book('B3', 'Sneha')

Query OK, 1 row affected

SELECT * FROM Book WHERE book_id = 'B3'

+---------+-------+-----------+
| book_id | title | available |
+---------+-------+-----------+
| B3      | DAA   |         0 |
+---------+-------+-----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 5 - CHECK stops available from going negative even if the procedure is bypassed

```sql
UPDATE Book SET available = available - 1 WHERE book_id = 'B3';
```

**Output**

```text
UPDATE Book SET available = available - 1 WHERE book_id = 'B3'

ERROR 3819 (HY000) at line 1: Check constraint 'chk_book_available' is violated.
```

**Why this output is correct:** Error 3819.

### Adv 6 - Fine report per member

```sql
SELECT member, SUM(fine) AS total_fine FROM Issue GROUP BY member ORDER BY total_fine DESC;
```

**Output**

```text
SELECT member, SUM(fine) AS total_fine FROM Issue GROUP BY member ORDER BY total_fine DESC

+--------+------------+
| member | total_fine |
+--------+------------+
| Riya   |         25 |
| Amit   |          0 |
| Sneha  |          0 |
+--------+------------+
3 rows in set
```

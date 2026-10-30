# Expected output - Experiment_01_SQL_Basics / 1A_Library

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - ER diagram with cardinalities (see 01_schema.sql and 06_explanation.md)

```sql
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_1a' AND COLUMN_KEY <> ''
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

**Output**

```text
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_1a' AND COLUMN_KEY <> ''
ORDER BY TABLE_NAME, ORDINAL_POSITION

+------------+-------------+------------+
| TABLE_NAME | COLUMN_NAME | COLUMN_KEY |
+------------+-------------+------------+
| book       | book_id     | PRI        |
| issue      | issue_id    | PRI        |
| issue      | book_id     | MUL        |
| issue      | member_id   | MUL        |
| member     | member_id   | PRI        |
| member     | phone       | UNI        |
+------------+-------------+------------+
6 rows in set
```

**Why this output is correct:** A member can borrow many books and a book can be borrowed many times, so Book-Member is M:N. The M:N is resolved by the Issue table: Member 1---N Issue and Book 1---N Issue.

### Task 2 - Create the three tables with PK, FK, NOT NULL, UNIQUE, CHECK

```sql
SHOW CREATE TABLE Issue\G
```

**Output**

```text
SHOW CREATE TABLE Issue

*************************** 1. row ***************************
       Table: Issue
Create Table: CREATE TABLE `issue` (
  `issue_id` int NOT NULL AUTO_INCREMENT,
  `book_id` varchar(10) NOT NULL,
  `member_id` varchar(10) NOT NULL,
  `issue_date` date NOT NULL,
  `return_date` date DEFAULT NULL,
  PRIMARY KEY (`issue_id`),
  KEY `fk_issue_book` (`book_id`),
  KEY `fk_issue_member` (`member_id`),
  CONSTRAINT `fk_issue_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`book_id`),
  CONSTRAINT `fk_issue_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `chk_issue_dates` CHECK ((`return_date` >= `issue_date`))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
1 row in set
```

**Why this output is correct:** Tables were created in 01_schema.sql; SHOW CREATE TABLE proves every constraint is stored.

### Task 3 - Insert given rows, then insert an issue for a non-existent book (FK error)

```sql
SELECT COUNT(*) AS books FROM Book;
INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B999', 'M01', '2026-10-20');
```

**Output**

```text
SELECT COUNT(*) AS books FROM Book

+-------+
| books |
+-------+
|     4 |
+-------+
1 row in set

INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B999', 'M01', '2026-10-20')

ERROR 1452 (23000) at line 2: Cannot add or update a child row: a foreign key constraint fails (`library_1a`.`issue`, CONSTRAINT `fk_issue_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`book_id`))
```

**Why this output is correct:** Rows were loaded by 02_sample_data.sql. B999 has no parent row in Book, so InnoDB rejects the insert with error 1452.

### Task 4 - Negative price and duplicate phone

```sql
INSERT INTO Book (book_id, title, author, price, copies) VALUES ('B105', 'Bad Book', 'Nobody', -50, 1);
INSERT INTO Member (member_id, name, dept, phone) VALUES ('M04', 'Dup Phone', 'CSE', '9822011111');
```

**Output**

```text
INSERT INTO Book (book_id, title, author, price, copies) VALUES ('B105', 'Bad Book', 'Nobody', -50, 1)

ERROR 3819 (HY000) at line 1: Check constraint 'chk_book_price' is violated.
INSERT INTO Member (member_id, name, dept, phone) VALUES ('M04', 'Dup Phone', 'CSE', '9822011111')

ERROR 1062 (23000) at line 2: Duplicate entry '9822011111' for key 'member.uq_member_phone'
```

**Why this output is correct:** price = -50 violates chk_book_price (error 3819); phone 9822011111 already belongs to M01 so uq_member_phone fires (error 1062).

### Task 5 - ALTER - add email column, widen title

```sql
ALTER TABLE Member ADD COLUMN email VARCHAR(60);
ALTER TABLE Book   MODIFY COLUMN title VARCHAR(100) NOT NULL;
DESCRIBE Member;
DESCRIBE Book;
```

**Output**

```text
ALTER TABLE Member ADD COLUMN email VARCHAR(60)

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

ALTER TABLE Book   MODIFY COLUMN title VARCHAR(100) NOT NULL

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

DESCRIBE Member

+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| member_id | varchar(10) | NO   | PRI | NULL    |       |
| name      | varchar(50) | NO   |     | NULL    |       |
| dept      | varchar(20) | YES  |     | NULL    |       |
| phone     | varchar(15) | NO   | UNI | NULL    |       |
| email     | varchar(60) | YES  |     | NULL    |       |
+-----------+-------------+------+-----+---------+-------+
5 rows in set

DESCRIBE Book

+---------+--------------+------+-----+---------+-------+
| Field   | Type         | Null | Key | Default | Extra |
+---------+--------------+------+-----+---------+-------+
| book_id | varchar(10)  | NO   | PRI | NULL    |       |
| title   | varchar(100) | NO   |     | NULL    |       |
| author  | varchar(40)  | NO   |     | NULL    |       |
| price   | decimal(8,2) | NO   |     | NULL    |       |
| copies  | int          | NO   |     | 1       |       |
+---------+--------------+------+-----+---------+-------+
5 rows in set
```

**Why this output is correct:** ADD COLUMN adds a nullable column, existing rows get NULL. MODIFY COLUMN changes the data type in place (VARCHAR(60) -> VARCHAR(100)).

### Task 6 - DEFAULT CURRENT_DATE on issue_date

```sql
ALTER TABLE Issue ALTER COLUMN issue_date SET DEFAULT (CURRENT_DATE);
INSERT INTO Issue (book_id, member_id) VALUES ('B102', 'M03');
SELECT issue_id, book_id, member_id, issue_date, issue_date = CURRENT_DATE AS defaulted_to_today FROM Issue WHERE issue_id > 3;
DELETE FROM Issue WHERE book_id = 'B102' AND member_id = 'M03';
```

**Output**

```text
ALTER TABLE Issue ALTER COLUMN issue_date SET DEFAULT (CURRENT_DATE)

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

INSERT INTO Issue (book_id, member_id) VALUES ('B102', 'M03')

Query OK, 1 row affected

SELECT issue_id, book_id, member_id, issue_date, issue_date = CURRENT_DATE AS defaulted_to_today FROM Issue WHERE issue_id > 3

+----------+---------+-----------+------------+--------------------+
| issue_id | book_id | member_id | issue_date | defaulted_to_today |
+----------+---------+-----------+------------+--------------------+
|        5 | B102    | M03       | 2026-10-30 |                  1 |
+----------+---------+-----------+------------+--------------------+
1 row in set

DELETE FROM Issue WHERE book_id = 'B102' AND member_id = 'M03'

Query OK, 1 row affected
```

**Why this output is correct:** MySQL 8.0.13+ allows an expression default, so it must be written in parentheses: DEFAULT (CURRENT_DATE). The new row below omits issue_date and receives today's date; it is then removed again to keep the data intact.

### Task 7 - Increase price of all Kanetkar books by 10%

```sql
UPDATE Book SET price = price * 1.10 WHERE author = 'Kanetkar';
SELECT book_id, title, author, price FROM Book;
```

**Output**

```text
UPDATE Book SET price = price * 1.10 WHERE author = 'Kanetkar'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT book_id, title, author, price FROM Book

+---------+--------------------------+----------+--------+
| book_id | title                    | author   | price  |
+---------+--------------------------+----------+--------+
| B101    | Database System Concepts | Korth    | 850.00 |
| B102    | Fundamentals of DBMS     | Navathe  | 720.00 |
| B103    | Let Us C                 | Kanetkar | 385.00 |
| B104    | Python Crash Course      | Matthes  | 600.00 |
+---------+--------------------------+----------+--------+
4 rows in set
```

**Why this output is correct:** Only the row WHERE author = 'Kanetkar' (B103) changes: 350 * 1.10 = 385.

### Task 8 - Mark B103 as returned today

```sql
UPDATE Issue SET return_date = CURRENT_DATE WHERE book_id = 'B103' AND return_date IS NULL;
SELECT * FROM Issue;
```

**Output**

```text
UPDATE Issue SET return_date = CURRENT_DATE WHERE book_id = 'B103' AND return_date IS NULL

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT * FROM Issue

+----------+---------+-----------+------------+-------------+
| issue_id | book_id | member_id | issue_date | return_date |
+----------+---------+-----------+------------+-------------+
|        1 | B101    | M01       | 2026-10-01 | 2026-10-10  |
|        2 | B103    | M02       | 2026-10-05 | 2026-10-30  |
|        3 | B104    | M01       | 2026-10-12 | NULL        |
+----------+---------+-----------+------------+-------------+
3 rows in set
```

**Why this output is correct:** return_date IS NULL ensures only the open loan is closed. CHECK(return_date >= issue_date) still passes (2026-10-05 <= today).

### Task 9 - Members currently holding more than 1 unreturned book

```sql
SELECT m.member_id, m.name, COUNT(*) AS unreturned
FROM Issue i JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL
GROUP BY m.member_id, m.name
HAVING COUNT(*) > 1;
START TRANSACTION;
INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B102', 'M01', '2026-10-20');
SELECT m.member_id, m.name, COUNT(*) AS unreturned
FROM Issue i JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL
GROUP BY m.member_id, m.name
HAVING COUNT(*) > 1;
ROLLBACK;
```

**Output**

```text
SELECT m.member_id, m.name, COUNT(*) AS unreturned
FROM Issue i JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL
GROUP BY m.member_id, m.name
HAVING COUNT(*) > 1

Empty set

START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B102', 'M01', '2026-10-20')

Query OK, 1 row affected

SELECT m.member_id, m.name, COUNT(*) AS unreturned
FROM Issue i JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL
GROUP BY m.member_id, m.name
HAVING COUNT(*) > 1

+-----------+------------+------------+
| member_id | name       | unreturned |
+-----------+------------+------------+
| M01       | Riya Patil |          2 |
+-----------+------------+------------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** GROUP BY member, count only rows with return_date IS NULL, HAVING filters groups (WHERE cannot filter on an aggregate). After task 8 nobody holds two books, so the first result is empty. The second run temporarily issues one more book to M01 inside a transaction (then ROLLBACK) to prove the query works.

### Task 10 - Delete member M03 and show remaining rows

```sql
DELETE FROM Member WHERE member_id = 'M03';
SELECT * FROM Member;
SELECT * FROM Issue;
```

**Output**

```text
DELETE FROM Member WHERE member_id = 'M03'

Query OK, 1 row affected

SELECT * FROM Member

+-----------+---------------+------+------------+-------+
| member_id | name          | dept | phone      | email |
+-----------+---------------+------+------------+-------+
| M01       | Riya Patil    | AIML | 9822011111 | NULL  |
| M02       | Amit Kulkarni | CSE  | 9822022222 | NULL  |
+-----------+---------------+------+------------+-------+
2 rows in set

SELECT * FROM Issue

+----------+---------+-----------+------------+-------------+
| issue_id | book_id | member_id | issue_date | return_date |
+----------+---------+-----------+------------+-------------+
|        1 | B101    | M01       | 2026-10-01 | 2026-10-10  |
|        2 | B103    | M02       | 2026-10-05 | 2026-10-30  |
|        3 | B104    | M01       | 2026-10-12 | NULL        |
+----------+---------+-----------+------------+-------------+
3 rows in set
```

**Why this output is correct:** M03 has no Issue rows, so the delete is allowed. (Deleting M01 would fail: see ADV 3 - RESTRICT behaviour of the FK.)

### Task 11 - User librarian, GRANT SELECT, INSERT on Issue, REVOKE INSERT, SHOW GRANTS

```sql
DROP USER IF EXISTS 'librarian'@'localhost';
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'Lib@12345';
GRANT SELECT, INSERT ON library_1a.Issue TO 'librarian'@'localhost';
SHOW GRANTS FOR 'librarian'@'localhost';
REVOKE INSERT ON library_1a.Issue FROM 'librarian'@'localhost';
SHOW GRANTS FOR 'librarian'@'localhost';
-- @as librarian Lib@12345
-- | INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B102', 'M01', '2026-10-21');
-- | SELECT COUNT(*) AS rows_visible FROM Issue;
```

**Output**

```text
DROP USER IF EXISTS 'librarian'@'localhost'

Query OK, 0 rows affected

CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'Lib@12345'

Query OK, 0 rows affected

GRANT SELECT, INSERT ON library_1a.Issue TO 'librarian'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'librarian'@'localhost'

+-------------------------------------------------------------------------+
| Grants for librarian@localhost                                          |
+-------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `librarian`@`localhost`                           |
| GRANT SELECT, INSERT ON `library_1a`.`issue` TO `librarian`@`localhost` |
+-------------------------------------------------------------------------+
2 rows in set

REVOKE INSERT ON library_1a.Issue FROM 'librarian'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'librarian'@'localhost'

+-----------------------------------------------------------------+
| Grants for librarian@localhost                                  |
+-----------------------------------------------------------------+
| GRANT USAGE ON *.* TO `librarian`@`localhost`                   |
| GRANT SELECT ON `library_1a`.`issue` TO `librarian`@`localhost` |
+-----------------------------------------------------------------+
2 rows in set

[session: user 'librarian']
INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B102', 'M01', '2026-10-21')

ERROR 1142 (42000) at line 1: INSERT command denied to user 'librarian'@'localhost' for table 'issue'
SELECT COUNT(*) AS rows_visible FROM Issue

+--------------+
| rows_visible |
+--------------+
|            3 |
+--------------+
1 row in set
```

**Why this output is correct:** DCL: privileges are stored per account. After REVOKE only SELECT on library_1a.Issue remains. (Oracle: GRANT ... TO librarian; no host part.)

### Task 12 - TRUNCATE a copy of Issue, DROP the copy; DELETE vs TRUNCATE vs DROP

```sql
CREATE TABLE Issue_copy AS SELECT * FROM Issue;
SELECT COUNT(*) AS rows_in_copy FROM Issue_copy;
TRUNCATE TABLE Issue_copy;
SELECT COUNT(*) AS rows_after_truncate FROM Issue_copy;
DROP TABLE Issue_copy;
SHOW TABLES;
```

**Output**

```text
CREATE TABLE Issue_copy AS SELECT * FROM Issue

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

SELECT COUNT(*) AS rows_in_copy FROM Issue_copy

+--------------+
| rows_in_copy |
+--------------+
|            3 |
+--------------+
1 row in set

TRUNCATE TABLE Issue_copy

Query OK, 0 rows affected

SELECT COUNT(*) AS rows_after_truncate FROM Issue_copy

+---------------------+
| rows_after_truncate |
+---------------------+
|                   0 |
+---------------------+
1 row in set

DROP TABLE Issue_copy

Query OK, 0 rows affected

SHOW TABLES

+----------------------+
| Tables_in_library_1a |
+----------------------+
| book                 |
| issue                |
| member               |
+----------------------+
3 rows in set
```

**Why this output is correct:** DELETE = DML, row by row, WHERE allowed, rollback-able, keeps AUTO_INCREMENT. TRUNCATE = DDL, removes all rows quickly, resets AUTO_INCREMENT, cannot be rolled back, no WHERE. DROP removes rows AND the table structure.


## Advanced / examiner-style queries

### Adv 1 - Books that have never been issued

```sql
SELECT b.book_id, b.title FROM Book b LEFT JOIN Issue i ON i.book_id = b.book_id WHERE i.issue_id IS NULL;
```

**Output**

```text
SELECT b.book_id, b.title FROM Book b LEFT JOIN Issue i ON i.book_id = b.book_id WHERE i.issue_id IS NULL

+---------+----------------------+
| book_id | title                |
+---------+----------------------+
| B102    | Fundamentals of DBMS |
+---------+----------------------+
1 row in set
```

**Why this output is correct:** LEFT JOIN keeps every book; rows with no match have NULL on the Issue side.

### Adv 2 - Who currently holds which book (unreturned loans), with days held

```sql
SELECT m.name, b.title, i.issue_date, DATEDIFF(CURRENT_DATE, i.issue_date) AS days_held
FROM Issue i JOIN Book b ON b.book_id = i.book_id JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL;
```

**Output**

```text
SELECT m.name, b.title, i.issue_date, DATEDIFF(CURRENT_DATE, i.issue_date) AS days_held
FROM Issue i JOIN Book b ON b.book_id = i.book_id JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL

+------------+---------------------+------------+-----------+
| name       | title               | issue_date | days_held |
+------------+---------------------+------------+-----------+
| Riya Patil | Python Crash Course | 2026-10-12 |        18 |
+------------+---------------------+------------+-----------+
1 row in set
```

**Why this output is correct:** DATEDIFF(CURRENT_DATE, issue_date) is the number of days since the book left the library.

### Adv 3 - Delete a member who still has issue records (RESTRICT behaviour)

```sql
DELETE FROM Member WHERE member_id = 'M01';
```

**Output**

```text
DELETE FROM Member WHERE member_id = 'M01'

ERROR 1451 (23000) at line 1: Cannot delete or update a parent row: a foreign key constraint fails (`library_1a`.`issue`, CONSTRAINT `fk_issue_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`))
```

**Why this output is correct:** The default FK action is RESTRICT/NO ACTION, so M01 (with 2 issue rows) cannot be deleted -> error 1451.

### Adv 4 - Overdue loans (policy: 14 days) for books not returned

```sql
SELECT i.issue_id, i.book_id, i.member_id, DATEDIFF(CURRENT_DATE, i.issue_date) - 14 AS days_overdue
FROM Issue i WHERE i.return_date IS NULL AND DATEDIFF(CURRENT_DATE, i.issue_date) > 14;
```

**Output**

```text
SELECT i.issue_id, i.book_id, i.member_id, DATEDIFF(CURRENT_DATE, i.issue_date) - 14 AS days_overdue
FROM Issue i WHERE i.return_date IS NULL AND DATEDIFF(CURRENT_DATE, i.issue_date) > 14

+----------+---------+-----------+--------------+
| issue_id | book_id | member_id | days_overdue |
+----------+---------+-----------+--------------+
|        3 | B104    | M01       |            4 |
+----------+---------+-----------+--------------+
1 row in set
```

### Adv 5 - Total inventory value per author

```sql
SELECT author, SUM(price * copies) AS stock_value FROM Book GROUP BY author ORDER BY stock_value DESC;
```

**Output**

```text
SELECT author, SUM(price * copies) AS stock_value FROM Book GROUP BY author ORDER BY stock_value DESC

+----------+-------------+
| author   | stock_value |
+----------+-------------+
| Korth    |     4250.00 |
| Kanetkar |     3080.00 |
| Matthes  |     2400.00 |
| Navathe  |     2160.00 |
+----------+-------------+
4 rows in set
```

### Adv 6 - Add ON DELETE CASCADE to the member FK, delete M02 and see its loans disappear

```sql
ALTER TABLE Issue DROP FOREIGN KEY fk_issue_member;
ALTER TABLE Issue ADD CONSTRAINT fk_issue_member FOREIGN KEY (member_id) REFERENCES Member(member_id) ON DELETE CASCADE;
DELETE FROM Member WHERE member_id = 'M02';
SELECT * FROM Issue;
```

**Output**

```text
ALTER TABLE Issue DROP FOREIGN KEY fk_issue_member

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

ALTER TABLE Issue ADD CONSTRAINT fk_issue_member FOREIGN KEY (member_id) REFERENCES Member(member_id) ON DELETE CASCADE

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

DELETE FROM Member WHERE member_id = 'M02'

Query OK, 1 row affected

SELECT * FROM Issue

+----------+---------+-----------+------------+-------------+
| issue_id | book_id | member_id | issue_date | return_date |
+----------+---------+-----------+------------+-------------+
|        1 | B101    | M01       | 2026-10-01 | 2026-10-10  |
|        3 | B104    | M01       | 2026-10-12 | NULL        |
+----------+---------+-----------+------------+-------------+
2 rows in set
```

**Why this output is correct:** Re-creating the FK with CASCADE makes the child rows follow the parent. Done inside a transaction-free demo, so we restore data afterwards.

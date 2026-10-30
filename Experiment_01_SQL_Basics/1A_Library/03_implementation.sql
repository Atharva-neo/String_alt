-- Experiment 1A - Library : implementation of the 12 tasks
-- Run after 01_schema.sql and 02_sample_data.sql.  MySQL 8 syntax (Oracle differences noted in comments).
/* @CONCEPTS
* **PRIMARY KEY** = NOT NULL + UNIQUE, one per table. **FOREIGN KEY** keeps Issue rows pointing at real Book/Member rows (referential integrity).
* **UNIQUE** (phone) rejects duplicates but still allows several NULLs; **CHECK** is enforced from MySQL 8.0.16 (older MySQL silently ignored it).
* **DDL** (CREATE/ALTER/DROP/TRUNCATE) auto-commits and cannot be rolled back; **DML** (INSERT/UPDATE/DELETE) can.
* **DCL**: GRANT / REVOKE manage privileges; `SHOW GRANTS` verifies them.
* Oracle differences: `MODIFY` instead of `MODIFY COLUMN`, `SYSDATE` instead of `CURRENT_DATE` in defaults, `DESCRIBE` works in both, users are created with `CREATE USER x IDENTIFIED BY pwd` (no `'@host'`).
*/

-- ### TASK 1: ER diagram with cardinalities (see 01_schema.sql and 06_explanation.md)
-- A member can borrow many books and a book can be borrowed many times, so Book-Member is M:N.
-- The M:N is resolved by the Issue table: Member 1---N Issue and Book 1---N Issue.
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_1a' AND COLUMN_KEY <> ''
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- ### TASK 2: Create the three tables with PK, FK, NOT NULL, UNIQUE, CHECK
-- Tables were created in 01_schema.sql; SHOW CREATE TABLE proves every constraint is stored.
SHOW CREATE TABLE Issue\G

-- ### TASK 3: Insert given rows, then insert an issue for a non-existent book (FK error)
-- Rows were loaded by 02_sample_data.sql. B999 has no parent row in Book, so InnoDB rejects the insert with error 1452.
SELECT COUNT(*) AS books FROM Book;
INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B999', 'M01', '2026-10-20');

-- ### TASK 4: Negative price and duplicate phone
-- price = -50 violates chk_book_price (error 3819); phone 9822011111 already belongs to M01 so uq_member_phone fires (error 1062).
INSERT INTO Book (book_id, title, author, price, copies) VALUES ('B105', 'Bad Book', 'Nobody', -50, 1);
INSERT INTO Member (member_id, name, dept, phone) VALUES ('M04', 'Dup Phone', 'CSE', '9822011111');

-- ### TASK 5: ALTER - add email column, widen title
-- ADD COLUMN adds a nullable column, existing rows get NULL. MODIFY COLUMN changes the data type in place (VARCHAR(60) -> VARCHAR(100)).
ALTER TABLE Member ADD COLUMN email VARCHAR(60);
ALTER TABLE Book   MODIFY COLUMN title VARCHAR(100) NOT NULL;
DESCRIBE Member;
DESCRIBE Book;

-- ### TASK 6: DEFAULT CURRENT_DATE on issue_date
-- MySQL 8.0.13+ allows an expression default, so it must be written in parentheses: DEFAULT (CURRENT_DATE).
-- The new row below omits issue_date and receives today's date; it is then removed again to keep the data intact.
ALTER TABLE Issue ALTER COLUMN issue_date SET DEFAULT (CURRENT_DATE);
INSERT INTO Issue (book_id, member_id) VALUES ('B102', 'M03');
SELECT issue_id, book_id, member_id, issue_date, issue_date = CURRENT_DATE AS defaulted_to_today FROM Issue WHERE issue_id > 3;
DELETE FROM Issue WHERE book_id = 'B102' AND member_id = 'M03';

-- ### TASK 7: Increase price of all Kanetkar books by 10%
-- Only the row WHERE author = 'Kanetkar' (B103) changes: 350 * 1.10 = 385.
UPDATE Book SET price = price * 1.10 WHERE author = 'Kanetkar';
SELECT book_id, title, author, price FROM Book;

-- ### TASK 8: Mark B103 as returned today
-- return_date IS NULL ensures only the open loan is closed. CHECK(return_date >= issue_date) still passes (2026-10-05 <= today).
UPDATE Issue SET return_date = CURRENT_DATE WHERE book_id = 'B103' AND return_date IS NULL;
SELECT * FROM Issue;

-- ### TASK 9: Members currently holding more than 1 unreturned book
-- GROUP BY member, count only rows with return_date IS NULL, HAVING filters groups (WHERE cannot filter on an aggregate).
-- After task 8 nobody holds two books, so the first result is empty. The second run temporarily issues one more book to M01
-- inside a transaction (then ROLLBACK) to prove the query works.
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

-- ### TASK 10: Delete member M03 and show remaining rows
-- M03 has no Issue rows, so the delete is allowed. (Deleting M01 would fail: see ADV 3 - RESTRICT behaviour of the FK.)
DELETE FROM Member WHERE member_id = 'M03';
SELECT * FROM Member;
SELECT * FROM Issue;

-- ### TASK 11: User librarian, GRANT SELECT, INSERT on Issue, REVOKE INSERT, SHOW GRANTS
-- DCL: privileges are stored per account. After REVOKE only SELECT on library_1a.Issue remains. (Oracle: GRANT ... TO librarian; no host part.)
DROP USER IF EXISTS 'librarian'@'localhost';
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'Lib@12345';
GRANT SELECT, INSERT ON library_1a.Issue TO 'librarian'@'localhost';
SHOW GRANTS FOR 'librarian'@'localhost';
REVOKE INSERT ON library_1a.Issue FROM 'librarian'@'localhost';
SHOW GRANTS FOR 'librarian'@'localhost';
-- @as librarian Lib@12345
-- | INSERT INTO Issue (book_id, member_id, issue_date) VALUES ('B102', 'M01', '2026-10-21');
-- | SELECT COUNT(*) AS rows_visible FROM Issue;

-- ### TASK 12: TRUNCATE a copy of Issue, DROP the copy; DELETE vs TRUNCATE vs DROP
-- DELETE = DML, row by row, WHERE allowed, rollback-able, keeps AUTO_INCREMENT. TRUNCATE = DDL, removes all rows quickly,
-- resets AUTO_INCREMENT, cannot be rolled back, no WHERE. DROP removes rows AND the table structure.
CREATE TABLE Issue_copy AS SELECT * FROM Issue;
SELECT COUNT(*) AS rows_in_copy FROM Issue_copy;
TRUNCATE TABLE Issue_copy;
SELECT COUNT(*) AS rows_after_truncate FROM Issue_copy;
DROP TABLE Issue_copy;
SHOW TABLES;

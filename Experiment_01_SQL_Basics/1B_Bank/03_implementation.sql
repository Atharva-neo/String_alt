-- Experiment 1B - Bank : implementation of the 12 tasks
/* @CONCEPTS
* **CHECK** with `IN (...)` models an enumeration; **DEFAULT** supplies a value when the column is omitted.
* **Column-level privilege**: `GRANT UPDATE (balance)` lets a user change only that column.
* `RENAME TABLE` keeps data, indexes and FKs (FKs automatically follow the new name).
* A copy made with `CREATE TABLE ... AS SELECT` has the data but **no constraints**, which is why it is safe to experiment on.
* Oracle: `RENAME Branch TO Bank_Branch;`, `ALTER TABLE ... ADD open_date DATE DEFAULT SYSDATE`.
*/

-- ### TASK 1: ER diagram for Branch, Customer, Account
-- Branch 1:N Account and Customer 1:N Account; Account is the many side and holds both FKs. See the diagram in 06_explanation.md.
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'bank_1b' ORDER BY table_name, constraint_type;

-- ### TASK 2: Tables with CHECK(balance >= 1000), CHECK(acc_type IN (...)) and DEFAULT 'Savings'
-- Proof of DEFAULT: insert an account without acc_type, it becomes 'Savings'; the row is then removed.
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5999, 'C3', 'BR2', 2000);
SELECT acc_no, acc_type FROM Account WHERE acc_no = 5999;
DELETE FROM Account WHERE acc_no = 5999;

-- ### TASK 3: Insert rows; balance 500 and type 'Fixed' must both fail
-- 500 < 1000 violates chk_acc_balance; 'Fixed' is not in the allowed list so chk_acc_type is violated. Both give error 3819.
SELECT * FROM Account;
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5005, 'C2', 'BR1', 'Savings', 500);
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5006, 'C2', 'BR1', 'Fixed', 5000);

-- ### TASK 4: Account for a non-existent branch (FK error)
-- BR9 is absent from Branch, so error 1452 (foreign key constraint fails).
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5007, 'C2', 'BR9', 'Savings', 5000);

-- ### TASK 5: Customers holding more than one account
-- GROUP BY customer + HAVING COUNT(*) > 1; only Rahul (C1) has two accounts (5001, 5004).
SELECT c.cust_id, c.name, COUNT(*) AS accounts
FROM Customer c JOIN Account a ON a.cust_id = c.cust_id
GROUP BY c.cust_id, c.name HAVING COUNT(*) > 1;

-- ### TASK 6: Add 4% interest to all Savings accounts
-- Savings accounts 5001 (25000 -> 26000) and 5003 (8000 -> 8320) change; Current accounts are untouched.
UPDATE Account SET balance = balance * 1.04 WHERE acc_type = 'Savings';
SELECT acc_no, acc_type, balance FROM Account;

-- ### TASK 7: Add column open_date with DEFAULT CURRENT_DATE
-- Existing rows also receive the default value (today) when a NOT NULL-with-default column is added.
ALTER TABLE Account ADD COLUMN open_date DATE NOT NULL DEFAULT (CURRENT_DATE);
SELECT acc_no, open_date FROM Account;

-- ### TASK 8: Total balance held at each branch
-- Aggregate per branch; LEFT JOIN from Branch so that a branch without accounts would still show with total 0.
SELECT b.branch_id, b.branch_name, COALESCE(SUM(a.balance), 0) AS total_balance
FROM Branch b LEFT JOIN Account a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name;

-- ### TASK 9: Delete accounts with balance below 10,000 - in a COPY of the table
-- The copy (CREATE TABLE AS SELECT) has no constraints; only account 5003 (8320) is below 10000, so it is removed from the copy only.
CREATE TABLE Account_copy AS SELECT * FROM Account;
DELETE FROM Account_copy WHERE balance < 10000;
SELECT acc_no, balance FROM Account_copy;
SELECT COUNT(*) AS original_rows_untouched FROM Account;

-- ### TASK 10: Rename Branch to Bank_Branch; TRUNCATE a copy of Account and show it is empty
-- RENAME TABLE is DDL; the FK from Account automatically follows the renamed parent.
RENAME TABLE Branch TO Bank_Branch;
SELECT constraint_name, referenced_table_name FROM information_schema.referential_constraints WHERE constraint_schema = 'bank_1b';
TRUNCATE TABLE Account_copy;
SELECT COUNT(*) AS rows_after_truncate FROM Account_copy;
DROP TABLE Account_copy;

-- ### TASK 11: User cashier with SELECT and UPDATE(balance); UPDATE of acc_type must fail
-- Column privilege: cashier may change only balance. Changing acc_type gives ERROR 1143 (UPDATE command denied for column).
DROP USER IF EXISTS 'cashier'@'localhost';
CREATE USER 'cashier'@'localhost' IDENTIFIED BY 'Cash@12345';
GRANT SELECT, UPDATE (balance) ON bank_1b.Account TO 'cashier'@'localhost';
SHOW GRANTS FOR 'cashier'@'localhost';
-- @as cashier Cash@12345
-- | UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001;
-- | UPDATE Account SET acc_type = 'Current' WHERE acc_no = 5001;
-- | SELECT acc_no, acc_type, balance FROM Account WHERE acc_no = 5001;

-- ### TASK 12: REVOKE UPDATE from cashier and verify with SHOW GRANTS
-- After the column-level REVOKE only SELECT remains; a later UPDATE by cashier is denied.
REVOKE UPDATE (balance) ON bank_1b.Account FROM 'cashier'@'localhost';
SHOW GRANTS FOR 'cashier'@'localhost';
-- @as cashier Cash@12345
-- | UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001;

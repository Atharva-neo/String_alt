# Expected output - Experiment_01_SQL_Basics / 1B_Bank

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - ER diagram for Branch, Customer, Account

```sql
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'bank_1b' ORDER BY table_name, constraint_type;
```

**Output**

```text
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'bank_1b' ORDER BY table_name, constraint_type

+------------+-----------------+-----------------+
| TABLE_NAME | CONSTRAINT_NAME | CONSTRAINT_TYPE |
+------------+-----------------+-----------------+
| account    | chk_acc_balance | CHECK           |
| account    | chk_acc_type    | CHECK           |
| account    | fk_acc_branch   | FOREIGN KEY     |
| account    | fk_acc_cust     | FOREIGN KEY     |
| account    | PRIMARY         | PRIMARY KEY     |
| branch     | PRIMARY         | PRIMARY KEY     |
| customer   | PRIMARY         | PRIMARY KEY     |
+------------+-----------------+-----------------+
7 rows in set
```

**Why this output is correct:** Branch 1:N Account and Customer 1:N Account; Account is the many side and holds both FKs. See the diagram in 06_explanation.md.

### Task 2 - Tables with CHECK(balance >= 1000), CHECK(acc_type IN (...)) and DEFAULT 'Savings'

```sql
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5999, 'C3', 'BR2', 2000);
SELECT acc_no, acc_type FROM Account WHERE acc_no = 5999;
DELETE FROM Account WHERE acc_no = 5999;
```

**Output**

```text
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5999, 'C3', 'BR2', 2000)

Query OK, 1 row affected

SELECT acc_no, acc_type FROM Account WHERE acc_no = 5999

+--------+----------+
| acc_no | acc_type |
+--------+----------+
|   5999 | Savings  |
+--------+----------+
1 row in set

DELETE FROM Account WHERE acc_no = 5999

Query OK, 1 row affected
```

**Why this output is correct:** Proof of DEFAULT: insert an account without acc_type, it becomes 'Savings'; the row is then removed.

### Task 3 - Insert rows; balance 500 and type 'Fixed' must both fail

```sql
SELECT * FROM Account;
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5005, 'C2', 'BR1', 'Savings', 500);
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5006, 'C2', 'BR1', 'Fixed', 5000);
```

**Output**

```text
SELECT * FROM Account

+--------+---------+-----------+----------+-----------+
| acc_no | cust_id | branch_id | acc_type | balance   |
+--------+---------+-----------+----------+-----------+
|   5001 | C1      | BR1       | Savings  |  25000.00 |
|   5002 | C2      | BR3       | Current  | 120000.00 |
|   5003 | C3      | BR2       | Savings  |   8000.00 |
|   5004 | C1      | BR1       | Current  |  45000.00 |
+--------+---------+-----------+----------+-----------+
4 rows in set

INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5005, 'C2', 'BR1', 'Savings', 500)

ERROR 3819 (HY000) at line 2: Check constraint 'chk_acc_balance' is violated.
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5006, 'C2', 'BR1', 'Fixed', 5000)

ERROR 3819 (HY000) at line 3: Check constraint 'chk_acc_type' is violated.
```

**Why this output is correct:** 500 < 1000 violates chk_acc_balance; 'Fixed' is not in the allowed list so chk_acc_type is violated. Both give error 3819.

### Task 4 - Account for a non-existent branch (FK error)

```sql
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5007, 'C2', 'BR9', 'Savings', 5000);
```

**Output**

```text
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES (5007, 'C2', 'BR9', 'Savings', 5000)

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`bank_1b`.`account`, CONSTRAINT `fk_acc_branch` FOREIGN KEY (`branch_id`) REFERENCES `branch` (`branch_id`))
```

**Why this output is correct:** BR9 is absent from Branch, so error 1452 (foreign key constraint fails).

### Task 5 - Customers holding more than one account

```sql
SELECT c.cust_id, c.name, COUNT(*) AS accounts
FROM Customer c JOIN Account a ON a.cust_id = c.cust_id
GROUP BY c.cust_id, c.name HAVING COUNT(*) > 1;
```

**Output**

```text
SELECT c.cust_id, c.name, COUNT(*) AS accounts
FROM Customer c JOIN Account a ON a.cust_id = c.cust_id
GROUP BY c.cust_id, c.name HAVING COUNT(*) > 1

+---------+------------+----------+
| cust_id | name       | accounts |
+---------+------------+----------+
| C1      | Rahul More |        2 |
+---------+------------+----------+
1 row in set
```

**Why this output is correct:** GROUP BY customer + HAVING COUNT(*) > 1; only Rahul (C1) has two accounts (5001, 5004).

### Task 6 - Add 4% interest to all Savings accounts

```sql
UPDATE Account SET balance = balance * 1.04 WHERE acc_type = 'Savings';
SELECT acc_no, acc_type, balance FROM Account;
```

**Output**

```text
UPDATE Account SET balance = balance * 1.04 WHERE acc_type = 'Savings'

Query OK, 2 rows affected
Rows matched: 2  Changed: 2  Warnings: 0

SELECT acc_no, acc_type, balance FROM Account

+--------+----------+-----------+
| acc_no | acc_type | balance   |
+--------+----------+-----------+
|   5001 | Savings  |  26000.00 |
|   5002 | Current  | 120000.00 |
|   5003 | Savings  |   8320.00 |
|   5004 | Current  |  45000.00 |
+--------+----------+-----------+
4 rows in set
```

**Why this output is correct:** Savings accounts 5001 (25000 -> 26000) and 5003 (8000 -> 8320) change; Current accounts are untouched.

### Task 7 - Add column open_date with DEFAULT CURRENT_DATE

```sql
ALTER TABLE Account ADD COLUMN open_date DATE NOT NULL DEFAULT (CURRENT_DATE);
SELECT acc_no, open_date FROM Account;
```

**Output**

```text
ALTER TABLE Account ADD COLUMN open_date DATE NOT NULL DEFAULT (CURRENT_DATE)

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT acc_no, open_date FROM Account

+--------+------------+
| acc_no | open_date  |
+--------+------------+
|   5001 | 2026-10-30 |
|   5002 | 2026-10-30 |
|   5003 | 2026-10-30 |
|   5004 | 2026-10-30 |
+--------+------------+
4 rows in set
```

**Why this output is correct:** Existing rows also receive the default value (today) when a NOT NULL-with-default column is added.

### Task 8 - Total balance held at each branch

```sql
SELECT b.branch_id, b.branch_name, COALESCE(SUM(a.balance), 0) AS total_balance
FROM Branch b LEFT JOIN Account a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name;
```

**Output**

```text
SELECT b.branch_id, b.branch_name, COALESCE(SUM(a.balance), 0) AS total_balance
FROM Branch b LEFT JOIN Account a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name

+-----------+-------------+---------------+
| branch_id | branch_name | total_balance |
+-----------+-------------+---------------+
| BR1       | Vishrambag  |      71000.00 |
| BR2       | Rajarampuri |       8320.00 |
| BR3       | Deccan      |     120000.00 |
+-----------+-------------+---------------+
3 rows in set
```

**Why this output is correct:** Aggregate per branch; LEFT JOIN from Branch so that a branch without accounts would still show with total 0.

### Task 9 - Delete accounts with balance below 10,000 - in a COPY of the table

```sql
CREATE TABLE Account_copy AS SELECT * FROM Account;
DELETE FROM Account_copy WHERE balance < 10000;
SELECT acc_no, balance FROM Account_copy;
SELECT COUNT(*) AS original_rows_untouched FROM Account;
```

**Output**

```text
CREATE TABLE Account_copy AS SELECT * FROM Account

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

DELETE FROM Account_copy WHERE balance < 10000

Query OK, 1 row affected

SELECT acc_no, balance FROM Account_copy

+--------+-----------+
| acc_no | balance   |
+--------+-----------+
|   5001 |  26000.00 |
|   5002 | 120000.00 |
|   5004 |  45000.00 |
+--------+-----------+
3 rows in set

SELECT COUNT(*) AS original_rows_untouched FROM Account

+-------------------------+
| original_rows_untouched |
+-------------------------+
|                       4 |
+-------------------------+
1 row in set
```

**Why this output is correct:** The copy (CREATE TABLE AS SELECT) has no constraints; only account 5003 (8320) is below 10000, so it is removed from the copy only.

### Task 10 - Rename Branch to Bank_Branch; TRUNCATE a copy of Account and show it is empty

```sql
RENAME TABLE Branch TO Bank_Branch;
SELECT constraint_name, referenced_table_name FROM information_schema.referential_constraints WHERE constraint_schema = 'bank_1b';
TRUNCATE TABLE Account_copy;
SELECT COUNT(*) AS rows_after_truncate FROM Account_copy;
DROP TABLE Account_copy;
```

**Output**

```text
RENAME TABLE Branch TO Bank_Branch

Query OK, 0 rows affected

SELECT constraint_name, referenced_table_name FROM information_schema.referential_constraints WHERE constraint_schema = 'bank_1b'

+-----------------+-----------------------+
| CONSTRAINT_NAME | REFERENCED_TABLE_NAME |
+-----------------+-----------------------+
| fk_acc_branch   | bank_branch           |
| fk_acc_cust     | customer              |
+-----------------+-----------------------+
2 rows in set

TRUNCATE TABLE Account_copy

Query OK, 0 rows affected

SELECT COUNT(*) AS rows_after_truncate FROM Account_copy

+---------------------+
| rows_after_truncate |
+---------------------+
|                   0 |
+---------------------+
1 row in set

DROP TABLE Account_copy

Query OK, 0 rows affected
```

**Why this output is correct:** RENAME TABLE is DDL; the FK from Account automatically follows the renamed parent.

### Task 11 - User cashier with SELECT and UPDATE(balance); UPDATE of acc_type must fail

```sql
DROP USER IF EXISTS 'cashier'@'localhost';
CREATE USER 'cashier'@'localhost' IDENTIFIED BY 'Cash@12345';
GRANT SELECT, UPDATE (balance) ON bank_1b.Account TO 'cashier'@'localhost';
SHOW GRANTS FOR 'cashier'@'localhost';
-- @as cashier Cash@12345
-- | UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001;
-- | UPDATE Account SET acc_type = 'Current' WHERE acc_no = 5001;
-- | SELECT acc_no, acc_type, balance FROM Account WHERE acc_no = 5001;
```

**Output**

```text
DROP USER IF EXISTS 'cashier'@'localhost'

Query OK, 0 rows affected

CREATE USER 'cashier'@'localhost' IDENTIFIED BY 'Cash@12345'

Query OK, 0 rows affected

GRANT SELECT, UPDATE (balance) ON bank_1b.Account TO 'cashier'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'cashier'@'localhost'

+----------------------------------------------------------------------------------+
| Grants for cashier@localhost                                                     |
+----------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `cashier`@`localhost`                                      |
| GRANT SELECT, UPDATE (`balance`) ON `bank_1b`.`account` TO `cashier`@`localhost` |
+----------------------------------------------------------------------------------+
2 rows in set

[session: user 'cashier']
UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

UPDATE Account SET acc_type = 'Current' WHERE acc_no = 5001

ERROR 1143 (42000) at line 2: UPDATE command denied to user 'cashier'@'localhost' for column 'acc_type' in table 'account'
SELECT acc_no, acc_type, balance FROM Account WHERE acc_no = 5001

+--------+----------+----------+
| acc_no | acc_type | balance  |
+--------+----------+----------+
|   5001 | Savings  | 26100.00 |
+--------+----------+----------+
1 row in set
```

**Why this output is correct:** Column privilege: cashier may change only balance. Changing acc_type gives ERROR 1143 (UPDATE command denied for column).

### Task 12 - REVOKE UPDATE from cashier and verify with SHOW GRANTS

```sql
REVOKE UPDATE (balance) ON bank_1b.Account FROM 'cashier'@'localhost';
SHOW GRANTS FOR 'cashier'@'localhost';
-- @as cashier Cash@12345
-- | UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001;
```

**Output**

```text
REVOKE UPDATE (balance) ON bank_1b.Account FROM 'cashier'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'cashier'@'localhost'

+--------------------------------------------------------------+
| Grants for cashier@localhost                                 |
+--------------------------------------------------------------+
| GRANT USAGE ON *.* TO `cashier`@`localhost`                  |
| GRANT SELECT ON `bank_1b`.`account` TO `cashier`@`localhost` |
+--------------------------------------------------------------+
2 rows in set

[session: user 'cashier']
UPDATE Account SET balance = balance + 100 WHERE acc_no = 5001

ERROR 1142 (42000) at line 1: UPDATE command denied to user 'cashier'@'localhost' for table 'account'
```

**Why this output is correct:** After the column-level REVOKE only SELECT remains; a later UPDATE by cashier is denied.


## Advanced / examiner-style queries

### Adv 1 - Customers with their total balance and number of accounts, richest first

```sql
SELECT c.name, COUNT(a.acc_no) AS accounts, SUM(a.balance) AS total FROM Customer c JOIN Account a USING (cust_id) GROUP BY c.cust_id, c.name ORDER BY total DESC;
```

**Output**

```text
SELECT c.name, COUNT(a.acc_no) AS accounts, SUM(a.balance) AS total FROM Customer c JOIN Account a USING (cust_id) GROUP BY c.cust_id, c.name ORDER BY total DESC

+--------------+----------+-----------+
| name         | accounts | total     |
+--------------+----------+-----------+
| Pooja Shinde |        1 | 120000.00 |
| Rahul More   |        2 |  71100.00 |
| Kiran Desai  |        1 |   8320.00 |
+--------------+----------+-----------+
3 rows in set
```

### Adv 2 - Branch with the highest total balance

```sql
SELECT b.branch_name, SUM(a.balance) AS total FROM Bank_Branch b JOIN Account a USING (branch_id) GROUP BY b.branch_id, b.branch_name ORDER BY total DESC LIMIT 1;
```

**Output**

```text
SELECT b.branch_name, SUM(a.balance) AS total FROM Bank_Branch b JOIN Account a USING (branch_id) GROUP BY b.branch_id, b.branch_name ORDER BY total DESC LIMIT 1

+-------------+-----------+
| branch_name | total     |
+-------------+-----------+
| Deccan      | 120000.00 |
+-------------+-----------+
1 row in set
```

**Why this output is correct:** ORDER BY ... LIMIT 1 on the grouped result.

### Adv 3 - Customers older than 35 as of today with their accounts

```sql
SELECT c.name, TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) AS age, a.acc_no FROM Customer c JOIN Account a USING (cust_id) WHERE TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) > 35;
```

**Output**

```text
SELECT c.name, TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) AS age, a.acc_no FROM Customer c JOIN Account a USING (cust_id) WHERE TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) > 35

+--------------+------+--------+
| name         | age  | acc_no |
+--------------+------+--------+
| Pooja Shinde |   36 |   5002 |
| Kiran Desai  |   38 |   5003 |
+--------------+------+--------+
2 rows in set
```

### Adv 4 - Delete the customer who still has accounts (RESTRICT)

```sql
DELETE FROM Customer WHERE cust_id = 'C1';
```

**Output**

```text
DELETE FROM Customer WHERE cust_id = 'C1'

ERROR 1451 (23000) at line 1: Cannot delete or update a parent row: a foreign key constraint fails (`bank_1b`.`account`, CONSTRAINT `fk_acc_cust` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`))
```

**Why this output is correct:** Error 1451 because Account rows reference C1.

### Adv 5 - Violate NOT NULL: insert a customer with no name

```sql
INSERT INTO Customer (cust_id, name) VALUES ('C9', NULL);
```

**Output**

```text
INSERT INTO Customer (cust_id, name) VALUES ('C9', NULL)

ERROR 1048 (23000) at line 1: Column 'name' cannot be null
```

**Why this output is correct:** Error 1048 (Column 'name' cannot be null).

### Adv 6 - Duplicate primary key

```sql
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5001, 'C2', 'BR1', 5000);
```

**Output**

```text
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5001, 'C2', 'BR1', 5000)

ERROR 1062 (23000) at line 1: Duplicate entry '5001' for key 'account.PRIMARY'
```

**Why this output is correct:** Error 1062 because account 5001 already exists.

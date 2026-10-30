# Expected output - Experiment_04_Triggers_Procedures_ACID / 4A_Bank_Transfer

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Account and Txn_Log and insert the data

```sql
SELECT * FROM Account;
SELECT COUNT(*) AS log_rows FROM Txn_Log;
```

**Output**

```text
SELECT * FROM Account

+--------+--------+----------+
| acc_no | holder | balance  |
+--------+--------+----------+
|   1001 | Rahul  | 50000.00 |
|   1002 | Pooja  | 20000.00 |
|   1003 | Kiran  |  5000.00 |
+--------+--------+----------+
3 rows in set

SELECT COUNT(*) AS log_rows FROM Txn_Log

+----------+
| log_rows |
+----------+
|        0 |
+----------+
1 row in set
```

**Why this output is correct:** Tables and rows were created by 01_schema.sql / 02_sample_data.sql; Txn_Log is empty.

### Task 2 - AFTER UPDATE trigger that logs every balance change (Debit / Credit)

```sql
DELIMITER $$
CREATE TRIGGER trg_account_log AFTER UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance <> OLD.balance THEN
        INSERT INTO Txn_Log (acc_no, txn_type, amount)
        VALUES (NEW.acc_no, IF(NEW.balance < OLD.balance, 'Debit', 'Credit'), ABS(NEW.balance - OLD.balance));
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
UPDATE Account SET balance = balance + 250 WHERE acc_no = 1003;
SELECT log_id, acc_no, txn_type, amount FROM Txn_Log;
ROLLBACK;
```

**Output**

```text
CREATE TRIGGER trg_account_log AFTER UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance <> OLD.balance THEN
        INSERT INTO Txn_Log (acc_no, txn_type, amount)
        VALUES (NEW.acc_no, IF(NEW.balance < OLD.balance, 'Debit', 'Credit'), ABS(NEW.balance - OLD.balance));
    END IF;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

UPDATE Account SET balance = balance + 250 WHERE acc_no = 1003

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT log_id, acc_no, txn_type, amount FROM Txn_Log

+--------+--------+----------+--------+
| log_id | acc_no | txn_type | amount |
+--------+--------+----------+--------+
|      1 |   1003 | Credit   | 250.00 |
+--------+--------+----------+--------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** Fires after each UPDATE of Account; compares OLD.balance and NEW.balance and inserts the difference with the direction.

### Task 3 - BEFORE UPDATE trigger that blocks a balance below 1000

```sql
DELIMITER $$
CREATE TRIGGER trg_account_min_balance BEFORE UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance < 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Balance cannot fall below 1000';
    END IF;
END$$
DELIMITER ;
UPDATE Account SET balance = 500 WHERE acc_no = 1003;
SELECT acc_no, balance FROM Account WHERE acc_no = 1003;
```

**Output**

```text
CREATE TRIGGER trg_account_min_balance BEFORE UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance < 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Balance cannot fall below 1000';
    END IF;
END

Query OK, 0 rows affected

UPDATE Account SET balance = 500 WHERE acc_no = 1003

ERROR 1644 (45000) at line 9: Balance cannot fall below 1000
SELECT acc_no, balance FROM Account WHERE acc_no = 1003

+--------+---------+
| acc_no | balance |
+--------+---------+
|   1003 | 5000.00 |
+--------+---------+
1 row in set
```

**Why this output is correct:** SIGNAL raises SQLSTATE 45000 with a message; the UPDATE is cancelled and nothing is logged.

### Task 4 - Procedures deposit(acc, amt) and withdraw(acc, amt)

```sql
DELIMITER $$
CREATE PROCEDURE deposit(IN p_acc INT, IN p_amt DECIMAL(12,2))
BEGIN
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deposit amount must be positive';
    END IF;
    UPDATE Account SET balance = balance + p_amt WHERE acc_no = p_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
    END IF;
END$$
CREATE PROCEDURE withdraw(IN p_acc INT, IN p_amt DECIMAL(12,2))
BEGIN
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Withdrawal amount must be positive';
    END IF;
    UPDATE Account SET balance = balance - p_amt WHERE acc_no = p_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
CALL deposit(1003, 500);
CALL withdraw(1003, 200);
SELECT acc_no, balance FROM Account WHERE acc_no = 1003;
CALL withdraw(1003, 99999);
CALL deposit(9999, 10);
ROLLBACK;
SELECT acc_no, balance FROM Account WHERE acc_no = 1003;
DELETE FROM Txn_Log;
```

**Output**

```text
CREATE PROCEDURE deposit(IN p_acc INT, IN p_amt DECIMAL(12,2))
BEGIN
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deposit amount must be positive';
    END IF;
    UPDATE Account SET balance = balance + p_amt WHERE acc_no = p_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
    END IF;
END

Query OK, 0 rows affected

CREATE PROCEDURE withdraw(IN p_acc INT, IN p_amt DECIMAL(12,2))
BEGIN
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Withdrawal amount must be positive';
    END IF;
    UPDATE Account SET balance = balance - p_amt WHERE acc_no = p_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
    END IF;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

CALL deposit(1003, 500)

Query OK, 1 row affected

CALL withdraw(1003, 200)

Query OK, 1 row affected

SELECT acc_no, balance FROM Account WHERE acc_no = 1003

+--------+---------+
| acc_no | balance |
+--------+---------+
|   1003 | 5300.00 |
+--------+---------+
1 row in set

CALL withdraw(1003, 99999)

ERROR 1644 (45000) at line 27: Balance cannot fall below 1000
CALL deposit(9999, 10)

ERROR 1644 (45000) at line 28: Account not found
ROLLBACK

Query OK, 0 rows affected

SELECT acc_no, balance FROM Account WHERE acc_no = 1003

+--------+---------+
| acc_no | balance |
+--------+---------+
|   1003 | 5000.00 |
+--------+---------+
1 row in set

DELETE FROM Txn_Log

Query OK, 0 rows affected
```

**Why this output is correct:** Both validate the amount and the account; the min-balance trigger from Task 3 protects withdraw. Tested inside a transaction that is rolled back, so the PDF's starting balances are unchanged (note: AUTO_INCREMENT values used by the rolled-back log rows are NOT given back - gaps in log_id are normal).

### Task 5 - transfer_funds(IN from_acc, IN to_acc, IN amt) inside START TRANSACTION ... COMMIT, ROLLBACK if insufficient

```sql
DELIMITER $$
CREATE PROCEDURE transfer_funds(IN from_acc INT, IN to_acc INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF amt <= 0 OR from_acc = to_acc THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid transfer request';
    END IF;
    START TRANSACTION;
    SELECT balance INTO v_bal FROM Account WHERE acc_no = from_acc FOR UPDATE;
    IF v_bal IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source account not found';
    END IF;
    IF v_bal - amt < 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
    UPDATE Account SET balance = balance - amt WHERE acc_no = from_acc;
    UPDATE Account SET balance = balance + amt WHERE acc_no = to_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination account not found';
    END IF;
    COMMIT;
END$$
DELIMITER ;
SHOW PROCEDURE STATUS WHERE Db = 'bank_4a';
```

**Output**

```text
CREATE PROCEDURE transfer_funds(IN from_acc INT, IN to_acc INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF amt <= 0 OR from_acc = to_acc THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid transfer request';
    END IF;
    START TRANSACTION;
    SELECT balance INTO v_bal FROM Account WHERE acc_no = from_acc FOR UPDATE;
    IF v_bal IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source account not found';
    END IF;
    IF v_bal - amt < 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
    UPDATE Account SET balance = balance - amt WHERE acc_no = from_acc;
    UPDATE Account SET balance = balance + amt WHERE acc_no = to_acc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination account not found';
    END IF;
    COMMIT;
END

Query OK, 0 rows affected

SHOW PROCEDURE STATUS WHERE Db = 'bank_4a'

+---------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| Db      | Name           | Type      | Definer        | Modified            | Created             | Security_type | Comment | character_set_client | collation_connection | Database Collation |
+---------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| bank_4a | deposit        | PROCEDURE | root@localhost | 2026-10-30 10:42:15 | 2026-10-30 10:42:15 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
| bank_4a | transfer_funds | PROCEDURE | root@localhost | 2026-10-30 10:42:16 | 2026-10-30 10:42:16 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
| bank_4a | withdraw       | PROCEDURE | root@localhost | 2026-10-30 10:42:15 | 2026-10-30 10:42:15 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+---------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
3 rows in set
```

**Why this output is correct:** SELECT ... FOR UPDATE locks the source row. If funds are short we SIGNAL; the EXIT HANDLER rolls back and re-raises the error to the caller. "Insufficient" also covers the 1000 minimum balance rule (balance after debit must stay >= 1000).

### Task 6 - Call transfer_funds(1001, 1002, 10000) and show both tables

```sql
CALL transfer_funds(1001, 1002, 10000);
SELECT * FROM Account;
SELECT log_id, acc_no, txn_type, amount FROM Txn_Log;
```

**Output**

```text
CALL transfer_funds(1001, 1002, 10000)

Query OK, 0 rows affected

SELECT * FROM Account

+--------+--------+----------+
| acc_no | holder | balance  |
+--------+--------+----------+
|   1001 | Rahul  | 40000.00 |
|   1002 | Pooja  | 30000.00 |
|   1003 | Kiran  |  5000.00 |
+--------+--------+----------+
3 rows in set

SELECT log_id, acc_no, txn_type, amount FROM Txn_Log

+--------+--------+----------+----------+
| log_id | acc_no | txn_type | amount   |
+--------+--------+----------+----------+
|      4 |   1001 | Debit    | 10000.00 |
|      5 |   1002 | Credit   | 10000.00 |
+--------+--------+----------+----------+
2 rows in set
```

**Why this output is correct:** 1001: 50000 -> 40000, 1002: 20000 -> 30000. The AFTER UPDATE trigger logs one Debit and one Credit of 10000. log_id starts at 4 and not 1 because ids 1-3 were consumed by log rows of the rolled-back tests in Tasks 2 and 4 (AUTO_INCREMENT is never rolled back).

### Task 7 - transfer_funds(1003, 1001, 8000) - rollback, balances unchanged (atomicity, consistency)

```sql
CALL transfer_funds(1003, 1001, 8000);
SELECT * FROM Account;
SELECT COUNT(*) AS log_rows_after_failed_transfer FROM Txn_Log;
```

**Output**

```text
CALL transfer_funds(1003, 1001, 8000)

ERROR 1644 (45000) at line 1: Insufficient balance
SELECT * FROM Account

+--------+--------+----------+
| acc_no | holder | balance  |
+--------+--------+----------+
|   1001 | Rahul  | 40000.00 |
|   1002 | Pooja  | 30000.00 |
|   1003 | Kiran  |  5000.00 |
+--------+--------+----------+
3 rows in set

SELECT COUNT(*) AS log_rows_after_failed_transfer FROM Txn_Log

+--------------------------------+
| log_rows_after_failed_transfer |
+--------------------------------+
|                              2 |
+--------------------------------+
1 row in set
```

**Why this output is correct:** Kiran has 5000; 5000 - 8000 < 1000, so the procedure signals "Insufficient balance" and the handler ROLLBACKs. Nothing changes and nothing is logged.

### Task 8 - Function get_balance(acc) and its use in SELECT

```sql
DELIMITER $$
CREATE FUNCTION get_balance(p_acc INT) RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    SELECT balance INTO v_bal FROM Account WHERE acc_no = p_acc;
    RETURN v_bal;
END$$
DELIMITER ;
SELECT acc_no, holder, get_balance(acc_no) AS balance_via_function FROM Account;
SELECT get_balance(1001) + get_balance(1002) AS combined_balance;
```

**Output**

```text
CREATE FUNCTION get_balance(p_acc INT) RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    SELECT balance INTO v_bal FROM Account WHERE acc_no = p_acc;
    RETURN v_bal;
END

Query OK, 0 rows affected

SELECT acc_no, holder, get_balance(acc_no) AS balance_via_function FROM Account

+--------+--------+----------------------+
| acc_no | holder | balance_via_function |
+--------+--------+----------------------+
|   1001 | Rahul  |             40000.00 |
|   1002 | Pooja  |             30000.00 |
|   1003 | Kiran  |              5000.00 |
+--------+--------+----------------------+
3 rows in set

SELECT get_balance(1001) + get_balance(1002) AS combined_balance

+------------------+
| combined_balance |
+------------------+
|         70000.00 |
+------------------+
1 row in set
```

**Why this output is correct:** A function returns one scalar and can be used in any expression. READS SQL DATA tells MySQL it only reads tables.

### Task 9 - Procedure mini_statement(acc) - last 5 transactions

```sql
DELIMITER $$
CREATE PROCEDURE mini_statement(IN p_acc INT)
BEGIN
    SELECT log_id, txn_type, amount, txn_time FROM Txn_Log WHERE acc_no = p_acc ORDER BY log_id DESC LIMIT 5;
END$$
DELIMITER ;
CALL mini_statement(1001);
CALL mini_statement(1002);
```

**Output**

```text
CREATE PROCEDURE mini_statement(IN p_acc INT)
BEGIN
    SELECT log_id, txn_type, amount, txn_time FROM Txn_Log WHERE acc_no = p_acc ORDER BY log_id DESC LIMIT 5;
END

Query OK, 0 rows affected

CALL mini_statement(1001)

+--------+----------+----------+---------------------+
| log_id | txn_type | amount   | txn_time            |
+--------+----------+----------+---------------------+
|      4 | Debit    | 10000.00 | 2026-10-30 10:42:16 |
+--------+----------+----------+---------------------+
1 row in set

Query OK, 0 rows affected

CALL mini_statement(1002)

+--------+----------+----------+---------------------+
| log_id | txn_type | amount   | txn_time            |
+--------+----------+----------+---------------------+
|      5 | Credit   | 10000.00 | 2026-10-30 10:42:16 |
+--------+----------+----------+---------------------+
1 row in set

Query OK, 0 rows affected
```

**Why this output is correct:** ORDER BY log_id DESC LIMIT 5 returns the newest entries first.

### Task 10 - Isolation - transfer in one session, read from another before COMMIT

```sql
SELECT 'see run_demo.py: Task 10' AS note;
```

**Output**

```text
SELECT 'see run_demo.py: Task 10' AS note

+--------------------------+
| note                     |
+--------------------------+
| see run_demo.py: Task 10 |
+--------------------------+
1 row in set
```

**Why this output is correct:** Needs two real connections, therefore executed by run_demo.py (see the "Multi-session demonstration" section further down this file and session1.sql / session2.sql). Under REPEATABLE READ (default) S2 keeps seeing the OLD balances until S1 commits, and S2's UPDATE on the same row waits for S1's row lock.

### Task 11 - Commit a transfer, restart the server, show it persists (durability)

```sql
CALL transfer_funds(1002, 1003, 2000);
SELECT * FROM Account;
```

**Output**

```text
CALL transfer_funds(1002, 1003, 2000)

Query OK, 0 rows affected

SELECT * FROM Account

+--------+--------+----------+
| acc_no | holder | balance  |
+--------+--------+----------+
|   1001 | Rahul  | 40000.00 |
|   1002 | Pooja  | 28000.00 |
|   1003 | Kiran  |  7000.00 |
+--------+--------+----------+
3 rows in set
```

**Why this output is correct:** Needs a server restart; follow DURABILITY.md (steps + real captured output). InnoDB writes the redo log at COMMIT (innodb_flush_log_at_trx_commit = 1), so after a crash/restart the committed transfer is replayed from the redo log.

### Task 12 - Drop a trigger and show that logging stops

```sql
SELECT COUNT(*) AS log_rows_before FROM Txn_Log;
DROP TRIGGER trg_account_log;
CALL deposit(1001, 100);
SELECT COUNT(*) AS log_rows_after FROM Txn_Log;
SHOW TRIGGERS;
```

**Output**

```text
SELECT COUNT(*) AS log_rows_before FROM Txn_Log

+-----------------+
| log_rows_before |
+-----------------+
|               4 |
+-----------------+
1 row in set

DROP TRIGGER trg_account_log

Query OK, 0 rows affected

CALL deposit(1001, 100)

Query OK, 1 row affected

SELECT COUNT(*) AS log_rows_after FROM Txn_Log

+----------------+
| log_rows_after |
+----------------+
|              4 |
+----------------+
1 row in set

SHOW TRIGGERS

+-------------------------+--------+---------+-------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| Trigger                 | Event  | Table   | Statement                                                                                                                                 | Timing | Created                | sql_mode                                                                                                              | Definer        | character_set_client | collation_connection | Database Collation |
+-------------------------+--------+---------+-------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| trg_account_min_balance | UPDATE | account | BEGIN
    IF NEW.balance < 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Balance cannot fall below 1000';
    END IF;
END | BEFORE | 2026-10-30 10:42:15.68 | ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION | root@localhost | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+-------------------------+--------+---------+-------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** After DROP TRIGGER trg_account_log, balance updates still work but Txn_Log no longer grows. (Remember to re-create the trigger if you continue the experiment.)


## Advanced / examiner-style queries

### Adv 1 - Re-create the logging trigger and prove it works again

```sql
DELIMITER $$
CREATE TRIGGER trg_account_log AFTER UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance <> OLD.balance THEN
        INSERT INTO Txn_Log (acc_no, txn_type, amount) VALUES (NEW.acc_no, IF(NEW.balance < OLD.balance, 'Debit', 'Credit'), ABS(NEW.balance - OLD.balance));
    END IF;
END$$
DELIMITER ;
CALL deposit(1003, 50);
SELECT log_id, acc_no, txn_type, amount FROM Txn_Log ORDER BY log_id DESC LIMIT 2;
```

**Output**

```text
CREATE TRIGGER trg_account_log AFTER UPDATE ON Account FOR EACH ROW
BEGIN
    IF NEW.balance <> OLD.balance THEN
        INSERT INTO Txn_Log (acc_no, txn_type, amount) VALUES (NEW.acc_no, IF(NEW.balance < OLD.balance, 'Debit', 'Credit'), ABS(NEW.balance - OLD.balance));
    END IF;
END

Query OK, 0 rows affected

CALL deposit(1003, 50)

Query OK, 1 row affected

SELECT log_id, acc_no, txn_type, amount FROM Txn_Log ORDER BY log_id DESC LIMIT 2

+--------+--------+----------+---------+
| log_id | acc_no | txn_type | amount  |
+--------+--------+----------+---------+
|      8 |   1003 | Credit   |   50.00 |
|      7 |   1003 | Credit   | 2000.00 |
+--------+--------+----------+---------+
2 rows in set
```

### Adv 2 - Invalid transfers - same account, negative amount, unknown source

```sql
CALL transfer_funds(1001, 1001, 100);
CALL transfer_funds(1001, 1002, -5);
CALL transfer_funds(7777, 1002, 100);
```

**Output**

```text
CALL transfer_funds(1001, 1001, 100)

ERROR 1644 (45000) at line 1: Invalid transfer request
CALL transfer_funds(1001, 1002, -5)

ERROR 1644 (45000) at line 2: Invalid transfer request
CALL transfer_funds(7777, 1002, 100)

ERROR 1644 (45000) at line 3: Source account not found
```

**Why this output is correct:** Each call fails with the message set by SIGNAL and changes nothing.

### Adv 3 - Transfer to a non-existent destination is rolled back (debit undone)

```sql
SELECT balance AS balance_before FROM Account WHERE acc_no = 1001;
CALL transfer_funds(1001, 9999, 100);
SELECT balance AS balance_after FROM Account WHERE acc_no = 1001;
```

**Output**

```text
SELECT balance AS balance_before FROM Account WHERE acc_no = 1001

+----------------+
| balance_before |
+----------------+
|       40100.00 |
+----------------+
1 row in set

CALL transfer_funds(1001, 9999, 100)

ERROR 1644 (45000) at line 2: Destination account not found
SELECT balance AS balance_after FROM Account WHERE acc_no = 1001

+---------------+
| balance_after |
+---------------+
|      40100.00 |
+---------------+
1 row in set
```

**Why this output is correct:** The credit UPDATE touches 0 rows -> SIGNAL -> handler ROLLBACK, so the already executed debit is undone.

### Adv 4 - Consistency check - total money in the bank never changes by a transfer

```sql
SELECT SUM(balance) AS total_before FROM Account;
CALL transfer_funds(1001, 1002, 500);
SELECT SUM(balance) AS total_after FROM Account;
```

**Output**

```text
SELECT SUM(balance) AS total_before FROM Account

+--------------+
| total_before |
+--------------+
|     75150.00 |
+--------------+
1 row in set

CALL transfer_funds(1001, 1002, 500)

Query OK, 0 rows affected

SELECT SUM(balance) AS total_after FROM Account

+-------------+
| total_after |
+-------------+
|    75150.00 |
+-------------+
1 row in set
```

### Adv 5 - Function in a WHERE clause

```sql
SELECT holder FROM Account WHERE get_balance(acc_no) > 30000;
```

**Output**

```text
SELECT holder FROM Account WHERE get_balance(acc_no) > 30000

+--------+
| holder |
+--------+
| Rahul  |
+--------+
1 row in set
```

### Adv 6 - Net movement per account from the log

```sql
SELECT acc_no, SUM(IF(txn_type = 'Credit', amount, -amount)) AS net FROM Txn_Log GROUP BY acc_no;
```

**Output**

```text
SELECT acc_no, SUM(IF(txn_type = 'Credit', amount, -amount)) AS net FROM Txn_Log GROUP BY acc_no

+--------+-----------+
| acc_no | net       |
+--------+-----------+
|   1001 | -10500.00 |
|   1002 |   8500.00 |
|   1003 |   2050.00 |
+--------+-----------+
3 rows in set
```


## Multi-session demonstration (`run_demo.py`, real connections)

> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.

admin> CREATE PROCEDURE transfer_funds(IN from_acc INT, IN to_acc INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT balance INTO v_bal FROM Account WHERE acc_no = from_acc FOR UPDATE;
    IF v_bal - amt < 1000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance'; END IF;
    UPDATE Account SET balance = balance - amt WHERE acc_no = from_acc;
    UPDATE Account SET balance = balance + amt WHERE acc_no = to_acc;
    COMMIT;
END
OK

#### Task 10 - Isolation: S1 changes balances but has not committed; S2 reads / writes

-- Plain statements instead of CALL transfer_funds are used so that S1 can stay inside an open transaction.
S1> START TRANSACTION
OK
S1> UPDATE Account SET balance = balance - 10000 WHERE acc_no = 1001
OK, 1 row affected
S1> UPDATE Account SET balance = balance + 10000 WHERE acc_no = 1002
OK, 1 row affected
S1> SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)
+--------+----------+
| acc_no | balance  |
+--------+----------+
|   1001 | 40000.00 |
|   1002 | 30000.00 |
+--------+----------+
2 rows in set
-- S1 sees its own uncommitted changes. S2 (default REPEATABLE READ) still sees the OLD, committed balances:
S2> START TRANSACTION
OK
S2> SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)
+--------+----------+
| acc_no | balance  |
+--------+----------+
|   1001 | 50000.00 |
|   1002 | 20000.00 |
+--------+----------+
2 rows in set
-- S2 tries to modify the row S1 has locked: it has to wait.
S2> UPDATE Account SET balance = balance + 1 WHERE acc_no = 1001
   [STILL RUNNING - blocked, waiting for a lock]
S1> COMMIT
OK
S2> (the blocked statement finishes)
OK, 1 row affected
S2> COMMIT
OK
S2> SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)
+--------+----------+
| acc_no | balance  |
+--------+----------+
|   1001 | 40001.00 |
|   1002 | 30000.00 |
+--------+----------+
2 rows in set
-- After S1's COMMIT the new balances are visible (and S2's waiting UPDATE added 1 to account 1001).
| Step | S1 | S2 |
|---|---|---|
| 1 | START TRANSACTION |  |
| 2 | UPDATE Account SET balance = balance - 10000 WHERE acc_no = 1001 |  |
| 3 | UPDATE Account SET balance = balance + 10000 WHERE acc_no = 1002 |  |
| 4 | SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002) |  |
| 5 |  | START TRANSACTION |
| 6 |  | SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002) |
| 7 |  | UPDATE Account SET balance = balance + 1 WHERE acc_no = 1001 |
| 8 | COMMIT |  |
| 9 |  | COMMIT |
| 10 |  | SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002) |

#### Task 10b - Atomicity: a failed transfer leaves nothing behind (also seen from a second session)

S1> CALL transfer_funds(1003, 1001, 8000)
ERROR 1644 (45000): Insufficient balance
S2> SELECT acc_no, balance FROM Account
+--------+----------+
| acc_no | balance  |
+--------+----------+
|   1001 | 40001.00 |
|   1002 | 30000.00 |
|   1003 |  5000.00 |
+--------+----------+
3 rows in set
S2> SELECT COUNT(*) AS log_rows FROM Txn_Log
+----------+
| log_rows |
+----------+
|        0 |
+----------+
1 row in set

(session scripts written)

-- Experiment 4A - Bank transfer : 12 tasks.  Tasks 10 and 11 need several sessions: see run_demo.py / session*.sql / DURABILITY.md
/* @CONCEPTS
* **Trigger**: code that fires automatically BEFORE/AFTER INSERT, UPDATE or DELETE on a table; `NEW` / `OLD` give the new / old row.
* **SIGNAL SQLSTATE '45000'** raises a user-defined error and aborts the statement (and the trigger's triggering statement).
* **Stored procedure** (`CALL`, IN/OUT parameters) vs **stored function** (returns one value, usable inside SELECT). Functions need `READS SQL DATA` (or DETERMINISTIC / NO SQL) when binary logging is on.
* **Transaction**: START TRANSACTION ... COMMIT / ROLLBACK. An `EXIT HANDLER FOR SQLEXCEPTION` that does ROLLBACK + RESIGNAL makes the procedure all-or-nothing.
* **ACID**: Atomicity (rollback of half a transfer), Consistency (CHECK/trigger/min balance), Isolation (other sessions do not see uncommitted data), Durability (committed data survives a crash/restart - InnoDB redo log).
* Oracle PL/SQL differences: `CREATE OR REPLACE TRIGGER ... :NEW.balance`, `RAISE_APPLICATION_ERROR(-20001, 'msg')`, `EXCEPTION WHEN OTHERS THEN ROLLBACK`.
*/

-- ### TASK 1: Create Account and Txn_Log and insert the data
-- Tables and rows were created by 01_schema.sql / 02_sample_data.sql; Txn_Log is empty.
SELECT * FROM Account;
SELECT COUNT(*) AS log_rows FROM Txn_Log;

-- ### TASK 2: AFTER UPDATE trigger that logs every balance change (Debit / Credit)
-- Fires after each UPDATE of Account; compares OLD.balance and NEW.balance and inserts the difference with the direction.
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

-- ### TASK 3: BEFORE UPDATE trigger that blocks a balance below 1000
-- SIGNAL raises SQLSTATE 45000 with a message; the UPDATE is cancelled and nothing is logged.
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

-- ### TASK 4: Procedures deposit(acc, amt) and withdraw(acc, amt)
-- Both validate the amount and the account; the min-balance trigger from Task 3 protects withdraw. Tested inside a transaction that is rolled back,
-- so the PDF's starting balances are unchanged (note: AUTO_INCREMENT values used by the rolled-back log rows are NOT given back - gaps in log_id are normal).
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

-- ### TASK 5: transfer_funds(IN from_acc, IN to_acc, IN amt) inside START TRANSACTION ... COMMIT, ROLLBACK if insufficient
-- SELECT ... FOR UPDATE locks the source row. If funds are short we SIGNAL; the EXIT HANDLER rolls back and re-raises the error to the caller.
-- "Insufficient" also covers the 1000 minimum balance rule (balance after debit must stay >= 1000).
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

-- ### TASK 6: Call transfer_funds(1001, 1002, 10000) and show both tables
-- 1001: 50000 -> 40000, 1002: 20000 -> 30000. The AFTER UPDATE trigger logs one Debit and one Credit of 10000.
-- log_id starts at 4 and not 1 because ids 1-3 were consumed by log rows of the rolled-back tests in Tasks 2 and 4 (AUTO_INCREMENT is never rolled back).
CALL transfer_funds(1001, 1002, 10000);
SELECT * FROM Account;
SELECT log_id, acc_no, txn_type, amount FROM Txn_Log;

-- ### TASK 7: transfer_funds(1003, 1001, 8000) - rollback, balances unchanged (atomicity, consistency)
-- Kiran has 5000; 5000 - 8000 < 1000, so the procedure signals "Insufficient balance" and the handler ROLLBACKs. Nothing changes and nothing is logged.
CALL transfer_funds(1003, 1001, 8000);
SELECT * FROM Account;
SELECT COUNT(*) AS log_rows_after_failed_transfer FROM Txn_Log;

-- ### TASK 8: Function get_balance(acc) and its use in SELECT
-- A function returns one scalar and can be used in any expression. READS SQL DATA tells MySQL it only reads tables.
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

-- ### TASK 9: Procedure mini_statement(acc) - last 5 transactions
-- ORDER BY log_id DESC LIMIT 5 returns the newest entries first.
DELIMITER $$
CREATE PROCEDURE mini_statement(IN p_acc INT)
BEGIN
    SELECT log_id, txn_type, amount, txn_time FROM Txn_Log WHERE acc_no = p_acc ORDER BY log_id DESC LIMIT 5;
END$$
DELIMITER ;
CALL mini_statement(1001);
CALL mini_statement(1002);

-- ### TASK 10: Isolation - transfer in one session, read from another before COMMIT
-- Needs two real connections, therefore executed by run_demo.py (see the "Multi-session demonstration" section further down this file and session1.sql / session2.sql).
-- Under REPEATABLE READ (default) S2 keeps seeing the OLD balances until S1 commits, and S2's UPDATE on the same row waits for S1's row lock.
SELECT 'see run_demo.py: Task 10' AS note;

-- ### TASK 11: Commit a transfer, restart the server, show it persists (durability)
-- Needs a server restart; follow DURABILITY.md (steps + real captured output). InnoDB writes the redo log at COMMIT (innodb_flush_log_at_trx_commit = 1),
-- so after a crash/restart the committed transfer is replayed from the redo log.
CALL transfer_funds(1002, 1003, 2000);
SELECT * FROM Account;

-- ### TASK 12: Drop a trigger and show that logging stops
-- After DROP TRIGGER trg_account_log, balance updates still work but Txn_Log no longer grows. (Remember to re-create the trigger if you continue the experiment.)
SELECT COUNT(*) AS log_rows_before FROM Txn_Log;
DROP TRIGGER trg_account_log;
CALL deposit(1001, 100);
SELECT COUNT(*) AS log_rows_after FROM Txn_Log;
SHOW TRIGGERS;

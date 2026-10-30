-- Experiment 4A - additional examiner-style queries (run after 03; the logging trigger was dropped in Task 12 so it is re-created here)
USE bank_4a;

-- ### ADV 1: Re-create the logging trigger and prove it works again
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

-- ### ADV 2: Invalid transfers - same account, negative amount, unknown source
-- Each call fails with the message set by SIGNAL and changes nothing.
CALL transfer_funds(1001, 1001, 100);
CALL transfer_funds(1001, 1002, -5);
CALL transfer_funds(7777, 1002, 100);

-- ### ADV 3: Transfer to a non-existent destination is rolled back (debit undone)
-- The credit UPDATE touches 0 rows -> SIGNAL -> handler ROLLBACK, so the already executed debit is undone.
SELECT balance AS balance_before FROM Account WHERE acc_no = 1001;
CALL transfer_funds(1001, 9999, 100);
SELECT balance AS balance_after FROM Account WHERE acc_no = 1001;

-- ### ADV 4: Consistency check - total money in the bank never changes by a transfer
SELECT SUM(balance) AS total_before FROM Account;
CALL transfer_funds(1001, 1002, 500);
SELECT SUM(balance) AS total_after FROM Account;

-- ### ADV 5: Function in a WHERE clause
SELECT holder FROM Account WHERE get_balance(acc_no) > 30000;

-- ### ADV 6: Net movement per account from the log
SELECT acc_no, SUM(IF(txn_type = 'Credit', amount, -amount)) AS net FROM Txn_Log GROUP BY acc_no;

-- 4A Bank transfer - Task 10: script for session S2 (open a separate terminal: mysql -u root -p bank_4a)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S1
-- step 2: run in S1
-- step 3: run in S1
-- step 4: run in S1
-- step 5
START TRANSACTION;
-- step 6
SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002);
-- step 7  (this statement will BLOCK until the other session releases its lock)
UPDATE Account SET balance = balance + 1 WHERE acc_no = 1001;
-- step 8: run in S1
-- step 9
COMMIT;
-- step 10
SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002);
-- step 11: run in S1
-- step 12
SELECT acc_no, balance FROM Account;
-- step 13
SELECT COUNT(*) AS log_rows FROM Txn_Log;

-- 4A Bank transfer - Task 10: script for session S1 (open a separate terminal: mysql -u root -p bank_4a)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1
START TRANSACTION;
-- step 2
UPDATE Account SET balance = balance - 10000 WHERE acc_no = 1001;
-- step 3
UPDATE Account SET balance = balance + 10000 WHERE acc_no = 1002;
-- step 4
SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002);
-- step 5: run in S2
-- step 6: run in S2
-- step 7: run in S2
-- step 8
COMMIT;
-- step 9: run in S2
-- step 10: run in S2
-- step 11
CALL transfer_funds(1003, 1001, 8000);
-- step 12: run in S2
-- step 13: run in S2

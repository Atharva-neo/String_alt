-- 5C Deadlock: script for session S2 (open a separate terminal: mysql -u root -p deadlock_5c)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S1
-- step 2
START TRANSACTION;
-- step 3: run in S1
-- step 4
UPDATE Account SET balance = balance - 300 WHERE acc_no = 2;
-- step 5: run in S1
-- step 6
UPDATE Account SET balance = balance + 300 WHERE acc_no = 1;
-- step 7: run in S1
-- step 8
COMMIT;
-- step 9: run in S1
-- step 10
START TRANSACTION;
-- step 11: run in S1
-- step 12  (this statement will BLOCK until the other session releases its lock)
UPDATE Account SET balance = balance - 300 WHERE acc_no = 1;
-- step 13: run in S1
-- step 14: run in S1
-- step 15
UPDATE Account SET balance = balance + 300 WHERE acc_no = 2;
-- step 16
COMMIT;
-- step 17: run in S1
-- step 18: run in S1
-- step 19: run in S1
-- step 20  (this statement will BLOCK until the other session releases its lock)
CALL transfer_retry(1, 2, 100, @attempts);
-- step 21: run in S1
-- step 22: run in S1
-- step 23
SELECT @attempts AS attempts_used;
-- step 24: run in S1
-- step 25
START TRANSACTION;
-- step 26: run in S3
-- step 27: run in S1
-- step 28: run in S1
-- step 29
UPDATE Account SET balance = balance - 1 WHERE acc_no = 2;
-- step 30
UPDATE Account SET balance = balance - 1 WHERE acc_no = 2;
-- step 31: run in S3
-- step 32: run in S1
-- step 33  (this statement will BLOCK until the other session releases its lock)
UPDATE Account SET balance = balance + 1 WHERE acc_no = 3;
-- step 34: run in S3
-- step 35: run in S3
-- step 36
COMMIT;
-- step 37: run in S1

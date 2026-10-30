-- 5C Deadlock: script for session S1 (open a separate terminal: mysql -u root -p deadlock_5c)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1
START TRANSACTION;
-- step 2: run in S2
-- step 3
UPDATE Account SET balance = balance - 500 WHERE acc_no = 1;
-- step 4: run in S2
-- step 5  (this statement will BLOCK until the other session releases its lock)
UPDATE Account SET balance = balance + 500 WHERE acc_no = 2;
-- step 6: run in S2
-- step 7
COMMIT;
-- step 8: run in S2
-- step 9
START TRANSACTION;
-- step 10: run in S2
-- step 11
UPDATE Account SET balance = balance - 500 WHERE acc_no = 1;
-- step 12: run in S2
-- step 13
UPDATE Account SET balance = balance + 500 WHERE acc_no = 2;
-- step 14
COMMIT;
-- step 15: run in S2
-- step 16: run in S2
-- step 17
START TRANSACTION;
-- step 18
UPDATE Account SET balance = balance - 100 WHERE acc_no = 2;
-- step 19
UPDATE Account SET balance = balance - 100 WHERE acc_no = 2;
-- step 20: run in S2
-- step 21
UPDATE Account SET balance = balance + 200 WHERE acc_no = 1;
-- step 22
COMMIT;
-- step 23: run in S2
-- step 24
START TRANSACTION;
-- step 25: run in S2
-- step 26: run in S3
-- step 27
UPDATE Account SET balance = balance - 1 WHERE acc_no = 1;
-- step 28
UPDATE Account SET balance = balance - 1 WHERE acc_no = 1;
-- step 29: run in S2
-- step 30: run in S2
-- step 31: run in S3
-- step 32  (this statement will BLOCK until the other session releases its lock)
UPDATE Account SET balance = balance + 1 WHERE acc_no = 2;
-- step 33: run in S2
-- step 34: run in S3
-- step 35: run in S3
-- step 36: run in S2
-- step 37
COMMIT;

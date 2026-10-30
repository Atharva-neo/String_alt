-- 5C Deadlock: script for session S3 (open a separate terminal: mysql -u root -p deadlock_5c)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S1
-- step 2: run in S2
-- step 3: run in S1
-- step 4: run in S2
-- step 5: run in S1
-- step 6: run in S2
-- step 7: run in S1
-- step 8: run in S2
-- step 9: run in S1
-- step 10: run in S2
-- step 11: run in S1
-- step 12: run in S2
-- step 13: run in S1
-- step 14: run in S1
-- step 15: run in S2
-- step 16: run in S2
-- step 17: run in S1
-- step 18: run in S1
-- step 19: run in S1
-- step 20: run in S2
-- step 21: run in S1
-- step 22: run in S1
-- step 23: run in S2
-- step 24: run in S1
-- step 25: run in S2
-- step 26
START TRANSACTION;
-- step 27: run in S1
-- step 28: run in S1
-- step 29: run in S2
-- step 30: run in S2
-- step 31
UPDATE Account SET balance = balance - 1 WHERE acc_no = 3;
-- step 32: run in S1
-- step 33: run in S2
-- step 34
UPDATE Account SET balance = balance + 1 WHERE acc_no = 1;
-- step 35
COMMIT;
-- step 36: run in S2
-- step 37: run in S1

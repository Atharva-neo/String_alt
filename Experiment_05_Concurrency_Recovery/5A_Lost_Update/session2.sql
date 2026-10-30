-- 5A Lost update: script for session S2 (open a separate terminal: mysql -u root -p stock_5a)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S1
-- step 2
SET autocommit = 0;
-- step 3: run in S1
-- step 4: run in S1
-- step 5
SELECT @@transaction_isolation AS isolation;
-- step 6: run in S1
-- step 7
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- step 8: run in S1
-- step 9
START TRANSACTION;
-- step 10: run in S1
-- step 11
SELECT qty FROM Stock WHERE item_id = 1;
-- step 12: run in S1
-- step 13  (this statement will BLOCK until the other session releases its lock)
UPDATE Stock SET qty = 50 WHERE item_id = 1;
-- step 14: run in S1
-- step 15
COMMIT;
-- step 16: run in S1
-- step 17
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 18: run in S1
-- step 19
START TRANSACTION;
-- step 20: run in S1
-- step 21  (this statement will BLOCK until the other session releases its lock)
SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE;
-- step 22: run in S1
-- step 23: run in S1
-- step 24
UPDATE Stock SET qty = 20 WHERE item_id = 1;
-- step 25
COMMIT;
-- step 26: run in S1
-- step 27
START TRANSACTION;
-- step 28: run in S1
-- step 29  (this statement will BLOCK until the other session releases its lock)
UPDATE Stock SET qty = qty - 50 WHERE item_id = 1;
-- step 30: run in S1
-- step 31
COMMIT;
-- step 32: run in S1
-- step 33
START TRANSACTION;
-- step 34: run in S1
-- step 35
SELECT qty FROM Stock WHERE item_id = 1;
-- step 36  (this statement will BLOCK until the other session releases its lock)
UPDATE Stock SET qty = qty - 1 WHERE item_id = 1;
-- step 37: run in S1
-- step 38
ROLLBACK;
-- step 39: run in S1
-- step 40: run in S1
-- step 41  (this statement will BLOCK until the other session releases its lock)
SELECT qty FROM Stock WHERE item_id = 1;
-- step 42: run in S1
-- step 43: run in S1
-- step 44
COMMIT;
-- step 45: run in S1
-- step 46: run in S1
-- step 47: run in S1
-- step 48
SELECT qty FROM Stock WHERE item_id = 1;
-- step 49  (this statement will BLOCK until the other session releases its lock)
UPDATE Stock SET qty = qty - 1 WHERE item_id = 1;
-- step 50: run in S1
-- step 51
ROLLBACK;
-- step 52: run in S1
-- step 53: run in S1
-- step 54
SET SESSION innodb_lock_wait_timeout = 2;
-- step 55
SELECT @@innodb_lock_wait_timeout AS timeout_seconds;
-- step 56
START TRANSACTION;
-- step 57
UPDATE Stock SET qty = qty - 2 WHERE item_id = 1;
-- step 58: run in S1
-- step 59
ROLLBACK;

-- 5A Lost update: script for session S1 (open a separate terminal: mysql -u root -p stock_5a)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1
SET autocommit = 0;
-- step 2: run in S2
-- step 3
SELECT @@autocommit AS autocommit;
-- step 4
SELECT @@transaction_isolation AS isolation;
-- step 5: run in S2
-- step 6
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- step 7: run in S2
-- step 8
START TRANSACTION;
-- step 9: run in S2
-- step 10
SELECT qty FROM Stock WHERE item_id = 1;
-- step 11: run in S2
-- step 12
UPDATE Stock SET qty = 70 WHERE item_id = 1;
-- step 13: run in S2
-- step 14
COMMIT;
-- step 15: run in S2
-- step 16
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 17: run in S2
-- step 18
START TRANSACTION;
-- step 19: run in S2
-- step 20
SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE;
-- step 21: run in S2
-- step 22
UPDATE Stock SET qty = 70 WHERE item_id = 1;
-- step 23
COMMIT;
-- step 24: run in S2
-- step 25: run in S2
-- step 26
START TRANSACTION;
-- step 27: run in S2
-- step 28
UPDATE Stock SET qty = qty - 30 WHERE item_id = 1;
-- step 29: run in S2
-- step 30
COMMIT;
-- step 31: run in S2
-- step 32
START TRANSACTION;
-- step 33: run in S2
-- step 34
SELECT qty FROM Stock WHERE item_id = 1 LOCK IN SHARE MODE;
-- step 35: run in S2
-- step 36: run in S2
-- step 37
COMMIT;
-- step 38: run in S2
-- step 39
LOCK TABLES Stock WRITE;
-- step 40
UPDATE Stock SET qty = qty - 30 WHERE item_id = 1;
-- step 41: run in S2
-- step 42
COMMIT;
-- step 43
UNLOCK TABLES;
-- step 44: run in S2
-- step 45
LOCK TABLES Stock READ;
-- step 46
SELECT qty FROM Stock WHERE item_id = 1;
-- step 47
UPDATE Stock SET qty = qty - 1 WHERE item_id = 1;
-- step 48: run in S2
-- step 49: run in S2
-- step 50
UNLOCK TABLES;
-- step 51: run in S2
-- step 52
START TRANSACTION;
-- step 53
UPDATE Stock SET qty = qty - 1 WHERE item_id = 1;
-- step 54: run in S2
-- step 55: run in S2
-- step 56: run in S2
-- step 57: run in S2
-- step 58
ROLLBACK;
-- step 59: run in S2

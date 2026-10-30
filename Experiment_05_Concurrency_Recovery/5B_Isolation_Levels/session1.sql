-- 5B Isolation levels: script for session S1 (open a separate terminal: mysql -u root -p seats_5b)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1
SELECT @@transaction_isolation AS isolation;
-- step 2: run in S2
-- step 3
START TRANSACTION;
-- step 4
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1';
-- step 5: run in S2
-- step 6: run in S2
-- step 7
ROLLBACK;
-- step 8: run in S2
-- step 9: run in S2
-- step 10: run in S2
-- step 11
START TRANSACTION;
-- step 12
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1';
-- step 13: run in S2
-- step 14: run in S2
-- step 15
ROLLBACK;
-- step 16: run in S2
-- step 17: run in S2
-- step 18: run in S2
-- step 19: run in S2
-- step 20
START TRANSACTION;
-- step 21
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2';
-- step 22
COMMIT;
-- step 23: run in S2
-- step 24: run in S2
-- step 25: run in S2
-- step 26: run in S2
-- step 27: run in S2
-- step 28
START TRANSACTION;
-- step 29
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2';
-- step 30
COMMIT;
-- step 31: run in S2
-- step 32: run in S2
-- step 33: run in S2
-- step 34: run in S2
-- step 35: run in S2
-- step 36: run in S2
-- step 37: run in S2
-- step 38
START TRANSACTION;
-- step 39
INSERT INTO Seats VALUES ('A4', 'Free');
-- step 40
COMMIT;
-- step 41: run in S2
-- step 42: run in S2
-- step 43: run in S2
-- step 44: run in S2
-- step 45: run in S2
-- step 46: run in S2
-- step 47
START TRANSACTION;
-- step 48
INSERT INTO Seats VALUES ('A4', 'Free');
-- step 49
COMMIT;
-- step 50: run in S2
-- step 51: run in S2
-- step 52: run in S2
-- step 53: run in S2
-- step 54: run in S2
-- step 55
START TRANSACTION;
-- step 56  (this statement will BLOCK until the other session releases its lock)
INSERT INTO Seats VALUES ('A4', 'Free');
-- step 57: run in S2
-- step 58: run in S2
-- step 59
COMMIT;
-- step 60
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 61: run in S2
-- step 62
START TRANSACTION;
-- step 63
SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE;
-- step 64: run in S2
-- step 65: run in S2
-- step 66
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2';
-- step 67
COMMIT;
-- step 68: run in S2
-- step 69: run in S2
-- step 70: run in S2
-- step 71
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- step 72: run in S2
-- step 73
SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level;
-- step 74: run in S2
-- step 75: run in S3

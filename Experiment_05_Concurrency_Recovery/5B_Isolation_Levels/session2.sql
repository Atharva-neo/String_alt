-- 5B Isolation levels: script for session S2 (open a separate terminal: mysql -u root -p seats_5b)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S1
-- step 2
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- step 3: run in S1
-- step 4: run in S1
-- step 5
START TRANSACTION;
-- step 6
SELECT seat_no, status FROM Seats WHERE seat_no = 'A1';
-- step 7: run in S1
-- step 8
SELECT seat_no, status FROM Seats WHERE seat_no = 'A1';
-- step 9
COMMIT;
-- step 10
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- step 11: run in S1
-- step 12: run in S1
-- step 13
START TRANSACTION;
-- step 14
SELECT seat_no, status FROM Seats WHERE seat_no = 'A1';
-- step 15: run in S1
-- step 16
COMMIT;
-- step 17
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- step 18
START TRANSACTION;
-- step 19
SELECT seat_no, status FROM Seats WHERE seat_no = 'A2';
-- step 20: run in S1
-- step 21: run in S1
-- step 22: run in S1
-- step 23
SELECT seat_no, status FROM Seats WHERE seat_no = 'A2';
-- step 24
COMMIT;
-- step 25
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 26
START TRANSACTION;
-- step 27
SELECT seat_no, status FROM Seats WHERE seat_no = 'A2';
-- step 28: run in S1
-- step 29: run in S1
-- step 30: run in S1
-- step 31
SELECT seat_no, status FROM Seats WHERE seat_no = 'A2';
-- step 32
COMMIT;
-- step 33
SELECT seat_no, status FROM Seats WHERE seat_no = 'A2';
-- step 34
COMMIT;
-- step 35
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 36
START TRANSACTION;
-- step 37
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 38: run in S1
-- step 39: run in S1
-- step 40: run in S1
-- step 41
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 42
SELECT COUNT(*) AS free_seats_locking_read FROM Seats WHERE status = 'Free' FOR UPDATE;
-- step 43
COMMIT;
-- step 44
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- step 45
START TRANSACTION;
-- step 46
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 47: run in S1
-- step 48: run in S1
-- step 49: run in S1
-- step 50
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 51
COMMIT;
-- step 52
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- step 53
START TRANSACTION;
-- step 54
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 55: run in S1
-- step 56: run in S1
-- step 57
SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free';
-- step 58
COMMIT;
-- step 59: run in S1
-- step 60: run in S1
-- step 61
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 62: run in S1
-- step 63: run in S1
-- step 64
START TRANSACTION;
-- step 65  (this statement will BLOCK until the other session releases its lock)
SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE;
-- step 66: run in S1
-- step 67: run in S1
-- step 68
ROLLBACK;
-- step 69
UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2' AND status = 'Free';
-- step 70
ROLLBACK;
-- step 71: run in S1
-- step 72
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- step 73: run in S1
-- step 74
SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level;
-- step 75: run in S3

-- Experiment 6D - additional examiner-style queries (run after 03)
USE login_6d;

-- ### ADV 1: Why unsalted SHA-256 is weak - and a salted variant
-- Two users with the same password get the SAME hash (visible to anybody who can read the table and crackable with rainbow tables). A random per-user salt
-- makes equal passwords look different. (Production: bcrypt/Argon2 in the application, not SHA-256.)
SELECT SHA2('Same@1234', 256) = SHA2('Same@1234', 256) AS unsalted_equal;
SET @salt1 = HEX(RANDOM_BYTES(8)), @salt2 = HEX(RANDOM_BYTES(8));
SELECT SHA2(CONCAT(@salt1, 'Same@1234'), 256) = SHA2(CONCAT(@salt2, 'Same@1234'), 256) AS salted_equal;

-- ### ADV 2: Users who never logged in successfully
SELECT u.username FROM App_User u WHERE NOT EXISTS (SELECT 1 FROM Login_Log l WHERE l.username = u.username AND l.status = 'Success');

-- ### ADV 3: Locked accounts
SELECT username, failed_attempts FROM App_User WHERE is_locked = 1;

-- ### ADV 4: Failed attempts per day
SELECT DATE(login_time) AS day, COUNT(*) AS failed FROM Login_Log WHERE status = 'Failed' GROUP BY DATE(login_time);

-- ### ADV 5: Duplicate username through direct INSERT
-- Error 1062 (uq_app_user_username) - the UNIQUE constraint backs up register().
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Whatever@1', 256), 'admin');

-- ### ADV 6: Invalid role
-- Error 3819 (chk_app_user_role).
INSERT INTO App_User (username, password_hash, role) VALUES ('zed', SHA2('Zed@12345', 256), 'superuser');

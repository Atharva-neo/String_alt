-- Experiment 6D - Login module : 12 tasks
/* @CONCEPTS
* Passwords are never stored: the table keeps `SHA2(password, 256)` (64 hex characters). To log in, hash the typed password and compare the hashes.
* **Caveat (important for the viva):** plain unsalted SHA-256 is what the PDF asks for and is fine for the exercise, but real systems use a per-user salt and a slow password hash (bcrypt, scrypt, Argon2) - see ADV 1. Never send a password through SQL logs in production.
* **Account locking**: `failed_attempts` counts consecutive failures, `is_locked = 1` after 3, a success resets the counter, an administrator unlocks.
* **Audit**: every attempt is written to `Login_Log` (Success / Failed / Locked); unknown usernames get the same generic message as wrong passwords so the login form does not reveal which usernames exist.
* **Least privilege**: application code gets `EXECUTE` on procedures only; nobody gets SELECT on `password_hash` (column privileges grant the harmless columns).
* Procedures are `SQL SECURITY DEFINER` (default): they run with the owner's rights, so a clerk can call `login` without any right on App_User.
*/

-- ### TASK 1: Create App_User (username UNIQUE) and Login_Log
CREATE TABLE App_User (
    user_id         INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(30) NOT NULL,
    password_hash   CHAR(64)    NOT NULL,
    role            VARCHAR(10) NOT NULL,
    failed_attempts INT         NOT NULL DEFAULT 0,
    is_locked       TINYINT     NOT NULL DEFAULT 0,
    CONSTRAINT uq_app_user_username UNIQUE (username),
    CONSTRAINT chk_app_user_role CHECK (role IN ('admin', 'clerk'))
) ENGINE=InnoDB;
CREATE TABLE Login_Log (
    log_id     INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(30) NOT NULL,
    login_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status     VARCHAR(10) NOT NULL,
    CONSTRAINT chk_login_status CHECK (status IN ('Success', 'Failed', 'Locked'))
) ENGINE=InnoDB;
DESCRIBE App_User;
DESCRIBE Login_Log;

-- ### TASK 2: Insert the users storing SHA-256 hashes; show the stored hash
-- SHA2('Admin@123', 256) is computed by the server; only the 64-character digest is stored, the plain password is nowhere in the table.
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Admin@123', 256), 'admin'), ('ravi', SHA2('Ravi@123', 256), 'clerk');
SELECT user_id, username, password_hash, CHAR_LENGTH(password_hash) AS hash_length, role, failed_attempts, is_locked FROM App_User;

-- ### TASK 3: Procedure register(uname, pwd, role): reject duplicate usernames and passwords shorter than 8 characters
-- Validation order: username present, password length, role, duplicate. The EXIT HANDLER for error 1062 turns a race-condition duplicate (two sessions at once) into the same friendly message.
DELIMITER $$
CREATE PROCEDURE register(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), IN p_role VARCHAR(10))
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username already exists';
    IF p_user IS NULL OR TRIM(p_user) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username is required';
    END IF;
    IF p_pwd IS NULL OR CHAR_LENGTH(p_pwd) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must be at least 8 characters';
    END IF;
    IF p_role NOT IN ('admin', 'clerk') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Role must be admin or clerk';
    END IF;
    IF EXISTS (SELECT 1 FROM App_User WHERE username = p_user) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username already exists';
    END IF;
    INSERT INTO App_User (username, password_hash, role) VALUES (p_user, SHA2(p_pwd, 256), p_role);
END$$
DELIMITER ;
CALL register('meena', 'Meena@2026', 'clerk');
CALL register('ravi', 'Another@123', 'clerk');
CALL register('shorty', 'abc', 'clerk');
CALL register('tester', 'Tester@123', 'clerk');
CALL register('tester2', 'Tester@123', 'clerk');
SELECT user_id, username, role FROM App_User;

-- ### TASK 4: Procedure login(IN uname, IN pwd, OUT msg) that compares hashes
-- Version 1: only the comparison. SHA2(typed password) must equal the stored hash. Unknown user and wrong password give the same message.
DELIMITER $$
CREATE PROCEDURE login(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), OUT msg VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    SELECT password_hash INTO v_hash FROM App_User WHERE username = p_user;
    IF v_hash IS NOT NULL AND v_hash = SHA2(p_pwd, 256) THEN
        SET msg = 'Login successful';
    ELSE
        SET msg = 'Invalid username or password';
    END IF;
END$$
DELIMITER ;
CALL login('tester', 'Tester@123', @m); SELECT @m AS message;
CALL login('tester', 'wrong-pass', @m); SELECT @m AS message;
CALL login('nobody', 'Tester@123', @m); SELECT @m AS message;

-- ### TASK 5: On failure increment failed_attempts; set is_locked = 1 after 3 failures
-- Version 2 adds the failure counter and the lock. `is_locked = (n >= 3)` is evaluated in the same UPDATE. A locked account is refused even with the right password.
DROP PROCEDURE login;
DELIMITER $$
CREATE PROCEDURE login(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), OUT msg VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    DECLARE v_locked TINYINT;
    DECLARE v_fail INT;
    SELECT password_hash, is_locked, failed_attempts INTO v_hash, v_locked, v_fail FROM App_User WHERE username = p_user;
    IF v_hash IS NULL THEN
        SET msg = 'Invalid username or password';
    ELSEIF v_locked = 1 THEN
        SET msg = 'Account is locked. Contact the administrator';
    ELSEIF v_hash = SHA2(p_pwd, 256) THEN
        SET msg = 'Login successful';
    ELSE
        SET v_fail = v_fail + 1;
        UPDATE App_User SET failed_attempts = v_fail, is_locked = (v_fail >= 3) WHERE username = p_user;
        IF v_fail >= 3 THEN
            SET msg = 'Invalid credentials. Account locked after 3 failed attempts';
        ELSE
            SET msg = CONCAT('Invalid credentials. Attempts left: ', 3 - v_fail);
        END IF;
    END IF;
END$$
DELIMITER ;
CALL login('tester', 'bad1', @m); SELECT @m AS message;
CALL login('tester', 'bad2', @m); SELECT @m AS message;
CALL login('tester', 'bad3', @m); SELECT @m AS message;
CALL login('tester', 'Tester@123', @m); SELECT @m AS message_with_correct_password;
SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester';

-- ### TASK 6: Reset failed_attempts to 0 on a successful login
-- Version 3: the success branch also runs `UPDATE ... failed_attempts = 0`. tester2 fails twice (counter 2) and then logs in correctly: the counter returns to 0.
DROP PROCEDURE login;
DELIMITER $$
CREATE PROCEDURE login(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), OUT msg VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    DECLARE v_locked TINYINT;
    DECLARE v_fail INT;
    SELECT password_hash, is_locked, failed_attempts INTO v_hash, v_locked, v_fail FROM App_User WHERE username = p_user;
    IF v_hash IS NULL THEN
        SET msg = 'Invalid username or password';
    ELSEIF v_locked = 1 THEN
        SET msg = 'Account is locked. Contact the administrator';
    ELSEIF v_hash = SHA2(p_pwd, 256) THEN
        UPDATE App_User SET failed_attempts = 0 WHERE username = p_user;
        SET msg = 'Login successful';
    ELSE
        SET v_fail = v_fail + 1;
        UPDATE App_User SET failed_attempts = v_fail, is_locked = (v_fail >= 3) WHERE username = p_user;
        IF v_fail >= 3 THEN
            SET msg = 'Invalid credentials. Account locked after 3 failed attempts';
        ELSE
            SET msg = CONCAT('Invalid credentials. Attempts left: ', 3 - v_fail);
        END IF;
    END IF;
END$$
DELIMITER ;
CALL login('tester2', 'x1', @m); CALL login('tester2', 'x2', @m);
SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester2';
CALL login('tester2', 'Tester@123', @m); SELECT @m AS message;
SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester2';

-- ### TASK 7: Log every attempt (Success / Failed / Locked) into Login_Log
-- Final version 4: each branch inserts a Login_Log row; the whole procedure is one transaction (counter update and log row commit together).
-- The test users are removed afterwards so that Task 8 starts from the PDF data.
DROP PROCEDURE login;
DELIMITER $$
CREATE PROCEDURE login(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), OUT msg VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    DECLARE v_locked TINYINT;
    DECLARE v_fail INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SELECT password_hash, is_locked, failed_attempts INTO v_hash, v_locked, v_fail FROM App_User WHERE username = p_user FOR UPDATE;
    IF v_hash IS NULL THEN
        INSERT INTO Login_Log (username, status) VALUES (p_user, 'Failed');
        SET msg = 'Invalid username or password';
    ELSEIF v_locked = 1 THEN
        INSERT INTO Login_Log (username, status) VALUES (p_user, 'Locked');
        SET msg = 'Account is locked. Contact the administrator';
    ELSEIF v_hash = SHA2(p_pwd, 256) THEN
        UPDATE App_User SET failed_attempts = 0 WHERE username = p_user;
        INSERT INTO Login_Log (username, status) VALUES (p_user, 'Success');
        SET msg = 'Login successful';
    ELSE
        SET v_fail = v_fail + 1;
        UPDATE App_User SET failed_attempts = v_fail, is_locked = (v_fail >= 3) WHERE username = p_user;
        INSERT INTO Login_Log (username, status) VALUES (p_user, 'Failed');
        IF v_fail >= 3 THEN
            SET msg = 'Invalid credentials. Account locked after 3 failed attempts';
        ELSE
            SET msg = CONCAT('Invalid credentials. Attempts left: ', 3 - v_fail);
        END IF;
    END IF;
    COMMIT;
END$$
DELIMITER ;
CALL login('tester2', 'nope', @m); SELECT @m AS message;
CALL login('tester2', 'Tester@123', @m); SELECT @m AS message;
SELECT log_id, username, status FROM Login_Log;
DELETE FROM App_User WHERE username IN ('tester', 'tester2');
DELETE FROM Login_Log;

-- ### TASK 8: One successful login and three failed logins for ravi, then a locked response
-- success -> counter stays 0; wrong x3 -> counters 1, 2, 3 and the lock; the 4th attempt (even with the correct password) is answered with the locked message and logged as 'Locked'.
CALL login('ravi', 'Ravi@123', @m); SELECT @m AS attempt_1_correct;
CALL login('ravi', 'guess1', @m); SELECT @m AS attempt_2_wrong;
CALL login('ravi', 'guess2', @m); SELECT @m AS attempt_3_wrong;
CALL login('ravi', 'guess3', @m); SELECT @m AS attempt_4_wrong;
CALL login('ravi', 'Ravi@123', @m); SELECT @m AS attempt_5_correct_but_locked;
SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'ravi';
SELECT log_id, username, status FROM Login_Log;

-- ### TASK 9: Procedure change_password(uname, old_pwd, new_pwd)
-- The old password must match, the new one must be at least 8 characters and different, and a locked account cannot change it. Tested with meena.
DELIMITER $$
CREATE PROCEDURE change_password(IN p_user VARCHAR(30), IN p_old VARCHAR(100), IN p_new VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    DECLARE v_locked TINYINT;
    SELECT password_hash, is_locked INTO v_hash, v_locked FROM App_User WHERE username = p_user;
    IF v_hash IS NULL OR v_hash <> SHA2(p_old, 256) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid username or old password';
    END IF;
    IF v_locked = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account is locked';
    END IF;
    IF CHAR_LENGTH(p_new) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New password must be at least 8 characters';
    END IF;
    IF p_new = p_old THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New password must differ from the old one';
    END IF;
    UPDATE App_User SET password_hash = SHA2(p_new, 256) WHERE username = p_user;
END$$
DELIMITER ;
CALL change_password('meena', 'WrongOld1', 'Meena@2027');
CALL change_password('meena', 'Meena@2026', 'short');
CALL change_password('meena', 'Meena@2026', 'Meena@2026');
CALL change_password('meena', 'Meena@2026', 'Meena@2027');
CALL login('meena', 'Meena@2026', @m); SELECT @m AS old_password_now;
CALL login('meena', 'Meena@2027', @m); SELECT @m AS new_password;
CALL change_password('ravi', 'Ravi@123', 'Ravi@2027');

-- ### TASK 10: Login history of each user with counts of failed attempts
SELECT u.username, u.role, COALESCE(SUM(l.status = 'Success'), 0) AS successes, COALESCE(SUM(l.status = 'Failed'), 0) AS failures,
       COALESCE(SUM(l.status = 'Locked'), 0) AS locked_attempts, u.failed_attempts AS current_counter, u.is_locked
FROM App_User u LEFT JOIN Login_Log l ON l.username = u.username GROUP BY u.user_id, u.username, u.role, u.failed_attempts, u.is_locked ORDER BY u.user_id;
SELECT username, status, COUNT(*) AS times FROM Login_Log GROUP BY username, status ORDER BY username, status;

-- ### TASK 11: Procedure unlock_user(uname); GRANT EXECUTE on it only to a DB user with the admin role
-- unlock_user clears the lock and the counter. Roles: admin may EXECUTE every procedure and read the non-secret columns; clerk may only call login and change_password.
-- db_admin holds role admin, db_clerk holds role clerk.
DELIMITER $$
CREATE PROCEDURE unlock_user(IN p_user VARCHAR(30))
BEGIN
    UPDATE App_User SET is_locked = 0, failed_attempts = 0 WHERE username = p_user;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or already unlocked';
    END IF;
END$$
DELIMITER ;
DROP USER IF EXISTS 'db_admin'@'localhost';
DROP USER IF EXISTS 'db_clerk'@'localhost';
DROP ROLE IF EXISTS 'admin', 'clerk';
CREATE ROLE 'admin', 'clerk';
GRANT EXECUTE ON PROCEDURE login_6d.unlock_user      TO 'admin';
GRANT EXECUTE ON PROCEDURE login_6d.register         TO 'admin';
GRANT EXECUTE ON PROCEDURE login_6d.login            TO 'admin', 'clerk';
GRANT EXECUTE ON PROCEDURE login_6d.change_password  TO 'admin', 'clerk';
GRANT SELECT (user_id, username, role, failed_attempts, is_locked) ON login_6d.App_User TO 'admin';
GRANT SELECT (user_id, username, role) ON login_6d.App_User TO 'clerk';
GRANT SELECT ON login_6d.Login_Log TO 'admin';
CREATE USER 'db_admin'@'localhost' IDENTIFIED BY 'DbAdmin@12345';
CREATE USER 'db_clerk'@'localhost' IDENTIFIED BY 'DbClerk@12345';
GRANT 'admin' TO 'db_admin'@'localhost';
GRANT 'clerk' TO 'db_clerk'@'localhost';
SET DEFAULT ROLE 'admin' TO 'db_admin'@'localhost';
SET DEFAULT ROLE 'clerk' TO 'db_clerk'@'localhost';
SHOW GRANTS FOR 'db_admin'@'localhost' USING 'admin';
-- @as db_admin DbAdmin@12345
-- | CALL unlock_user('ravi');
-- | SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'ravi';
-- | SELECT password_hash FROM App_User;

-- ### TASK 12: The clerk DB user cannot execute unlock_user or SELECT password_hash
-- db_clerk may call login (works) but unlock_user gives ERROR 1370; reading the hash column gives ERROR 1143 (column privilege), while the harmless columns are readable.
SHOW GRANTS FOR 'db_clerk'@'localhost' USING 'clerk';
-- @as db_clerk DbClerk@12345
-- | CALL unlock_user('ravi');
-- | SELECT password_hash FROM App_User;
-- | SELECT * FROM App_User;
-- | SELECT user_id, username, role FROM App_User;
-- | CALL login('ravi', 'Ravi@123', @m);
-- | SELECT @m AS message;

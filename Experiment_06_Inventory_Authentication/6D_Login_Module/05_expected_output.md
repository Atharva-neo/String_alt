# Expected output - Experiment_06_Inventory_Authentication / 6D_Login_Module

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create App_User (username UNIQUE) and Login_Log

```sql
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
```

**Output**

```text
CREATE TABLE App_User (
    user_id         INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(30) NOT NULL,
    password_hash   CHAR(64)    NOT NULL,
    role            VARCHAR(10) NOT NULL,
    failed_attempts INT         NOT NULL DEFAULT 0,
    is_locked       TINYINT     NOT NULL DEFAULT 0,
    CONSTRAINT uq_app_user_username UNIQUE (username),
    CONSTRAINT chk_app_user_role CHECK (role IN ('admin', 'clerk'))
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Login_Log (
    log_id     INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(30) NOT NULL,
    login_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status     VARCHAR(10) NOT NULL,
    CONSTRAINT chk_login_status CHECK (status IN ('Success', 'Failed', 'Locked'))
) ENGINE=InnoDB

Query OK, 0 rows affected

DESCRIBE App_User

+-----------------+-------------+------+-----+---------+----------------+
| Field           | Type        | Null | Key | Default | Extra          |
+-----------------+-------------+------+-----+---------+----------------+
| user_id         | int         | NO   | PRI | NULL    | auto_increment |
| username        | varchar(30) | NO   | UNI | NULL    |                |
| password_hash   | char(64)    | NO   |     | NULL    |                |
| role            | varchar(10) | NO   |     | NULL    |                |
| failed_attempts | int         | NO   |     | 0       |                |
| is_locked       | tinyint     | NO   |     | 0       |                |
+-----------------+-------------+------+-----+---------+----------------+
6 rows in set

DESCRIBE Login_Log

+------------+-------------+------+-----+-------------------+-------------------+
| Field      | Type        | Null | Key | Default           | Extra             |
+------------+-------------+------+-----+-------------------+-------------------+
| log_id     | int         | NO   | PRI | NULL              | auto_increment    |
| username   | varchar(30) | NO   |     | NULL              |                   |
| login_time | datetime    | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| status     | varchar(10) | NO   |     | NULL              |                   |
+------------+-------------+------+-----+-------------------+-------------------+
4 rows in set
```

### Task 2 - Insert the users storing SHA-256 hashes; show the stored hash

```sql
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Admin@123', 256), 'admin'), ('ravi', SHA2('Ravi@123', 256), 'clerk');
SELECT user_id, username, password_hash, CHAR_LENGTH(password_hash) AS hash_length, role, failed_attempts, is_locked FROM App_User;
```

**Output**

```text
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Admin@123', 256), 'admin'), ('ravi', SHA2('Ravi@123', 256), 'clerk')

Query OK, 2 rows affected
Records: 2  Duplicates: 0  Warnings: 0

SELECT user_id, username, password_hash, CHAR_LENGTH(password_hash) AS hash_length, role, failed_attempts, is_locked FROM App_User

+---------+----------+------------------------------------------------------------------+-------------+-------+-----------------+-----------+
| user_id | username | password_hash                                                    | hash_length | role  | failed_attempts | is_locked |
+---------+----------+------------------------------------------------------------------+-------------+-------+-----------------+-----------+
|       1 | admin    | e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7 |          64 | admin |               0 |         0 |
|       2 | ravi     | a01649699f5501489183d6c9b83d503699fe17329dcfc733f52d83aa58befcfc |          64 | clerk |               0 |         0 |
+---------+----------+------------------------------------------------------------------+-------------+-------+-----------------+-----------+
2 rows in set
```

**Why this output is correct:** SHA2('Admin@123', 256) is computed by the server; only the 64-character digest is stored, the plain password is nowhere in the table.

### Task 3 - Procedure register(uname, pwd, role): reject duplicate usernames and passwords shorter than 8 characters

```sql
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
```

**Output**

```text
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
END

Query OK, 0 rows affected

CALL register('meena', 'Meena@2026', 'clerk')

Query OK, 1 row affected

CALL register('ravi', 'Another@123', 'clerk')

ERROR 1644 (45000) at line 22: Username already exists
CALL register('shorty', 'abc', 'clerk')

ERROR 1644 (45000) at line 23: Password must be at least 8 characters
CALL register('tester', 'Tester@123', 'clerk')

Query OK, 1 row affected

CALL register('tester2', 'Tester@123', 'clerk')

Query OK, 1 row affected

SELECT user_id, username, role FROM App_User

+---------+----------+-------+
| user_id | username | role  |
+---------+----------+-------+
|       1 | admin    | admin |
|       2 | ravi     | clerk |
|       3 | meena    | clerk |
|       4 | tester   | clerk |
|       5 | tester2  | clerk |
+---------+----------+-------+
5 rows in set
```

**Why this output is correct:** Validation order: username present, password length, role, duplicate. The EXIT HANDLER for error 1062 turns a race-condition duplicate (two sessions at once) into the same friendly message.

### Task 4 - Procedure login(IN uname, IN pwd, OUT msg) that compares hashes

```sql
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
```

**Output**

```text
CREATE PROCEDURE login(IN p_user VARCHAR(30), IN p_pwd VARCHAR(100), OUT msg VARCHAR(100))
BEGIN
    DECLARE v_hash CHAR(64);
    SELECT password_hash INTO v_hash FROM App_User WHERE username = p_user;
    IF v_hash IS NOT NULL AND v_hash = SHA2(p_pwd, 256) THEN
        SET msg = 'Login successful';
    ELSE
        SET msg = 'Invalid username or password';
    END IF;
END

Query OK, 0 rows affected

CALL login('tester', 'Tester@123', @m)

Query OK, 1 row affected

SELECT @m AS message

+------------------+
| message          |
+------------------+
| Login successful |
+------------------+
1 row in set

CALL login('tester', 'wrong-pass', @m)

Query OK, 1 row affected

SELECT @m AS message

+------------------------------+
| message                      |
+------------------------------+
| Invalid username or password |
+------------------------------+
1 row in set

CALL login('nobody', 'Tester@123', @m)

Query OK, 0 rows affected

SELECT @m AS message

+------------------------------+
| message                      |
+------------------------------+
| Invalid username or password |
+------------------------------+
1 row in set
```

**Why this output is correct:** Version 1: only the comparison. SHA2(typed password) must equal the stored hash. Unknown user and wrong password give the same message.

### Task 5 - On failure increment failed_attempts; set is_locked = 1 after 3 failures

```sql
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
```

**Output**

```text
DROP PROCEDURE login

Query OK, 0 rows affected

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
END

Query OK, 0 rows affected

CALL login('tester', 'bad1', @m)

Query OK, 1 row affected

SELECT @m AS message

+---------------------------------------+
| message                               |
+---------------------------------------+
| Invalid credentials. Attempts left: 2 |
+---------------------------------------+
1 row in set

CALL login('tester', 'bad2', @m)

Query OK, 1 row affected

SELECT @m AS message

+---------------------------------------+
| message                               |
+---------------------------------------+
| Invalid credentials. Attempts left: 1 |
+---------------------------------------+
1 row in set

CALL login('tester', 'bad3', @m)

Query OK, 1 row affected

SELECT @m AS message

+-------------------------------------------------------------+
| message                                                     |
+-------------------------------------------------------------+
| Invalid credentials. Account locked after 3 failed attempts |
+-------------------------------------------------------------+
1 row in set

CALL login('tester', 'Tester@123', @m)

Query OK, 1 row affected

SELECT @m AS message_with_correct_password

+----------------------------------------------+
| message_with_correct_password                |
+----------------------------------------------+
| Account is locked. Contact the administrator |
+----------------------------------------------+
1 row in set

SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester'

+----------+-----------------+-----------+
| username | failed_attempts | is_locked |
+----------+-----------------+-----------+
| tester   |               3 |         1 |
+----------+-----------------+-----------+
1 row in set
```

**Why this output is correct:** Version 2 adds the failure counter and the lock. `is_locked = (n >= 3)` is evaluated in the same UPDATE. A locked account is refused even with the right password.

### Task 6 - Reset failed_attempts to 0 on a successful login

```sql
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
```

**Output**

```text
DROP PROCEDURE login

Query OK, 0 rows affected

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
END

Query OK, 0 rows affected

CALL login('tester2', 'x1', @m)

Query OK, 1 row affected

CALL login('tester2', 'x2', @m)

Query OK, 1 row affected

SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester2'

+----------+-----------------+-----------+
| username | failed_attempts | is_locked |
+----------+-----------------+-----------+
| tester2  |               2 |         0 |
+----------+-----------------+-----------+
1 row in set

CALL login('tester2', 'Tester@123', @m)

Query OK, 1 row affected

SELECT @m AS message

+------------------+
| message          |
+------------------+
| Login successful |
+------------------+
1 row in set

SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'tester2'

+----------+-----------------+-----------+
| username | failed_attempts | is_locked |
+----------+-----------------+-----------+
| tester2  |               0 |         0 |
+----------+-----------------+-----------+
1 row in set
```

**Why this output is correct:** Version 3: the success branch also runs `UPDATE ... failed_attempts = 0`. tester2 fails twice (counter 2) and then logs in correctly: the counter returns to 0.

### Task 7 - Log every attempt (Success / Failed / Locked) into Login_Log

```sql
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
```

**Output**

```text
DROP PROCEDURE login

Query OK, 0 rows affected

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
END

Query OK, 0 rows affected

CALL login('tester2', 'nope', @m)

Query OK, 0 rows affected

SELECT @m AS message

+---------------------------------------+
| message                               |
+---------------------------------------+
| Invalid credentials. Attempts left: 2 |
+---------------------------------------+
1 row in set

CALL login('tester2', 'Tester@123', @m)

Query OK, 0 rows affected

SELECT @m AS message

+------------------+
| message          |
+------------------+
| Login successful |
+------------------+
1 row in set

SELECT log_id, username, status FROM Login_Log

+--------+----------+---------+
| log_id | username | status  |
+--------+----------+---------+
|      1 | tester2  | Failed  |
|      2 | tester2  | Success |
+--------+----------+---------+
2 rows in set

DELETE FROM App_User WHERE username IN ('tester', 'tester2')

Query OK, 2 rows affected

DELETE FROM Login_Log

Query OK, 2 rows affected
```

**Why this output is correct:** Final version 4: each branch inserts a Login_Log row; the whole procedure is one transaction (counter update and log row commit together). The test users are removed afterwards so that Task 8 starts from the PDF data.

### Task 8 - One successful login and three failed logins for ravi, then a locked response

```sql
CALL login('ravi', 'Ravi@123', @m); SELECT @m AS attempt_1_correct;
CALL login('ravi', 'guess1', @m); SELECT @m AS attempt_2_wrong;
CALL login('ravi', 'guess2', @m); SELECT @m AS attempt_3_wrong;
CALL login('ravi', 'guess3', @m); SELECT @m AS attempt_4_wrong;
CALL login('ravi', 'Ravi@123', @m); SELECT @m AS attempt_5_correct_but_locked;
SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'ravi';
SELECT log_id, username, status FROM Login_Log;
```

**Output**

```text
CALL login('ravi', 'Ravi@123', @m)

Query OK, 0 rows affected

SELECT @m AS attempt_1_correct

+-------------------+
| attempt_1_correct |
+-------------------+
| Login successful  |
+-------------------+
1 row in set

CALL login('ravi', 'guess1', @m)

Query OK, 0 rows affected

SELECT @m AS attempt_2_wrong

+---------------------------------------+
| attempt_2_wrong                       |
+---------------------------------------+
| Invalid credentials. Attempts left: 2 |
+---------------------------------------+
1 row in set

CALL login('ravi', 'guess2', @m)

Query OK, 0 rows affected

SELECT @m AS attempt_3_wrong

+---------------------------------------+
| attempt_3_wrong                       |
+---------------------------------------+
| Invalid credentials. Attempts left: 1 |
+---------------------------------------+
1 row in set

CALL login('ravi', 'guess3', @m)

Query OK, 0 rows affected

SELECT @m AS attempt_4_wrong

+-------------------------------------------------------------+
| attempt_4_wrong                                             |
+-------------------------------------------------------------+
| Invalid credentials. Account locked after 3 failed attempts |
+-------------------------------------------------------------+
1 row in set

CALL login('ravi', 'Ravi@123', @m)

Query OK, 0 rows affected

SELECT @m AS attempt_5_correct_but_locked

+----------------------------------------------+
| attempt_5_correct_but_locked                 |
+----------------------------------------------+
| Account is locked. Contact the administrator |
+----------------------------------------------+
1 row in set

SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'ravi'

+----------+-----------------+-----------+
| username | failed_attempts | is_locked |
+----------+-----------------+-----------+
| ravi     |               3 |         1 |
+----------+-----------------+-----------+
1 row in set

SELECT log_id, username, status FROM Login_Log

+--------+----------+---------+
| log_id | username | status  |
+--------+----------+---------+
|      3 | ravi     | Success |
|      4 | ravi     | Failed  |
|      5 | ravi     | Failed  |
|      6 | ravi     | Failed  |
|      7 | ravi     | Locked  |
+--------+----------+---------+
5 rows in set
```

**Why this output is correct:** success -> counter stays 0; wrong x3 -> counters 1, 2, 3 and the lock; the 4th attempt (even with the correct password) is answered with the locked message and logged as 'Locked'.

### Task 9 - Procedure change_password(uname, old_pwd, new_pwd)

```sql
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
```

**Output**

```text
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
END

Query OK, 0 rows affected

CALL change_password('meena', 'WrongOld1', 'Meena@2027')

ERROR 1644 (45000) at line 22: Invalid username or old password
CALL change_password('meena', 'Meena@2026', 'short')

ERROR 1644 (45000) at line 23: New password must be at least 8 characters
CALL change_password('meena', 'Meena@2026', 'Meena@2026')

ERROR 1644 (45000) at line 24: New password must differ from the old one
CALL change_password('meena', 'Meena@2026', 'Meena@2027')

Query OK, 1 row affected

CALL login('meena', 'Meena@2026', @m)

Query OK, 0 rows affected

SELECT @m AS old_password_now

+---------------------------------------+
| old_password_now                      |
+---------------------------------------+
| Invalid credentials. Attempts left: 2 |
+---------------------------------------+
1 row in set

CALL login('meena', 'Meena@2027', @m)

Query OK, 0 rows affected

SELECT @m AS new_password

+------------------+
| new_password     |
+------------------+
| Login successful |
+------------------+
1 row in set

CALL change_password('ravi', 'Ravi@123', 'Ravi@2027')

ERROR 1644 (45000) at line 28: Account is locked
```

**Why this output is correct:** The old password must match, the new one must be at least 8 characters and different, and a locked account cannot change it. Tested with meena.

### Task 10 - Login history of each user with counts of failed attempts

```sql
SELECT u.username, u.role, COALESCE(SUM(l.status = 'Success'), 0) AS successes, COALESCE(SUM(l.status = 'Failed'), 0) AS failures,
       COALESCE(SUM(l.status = 'Locked'), 0) AS locked_attempts, u.failed_attempts AS current_counter, u.is_locked
FROM App_User u LEFT JOIN Login_Log l ON l.username = u.username GROUP BY u.user_id, u.username, u.role, u.failed_attempts, u.is_locked ORDER BY u.user_id;
SELECT username, status, COUNT(*) AS times FROM Login_Log GROUP BY username, status ORDER BY username, status;
```

**Output**

```text
SELECT u.username, u.role, COALESCE(SUM(l.status = 'Success'), 0) AS successes, COALESCE(SUM(l.status = 'Failed'), 0) AS failures,
       COALESCE(SUM(l.status = 'Locked'), 0) AS locked_attempts, u.failed_attempts AS current_counter, u.is_locked
FROM App_User u LEFT JOIN Login_Log l ON l.username = u.username GROUP BY u.user_id, u.username, u.role, u.failed_attempts, u.is_locked ORDER BY u.user_id

+----------+-------+-----------+----------+-----------------+-----------------+-----------+
| username | role  | successes | failures | locked_attempts | current_counter | is_locked |
+----------+-------+-----------+----------+-----------------+-----------------+-----------+
| admin    | admin |         0 |        0 |               0 |               0 |         0 |
| ravi     | clerk |         1 |        3 |               1 |               3 |         1 |
| meena    | clerk |         1 |        1 |               0 |               0 |         0 |
+----------+-------+-----------+----------+-----------------+-----------------+-----------+
3 rows in set

SELECT username, status, COUNT(*) AS times FROM Login_Log GROUP BY username, status ORDER BY username, status

+----------+---------+-------+
| username | status  | times |
+----------+---------+-------+
| meena    | Failed  |     1 |
| meena    | Success |     1 |
| ravi     | Failed  |     3 |
| ravi     | Locked  |     1 |
| ravi     | Success |     1 |
+----------+---------+-------+
5 rows in set
```

### Task 11 - Procedure unlock_user(uname); GRANT EXECUTE on it only to a DB user with the admin role

```sql
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
```

**Output**

```text
CREATE PROCEDURE unlock_user(IN p_user VARCHAR(30))
BEGIN
    UPDATE App_User SET is_locked = 0, failed_attempts = 0 WHERE username = p_user;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or already unlocked';
    END IF;
END

Query OK, 0 rows affected

DROP USER IF EXISTS 'db_admin'@'localhost'

Query OK, 0 rows affected

DROP USER IF EXISTS 'db_clerk'@'localhost'

Query OK, 0 rows affected

DROP ROLE IF EXISTS 'admin', 'clerk'

Query OK, 0 rows affected

CREATE ROLE 'admin', 'clerk'

Query OK, 0 rows affected

GRANT EXECUTE ON PROCEDURE login_6d.unlock_user      TO 'admin'

Query OK, 0 rows affected

GRANT EXECUTE ON PROCEDURE login_6d.register         TO 'admin'

Query OK, 0 rows affected

GRANT EXECUTE ON PROCEDURE login_6d.login            TO 'admin', 'clerk'

Query OK, 0 rows affected

GRANT EXECUTE ON PROCEDURE login_6d.change_password  TO 'admin', 'clerk'

Query OK, 0 rows affected

GRANT SELECT (user_id, username, role, failed_attempts, is_locked) ON login_6d.App_User TO 'admin'

Query OK, 0 rows affected

GRANT SELECT (user_id, username, role) ON login_6d.App_User TO 'clerk'

Query OK, 0 rows affected

GRANT SELECT ON login_6d.Login_Log TO 'admin'

Query OK, 0 rows affected

CREATE USER 'db_admin'@'localhost' IDENTIFIED BY 'DbAdmin@12345'

Query OK, 0 rows affected

CREATE USER 'db_clerk'@'localhost' IDENTIFIED BY 'DbClerk@12345'

Query OK, 0 rows affected

GRANT 'admin' TO 'db_admin'@'localhost'

Query OK, 0 rows affected

GRANT 'clerk' TO 'db_clerk'@'localhost'

Query OK, 0 rows affected

SET DEFAULT ROLE 'admin' TO 'db_admin'@'localhost'

Query OK, 0 rows affected

SET DEFAULT ROLE 'clerk' TO 'db_clerk'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'db_admin'@'localhost' USING 'admin'

+---------------------------------------------------------------------------------------------------------------------------------+
| Grants for db_admin@localhost                                                                                                   |
+---------------------------------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `db_admin`@`localhost`                                                                                    |
| GRANT SELECT (`failed_attempts`, `is_locked`, `role`, `user_id`, `username`) ON `login_6d`.`app_user` TO `db_admin`@`localhost` |
| GRANT SELECT ON `login_6d`.`login_log` TO `db_admin`@`localhost`                                                                |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`change_password` TO `db_admin`@`localhost`                                               |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`login` TO `db_admin`@`localhost`                                                         |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`register` TO `db_admin`@`localhost`                                                      |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`unlock_user` TO `db_admin`@`localhost`                                                   |
| GRANT `admin`@`%` TO `db_admin`@`localhost`                                                                                     |
+---------------------------------------------------------------------------------------------------------------------------------+
8 rows in set

[session: user 'db_admin']
CALL unlock_user('ravi')

Query OK, 1 row affected

SELECT username, failed_attempts, is_locked FROM App_User WHERE username = 'ravi'

+----------+-----------------+-----------+
| username | failed_attempts | is_locked |
+----------+-----------------+-----------+
| ravi     |               0 |         0 |
+----------+-----------------+-----------+
1 row in set

SELECT password_hash FROM App_User

ERROR 1143 (42000) at line 3: SELECT command denied to user 'db_admin'@'localhost' for column 'password_hash' in table 'app_user'
```

**Why this output is correct:** unlock_user clears the lock and the counter. Roles: admin may EXECUTE every procedure and read the non-secret columns; clerk may only call login and change_password. db_admin holds role admin, db_clerk holds role clerk.

### Task 12 - The clerk DB user cannot execute unlock_user or SELECT password_hash

```sql
SHOW GRANTS FOR 'db_clerk'@'localhost' USING 'clerk';
-- @as db_clerk DbClerk@12345
-- | CALL unlock_user('ravi');
-- | SELECT password_hash FROM App_User;
-- | SELECT * FROM App_User;
-- | SELECT user_id, username, role FROM App_User;
-- | CALL login('ravi', 'Ravi@123', @m);
-- | SELECT @m AS message;
```

**Output**

```text
SHOW GRANTS FOR 'db_clerk'@'localhost' USING 'clerk'

+-------------------------------------------------------------------------------------------------+
| Grants for db_clerk@localhost                                                                   |
+-------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `db_clerk`@`localhost`                                                    |
| GRANT SELECT (`role`, `user_id`, `username`) ON `login_6d`.`app_user` TO `db_clerk`@`localhost` |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`change_password` TO `db_clerk`@`localhost`               |
| GRANT EXECUTE ON PROCEDURE `login_6d`.`login` TO `db_clerk`@`localhost`                         |
| GRANT `clerk`@`%` TO `db_clerk`@`localhost`                                                     |
+-------------------------------------------------------------------------------------------------+
5 rows in set

[session: user 'db_clerk']
CALL unlock_user('ravi')

ERROR 1370 (42000) at line 1: execute command denied to user 'db_clerk'@'localhost' for routine 'login_6d.unlock_user'
SELECT password_hash FROM App_User

ERROR 1143 (42000) at line 2: SELECT command denied to user 'db_clerk'@'localhost' for column 'password_hash' in table 'app_user'
SELECT * FROM App_User

ERROR 1142 (42000) at line 3: SELECT command denied to user 'db_clerk'@'localhost' for table 'app_user'
SELECT user_id, username, role FROM App_User

+---------+----------+-------+
| user_id | username | role  |
+---------+----------+-------+
|       1 | admin    | admin |
|       2 | ravi     | clerk |
|       3 | meena    | clerk |
+---------+----------+-------+
3 rows in set

CALL login('ravi', 'Ravi@123', @m)

Query OK, 0 rows affected

SELECT @m AS message

+------------------+
| message          |
+------------------+
| Login successful |
+------------------+
1 row in set
```

**Why this output is correct:** db_clerk may call login (works) but unlock_user gives ERROR 1370; reading the hash column gives ERROR 1143 (column privilege), while the harmless columns are readable.


## Advanced / examiner-style queries

### Adv 1 - Why unsalted SHA-256 is weak - and a salted variant

```sql
SELECT SHA2('Same@1234', 256) = SHA2('Same@1234', 256) AS unsalted_equal;
SET @salt1 = HEX(RANDOM_BYTES(8)), @salt2 = HEX(RANDOM_BYTES(8));
SELECT SHA2(CONCAT(@salt1, 'Same@1234'), 256) = SHA2(CONCAT(@salt2, 'Same@1234'), 256) AS salted_equal;
```

**Output**

```text
SELECT SHA2('Same@1234', 256) = SHA2('Same@1234', 256) AS unsalted_equal

+----------------+
| unsalted_equal |
+----------------+
|              1 |
+----------------+
1 row in set

SET @salt1 = HEX(RANDOM_BYTES(8)), @salt2 = HEX(RANDOM_BYTES(8))

Query OK, 0 rows affected

SELECT SHA2(CONCAT(@salt1, 'Same@1234'), 256) = SHA2(CONCAT(@salt2, 'Same@1234'), 256) AS salted_equal

+--------------+
| salted_equal |
+--------------+
|            0 |
+--------------+
1 row in set
```

**Why this output is correct:** Two users with the same password get the SAME hash (visible to anybody who can read the table and crackable with rainbow tables). A random per-user salt makes equal passwords look different. (Production: bcrypt/Argon2 in the application, not SHA-256.)

### Adv 2 - Users who never logged in successfully

```sql
SELECT u.username FROM App_User u WHERE NOT EXISTS (SELECT 1 FROM Login_Log l WHERE l.username = u.username AND l.status = 'Success');
```

**Output**

```text
SELECT u.username FROM App_User u WHERE NOT EXISTS (SELECT 1 FROM Login_Log l WHERE l.username = u.username AND l.status = 'Success')

+----------+
| username |
+----------+
| admin    |
+----------+
1 row in set
```

### Adv 3 - Locked accounts

```sql
SELECT username, failed_attempts FROM App_User WHERE is_locked = 1;
```

**Output**

```text
SELECT username, failed_attempts FROM App_User WHERE is_locked = 1

Empty set
```

### Adv 4 - Failed attempts per day

```sql
SELECT DATE(login_time) AS day, COUNT(*) AS failed FROM Login_Log WHERE status = 'Failed' GROUP BY DATE(login_time);
```

**Output**

```text
SELECT DATE(login_time) AS day, COUNT(*) AS failed FROM Login_Log WHERE status = 'Failed' GROUP BY DATE(login_time)

+------------+--------+
| day        | failed |
+------------+--------+
| 2026-10-30 |      4 |
+------------+--------+
1 row in set
```

### Adv 5 - Duplicate username through direct INSERT

```sql
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Whatever@1', 256), 'admin');
```

**Output**

```text
INSERT INTO App_User (username, password_hash, role) VALUES ('admin', SHA2('Whatever@1', 256), 'admin')

ERROR 1062 (23000) at line 1: Duplicate entry 'admin' for key 'app_user.uq_app_user_username'
```

**Why this output is correct:** Error 1062 (uq_app_user_username) - the UNIQUE constraint backs up register().

### Adv 6 - Invalid role

```sql
INSERT INTO App_User (username, password_hash, role) VALUES ('zed', SHA2('Zed@12345', 256), 'superuser');
```

**Output**

```text
INSERT INTO App_User (username, password_hash, role) VALUES ('zed', SHA2('Zed@12345', 256), 'superuser')

ERROR 3819 (HY000) at line 1: Check constraint 'chk_app_user_role' is violated.
```

**Why this output is correct:** Error 3819 (chk_app_user_role).

# Expected output - Experiment_04_Triggers_Procedures_ACID / 4B_Payroll

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Employee and insert the data

```sql
SELECT * FROM Employee;
```

**Output**

```text
SELECT * FROM Employee

+--------+--------+-------+----------+
| emp_id | name   | dept  | salary   |
+--------+--------+-------+----------+
|      1 | Anil   | IT    | 60000.00 |
|      2 | Bharti | IT    | 55000.00 |
|      3 | Chirag | HR    | 40000.00 |
|      4 | Deepa  | HR    | 42000.00 |
|      5 | Eshan  | Sales | 35000.00 |
+--------+--------+-------+----------+
5 rows in set
```

### Task 2 - Create table Salary_Audit (emp_id, old_salary, new_salary, changed_on)

```sql
DESCRIBE Salary_Audit;
```

**Output**

```text
DESCRIBE Salary_Audit

+------------+---------------+------+-----+-------------------+-------------------+
| Field      | Type          | Null | Key | Default           | Extra             |
+------------+---------------+------+-----+-------------------+-------------------+
| audit_id   | int           | NO   | PRI | NULL              | auto_increment    |
| emp_id     | int           | NO   |     | NULL              |                   |
| old_salary | decimal(10,2) | NO   |     | NULL              |                   |
| new_salary | decimal(10,2) | NO   |     | NULL              |                   |
| changed_on | datetime      | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
+------------+---------------+------+-----+-------------------+-------------------+
5 rows in set
```

**Why this output is correct:** Created in 01_schema.sql; changed_on defaults to the current time.

### Task 3 - BEFORE UPDATE trigger that raises an error if the new salary is lower than the old one

```sql
DELIMITER $$
CREATE TRIGGER trg_emp_no_decrease BEFORE UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be reduced';
    END IF;
END$$
DELIMITER ;
SHOW TRIGGERS LIKE 'Employee';
```

**Output**

```text
CREATE TRIGGER trg_emp_no_decrease BEFORE UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be reduced';
    END IF;
END

Query OK, 0 rows affected

SHOW TRIGGERS LIKE 'Employee'

+---------------------+--------+----------+------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| Trigger             | Event  | Table    | Statement                                                                                                                                | Timing | Created                | sql_mode                                                                                                              | Definer        | character_set_client | collation_connection | Database Collation |
+---------------------+--------+----------+------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
| trg_emp_no_decrease | UPDATE | employee | BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be reduced';
    END IF;
END | BEFORE | 2026-10-30 10:42:24.42 | ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION | root@localhost | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+---------------------+--------+----------+------------------------------------------------------------------------------------------------------------------------------------------+--------+------------------------+-----------------------------------------------------------------------------------------------------------------------+----------------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** SIGNAL SQLSTATE 45000 aborts the UPDATE with the given message.

### Task 4 - AFTER UPDATE trigger that records every salary change in Salary_Audit

```sql
DELIMITER $$
CREATE TRIGGER trg_emp_audit AFTER UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary <> OLD.salary THEN
        INSERT INTO Salary_Audit (emp_id, old_salary, new_salary) VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
UPDATE Employee SET name = 'Deepa K' WHERE emp_id = 4;
SELECT COUNT(*) AS audit_rows_after_name_change FROM Salary_Audit;
ROLLBACK;
```

**Output**

```text
CREATE TRIGGER trg_emp_audit AFTER UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary <> OLD.salary THEN
        INSERT INTO Salary_Audit (emp_id, old_salary, new_salary) VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    END IF;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

UPDATE Employee SET name = 'Deepa K' WHERE emp_id = 4

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT COUNT(*) AS audit_rows_after_name_change FROM Salary_Audit

+------------------------------+
| audit_rows_after_name_change |
+------------------------------+
|                            0 |
+------------------------------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** Only when the salary actually changed (NEW.salary <> OLD.salary), so updating other columns does not create audit rows.

### Task 5 - BEFORE INSERT trigger that sets salary to 20000 if inserted as NULL

```sql
DELIMITER $$
CREATE TRIGGER trg_emp_default_salary BEFORE INSERT ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL THEN
        SET NEW.salary = 20000;
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
INSERT INTO Employee (emp_id, name, dept, salary) VALUES (6, 'Farhan', 'IT', NULL);
SELECT * FROM Employee WHERE emp_id = 6;
ROLLBACK;
```

**Output**

```text
CREATE TRIGGER trg_emp_default_salary BEFORE INSERT ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL THEN
        SET NEW.salary = 20000;
    END IF;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Employee (emp_id, name, dept, salary) VALUES (6, 'Farhan', 'IT', NULL)

Query OK, 1 row affected

SELECT * FROM Employee WHERE emp_id = 6

+--------+--------+------+----------+
| emp_id | name   | dept | salary   |
+--------+--------+------+----------+
|      6 | Farhan | IT   | 20000.00 |
+--------+--------+------+----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** The column is NOT NULL, but a BEFORE trigger runs before the NOT NULL check, so replacing NEW.salary makes the INSERT legal. The new row is rolled back afterwards so later tasks see the five rows of the PDF.

### Task 6 - Procedure give_raise(IN d, IN pct) with a cursor that prints each new salary

```sql
DELIMITER $$
CREATE PROCEDURE give_raise(IN d VARCHAR(20), IN pct INT)
BEGIN
    DECLARE v_id INT;
    DECLARE v_name VARCHAR(40);
    DECLARE v_sal DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT emp_id, name, salary FROM Employee WHERE dept = d;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    raise_loop: LOOP
        FETCH cur INTO v_id, v_name, v_sal;
        IF done = 1 THEN
            LEAVE raise_loop;
        END IF;
        UPDATE Employee SET salary = salary * (1 + pct / 100) WHERE emp_id = v_id;
        SELECT CONCAT(v_name, ': ', v_sal, ' -> ', (SELECT salary FROM Employee WHERE emp_id = v_id)) AS new_salary;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
SHOW PROCEDURE STATUS WHERE Db = 'payroll_4b';
```

**Output**

```text
CREATE PROCEDURE give_raise(IN d VARCHAR(20), IN pct INT)
BEGIN
    DECLARE v_id INT;
    DECLARE v_name VARCHAR(40);
    DECLARE v_sal DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT emp_id, name, salary FROM Employee WHERE dept = d;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    raise_loop: LOOP
        FETCH cur INTO v_id, v_name, v_sal;
        IF done = 1 THEN
            LEAVE raise_loop;
        END IF;
        UPDATE Employee SET salary = salary * (1 + pct / 100) WHERE emp_id = v_id;
        SELECT CONCAT(v_name, ': ', v_sal, ' -> ', (SELECT salary FROM Employee WHERE emp_id = v_id)) AS new_salary;
    END LOOP;
    CLOSE cur;
END

Query OK, 0 rows affected

SHOW PROCEDURE STATUS WHERE Db = 'payroll_4b'

+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| Db         | Name       | Type      | Definer        | Modified            | Created             | Security_type | Comment | character_set_client | collation_connection | Database Collation |
+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| payroll_4b | give_raise | PROCEDURE | root@localhost | 2026-10-30 10:42:25 | 2026-10-30 10:42:25 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+------------+------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** The cursor loops over the employees of one department; each iteration raises the salary and SELECTs a message (a "print").

### Task 7 - Call give_raise('IT', 10) and display Employee and Salary_Audit

```sql
CALL give_raise('IT', 10);
SELECT * FROM Employee;
SELECT audit_id, emp_id, old_salary, new_salary FROM Salary_Audit;
```

**Output**

```text
CALL give_raise('IT', 10)

+----------------------------+
| new_salary                 |
+----------------------------+
| Anil: 60000.00 -> 66000.00 |
+----------------------------+
1 row in set

+------------------------------+
| new_salary                   |
+------------------------------+
| Bharti: 55000.00 -> 60500.00 |
+------------------------------+
1 row in set

Query OK, 0 rows affected

SELECT * FROM Employee

+--------+--------+-------+----------+
| emp_id | name   | dept  | salary   |
+--------+--------+-------+----------+
|      1 | Anil   | IT    | 66000.00 |
|      2 | Bharti | IT    | 60500.00 |
|      3 | Chirag | HR    | 40000.00 |
|      4 | Deepa  | HR    | 42000.00 |
|      5 | Eshan  | Sales | 35000.00 |
+--------+--------+-------+----------+
5 rows in set

SELECT audit_id, emp_id, old_salary, new_salary FROM Salary_Audit

+----------+--------+------------+------------+
| audit_id | emp_id | old_salary | new_salary |
+----------+--------+------------+------------+
|        1 |      1 |   60000.00 |   66000.00 |
|        2 |      2 |   55000.00 |   60500.00 |
+----------+--------+------------+------------+
2 rows in set
```

**Why this output is correct:** Anil 60000 -> 66000, Bharti 55000 -> 60500; the AFTER UPDATE trigger writes two audit rows.

### Task 8 - Reduce Chirag's salary to 30000 - trigger error

```sql
UPDATE Employee SET salary = 30000 WHERE name = 'Chirag';
SELECT emp_id, name, salary FROM Employee WHERE name = 'Chirag';
```

**Output**

```text
UPDATE Employee SET salary = 30000 WHERE name = 'Chirag'

ERROR 1644 (45000) at line 1: Salary cannot be reduced
SELECT emp_id, name, salary FROM Employee WHERE name = 'Chirag'

+--------+--------+----------+
| emp_id | name   | salary   |
+--------+--------+----------+
|      3 | Chirag | 40000.00 |
+--------+--------+----------+
1 row in set
```

**Why this output is correct:** 30000 < 40000, so trg_emp_no_decrease signals "Salary cannot be reduced"; the row keeps 40000 and no audit row is written.

### Task 9 - Function annual_tax(emp_id) - 0% up to 5,00,000 annual, 10% above; list every employee with tax

```sql
DELIMITER $$
CREATE FUNCTION annual_tax(p_emp INT) RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
    DECLARE v_annual DECIMAL(12,2);
    SELECT salary * 12 INTO v_annual FROM Employee WHERE emp_id = p_emp;
    IF v_annual IS NULL OR v_annual <= 500000 THEN
        RETURN 0;
    END IF;
    RETURN (v_annual - 500000) * 0.10;
END$$
DELIMITER ;
SELECT emp_id, name, salary, salary * 12 AS annual_income, annual_tax(emp_id) AS tax FROM Employee;
```

**Output**

```text
CREATE FUNCTION annual_tax(p_emp INT) RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
    DECLARE v_annual DECIMAL(12,2);
    SELECT salary * 12 INTO v_annual FROM Employee WHERE emp_id = p_emp;
    IF v_annual IS NULL OR v_annual <= 500000 THEN
        RETURN 0;
    END IF;
    RETURN (v_annual - 500000) * 0.10;
END

Query OK, 0 rows affected

SELECT emp_id, name, salary, salary * 12 AS annual_income, annual_tax(emp_id) AS tax FROM Employee

+--------+--------+----------+---------------+----------+
| emp_id | name   | salary   | annual_income | tax      |
+--------+--------+----------+---------------+----------+
|      1 | Anil   | 66000.00 |     792000.00 | 29200.00 |
|      2 | Bharti | 60500.00 |     726000.00 | 22600.00 |
|      3 | Chirag | 40000.00 |     480000.00 |     0.00 |
|      4 | Deepa  | 42000.00 |     504000.00 |   400.00 |
|      5 | Eshan  | 35000.00 |     420000.00 |     0.00 |
+--------+--------+----------+---------------+----------+
5 rows in set
```

**Why this output is correct:** annual = monthly salary x 12; tax = 10% of (annual - 500000) when annual > 500000. Anil 792000 -> 29200, Bharti 726000 -> 22600, Deepa 504000 -> 400, others 0.

### Task 10 - Procedure dept_stats(IN d, OUT total, OUT avg_sal) and call it

```sql
DELIMITER $$
CREATE PROCEDURE dept_stats(IN d VARCHAR(20), OUT total DECIMAL(12,2), OUT avg_sal DECIMAL(12,2))
BEGIN
    SELECT SUM(salary), AVG(salary) INTO total, avg_sal FROM Employee WHERE dept = d;
END$$
DELIMITER ;
CALL dept_stats('IT', @total, @avg_sal);
SELECT @total AS it_total, @avg_sal AS it_average;
CALL dept_stats('HR', @total, @avg_sal);
SELECT @total AS hr_total, @avg_sal AS hr_average;
```

**Output**

```text
CREATE PROCEDURE dept_stats(IN d VARCHAR(20), OUT total DECIMAL(12,2), OUT avg_sal DECIMAL(12,2))
BEGIN
    SELECT SUM(salary), AVG(salary) INTO total, avg_sal FROM Employee WHERE dept = d;
END

Query OK, 0 rows affected

CALL dept_stats('IT', @total, @avg_sal)

Query OK, 1 row affected

SELECT @total AS it_total, @avg_sal AS it_average

+-----------+------------+
| it_total  | it_average |
+-----------+------------+
| 126500.00 |   63250.00 |
+-----------+------------+
1 row in set

CALL dept_stats('HR', @total, @avg_sal)

Query OK, 1 row affected

SELECT @total AS hr_total, @avg_sal AS hr_average

+----------+------------+
| hr_total | hr_average |
+----------+------------+
| 82000.00 |   41000.00 |
+----------+------------+
1 row in set
```

**Why this output is correct:** OUT parameters are filled by the procedure and read back through user variables in the same session.

### Task 11 - Exception handling (DECLARE ... HANDLER) in give_raise for an invalid department

```sql
DROP PROCEDURE give_raise;
DELIMITER $$
CREATE PROCEDURE give_raise(IN d VARCHAR(20), IN pct INT)
BEGIN
    DECLARE v_id INT;
    DECLARE v_name VARCHAR(40);
    DECLARE v_sal DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE v_msg TEXT;
    DECLARE cur CURSOR FOR SELECT emp_id, name, salary FROM Employee WHERE dept = d;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        SELECT CONCAT('give_raise failed: ', v_msg) AS error_handled;
    END;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE dept = d) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid department';
    END IF;
    OPEN cur;
    raise_loop: LOOP
        FETCH cur INTO v_id, v_name, v_sal;
        IF done = 1 THEN
            LEAVE raise_loop;
        END IF;
        UPDATE Employee SET salary = salary * (1 + pct / 100) WHERE emp_id = v_id;
        SELECT CONCAT(v_name, ': ', v_sal, ' -> ', (SELECT salary FROM Employee WHERE emp_id = v_id)) AS new_salary;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
CALL give_raise('Marketing', 10);
START TRANSACTION;
CALL give_raise('Sales', 100);
ROLLBACK;
```

**Output**

```text
DROP PROCEDURE give_raise

Query OK, 0 rows affected

CREATE PROCEDURE give_raise(IN d VARCHAR(20), IN pct INT)
BEGIN
    DECLARE v_id INT;
    DECLARE v_name VARCHAR(40);
    DECLARE v_sal DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE v_msg TEXT;
    DECLARE cur CURSOR FOR SELECT emp_id, name, salary FROM Employee WHERE dept = d;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        SELECT CONCAT('give_raise failed: ', v_msg) AS error_handled;
    END;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE dept = d) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid department';
    END IF;
    OPEN cur;
    raise_loop: LOOP
        FETCH cur INTO v_id, v_name, v_sal;
        IF done = 1 THEN
            LEAVE raise_loop;
        END IF;
        UPDATE Employee SET salary = salary * (1 + pct / 100) WHERE emp_id = v_id;
        SELECT CONCAT(v_name, ': ', v_sal, ' -> ', (SELECT salary FROM Employee WHERE emp_id = v_id)) AS new_salary;
    END LOOP;
    CLOSE cur;
END

Query OK, 0 rows affected

CALL give_raise('Marketing', 10)

+---------------------------------------+
| error_handled                         |
+---------------------------------------+
| give_raise failed: Invalid department |
+---------------------------------------+
1 row in set

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

CALL give_raise('Sales', 100)

+-----------------------------+
| new_salary                  |
+-----------------------------+
| Eshan: 35000.00 -> 70000.00 |
+-----------------------------+
1 row in set

Query OK, 0 rows affected

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** The new version first checks that the department exists and SIGNALs otherwise; an EXIT HANDLER catches any SQL exception, reads its text with GET DIAGNOSTICS and returns it as a normal result instead of an error. Valid departments behave exactly as before.

### Task 12 - Run give_raise inside a transaction and ROLLBACK; salaries are restored

```sql
SELECT COUNT(*) AS audit_rows_before FROM Salary_Audit;
START TRANSACTION;
CALL give_raise('HR', 20);
SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR';
ROLLBACK;
SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR';
SELECT COUNT(*) AS audit_rows_after FROM Salary_Audit;
```

**Output**

```text
SELECT COUNT(*) AS audit_rows_before FROM Salary_Audit

+-------------------+
| audit_rows_before |
+-------------------+
|                 2 |
+-------------------+
1 row in set

START TRANSACTION

Query OK, 0 rows affected

CALL give_raise('HR', 20)

+------------------------------+
| new_salary                   |
+------------------------------+
| Chirag: 40000.00 -> 48000.00 |
+------------------------------+
1 row in set

+-----------------------------+
| new_salary                  |
+-----------------------------+
| Deepa: 42000.00 -> 50400.00 |
+-----------------------------+
1 row in set

Query OK, 0 rows affected

SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR'

+--------+--------+----------+
| emp_id | name   | salary   |
+--------+--------+----------+
|      3 | Chirag | 48000.00 |
|      4 | Deepa  | 50400.00 |
+--------+--------+----------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected

SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR'

+--------+--------+----------+
| emp_id | name   | salary   |
+--------+--------+----------+
|      3 | Chirag | 40000.00 |
|      4 | Deepa  | 42000.00 |
+--------+--------+----------+
2 rows in set

SELECT COUNT(*) AS audit_rows_after FROM Salary_Audit

+------------------+
| audit_rows_after |
+------------------+
|                2 |
+------------------+
1 row in set
```

**Why this output is correct:** The procedure itself does not commit, so the caller controls the transaction: the raise (and its audit rows) disappear on ROLLBACK.


## Advanced / examiner-style queries

### Adv 1 - Total tax payable by the company

```sql
SELECT SUM(annual_tax(emp_id)) AS total_tax FROM Employee;
```

**Output**

```text
SELECT SUM(annual_tax(emp_id)) AS total_tax FROM Employee

+-----------+
| total_tax |
+-----------+
|  52200.00 |
+-----------+
1 row in set
```

### Adv 2 - Highest paid employee of each department using a correlated subquery

```sql
SELECT name, dept, salary FROM Employee e WHERE salary = (SELECT MAX(salary) FROM Employee x WHERE x.dept = e.dept);
```

**Output**

```text
SELECT name, dept, salary FROM Employee e WHERE salary = (SELECT MAX(salary) FROM Employee x WHERE x.dept = e.dept)

+-------+-------+----------+
| name  | dept  | salary   |
+-------+-------+----------+
| Anil  | IT    | 66000.00 |
| Deepa | HR    | 42000.00 |
| Eshan | Sales | 35000.00 |
+-------+-------+----------+
3 rows in set
```

### Adv 3 - Audit trail with the percentage change

```sql
SELECT emp_id, old_salary, new_salary, ROUND((new_salary - old_salary) / old_salary * 100, 2) AS pct_change FROM Salary_Audit;
```

**Output**

```text
SELECT emp_id, old_salary, new_salary, ROUND((new_salary - old_salary) / old_salary * 100, 2) AS pct_change FROM Salary_Audit

+--------+------------+------------+------------+
| emp_id | old_salary | new_salary | pct_change |
+--------+------------+------------+------------+
|      1 |   60000.00 |   66000.00 |      10.00 |
|      2 |   55000.00 |   60500.00 |      10.00 |
+--------+------------+------------+------------+
2 rows in set
```

### Adv 4 - Equal salary update is allowed and creates no audit row

```sql
SELECT COUNT(*) AS audit_before FROM Salary_Audit;
UPDATE Employee SET salary = salary WHERE emp_id = 3;
SELECT COUNT(*) AS audit_after FROM Salary_Audit;
```

**Output**

```text
SELECT COUNT(*) AS audit_before FROM Salary_Audit

+--------------+
| audit_before |
+--------------+
|            2 |
+--------------+
1 row in set

UPDATE Employee SET salary = salary WHERE emp_id = 3

Query OK, 0 rows affected
Rows matched: 1  Changed: 0  Warnings: 0

SELECT COUNT(*) AS audit_after FROM Salary_Audit

+-------------+
| audit_after |
+-------------+
|           2 |
+-------------+
1 row in set
```

**Why this output is correct:** The BEFORE trigger only rejects a LOWER salary; the AFTER trigger logs only real changes.

### Adv 5 - Trigger rejecting a decrease also protects bulk updates

```sql
SELECT SUM(salary) AS payroll_before FROM Employee;
UPDATE Employee SET salary = salary - 1000;
SELECT SUM(salary) AS payroll_after FROM Employee;
```

**Output**

```text
SELECT SUM(salary) AS payroll_before FROM Employee

+----------------+
| payroll_before |
+----------------+
|      243500.00 |
+----------------+
1 row in set

UPDATE Employee SET salary = salary - 1000

ERROR 1644 (45000) at line 2: Salary cannot be reduced
SELECT SUM(salary) AS payroll_after FROM Employee

+---------------+
| payroll_after |
+---------------+
|     243500.00 |
+---------------+
1 row in set
```

**Why this output is correct:** The whole UPDATE fails and is rolled back as one statement, no employee is changed.

### Adv 6 - Dept_stats for an unknown department returns NULLs (no error)

```sql
CALL dept_stats('Marketing', @t, @a);
SELECT @t AS total, @a AS average;
```

**Output**

```text
CALL dept_stats('Marketing', @t, @a)

Query OK, 1 row affected

SELECT @t AS total, @a AS average

+-------+---------+
| total | average |
+-------+---------+
|  NULL |    NULL |
+-------+---------+
1 row in set
```

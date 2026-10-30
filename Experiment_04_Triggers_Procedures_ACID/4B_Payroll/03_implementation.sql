-- Experiment 4B - Payroll : 12 tasks
/* @CONCEPTS
* **BEFORE UPDATE** trigger = validation (SIGNAL to reject); **AFTER UPDATE** trigger = audit trail; **BEFORE INSERT** trigger can rewrite `NEW` values (default NULL salary to 20000).
* **Cursor**: `DECLARE c CURSOR FOR SELECT ...; OPEN c; FETCH c INTO ...; CLOSE c;` with `DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1` to end the loop.
* **Handlers**: `DECLARE EXIT/CONTINUE HANDLER FOR SQLEXCEPTION|SQLSTATE|NOT FOUND` ; `GET DIAGNOSTICS CONDITION 1 msg = MESSAGE_TEXT` reads the error text.
* **OUT parameters** return values to the caller through session variables: `CALL dept_stats('IT', @t, @a)`.
* Assumption for Task 9: the salary column is the **monthly** salary, so annual = salary x 12; tax is a slab: 0% up to 5,00,000 and 10% of the part above 5,00,000.
* Oracle: use `RAISE_APPLICATION_ERROR`, `FOR rec IN (SELECT ...) LOOP ... END LOOP;` for cursors, `OUT` params with bind variables.
*/

-- ### TASK 1: Create Employee and insert the data
SELECT * FROM Employee;

-- ### TASK 2: Create table Salary_Audit (emp_id, old_salary, new_salary, changed_on)
-- Created in 01_schema.sql; changed_on defaults to the current time.
DESCRIBE Salary_Audit;

-- ### TASK 3: BEFORE UPDATE trigger that raises an error if the new salary is lower than the old one
-- SIGNAL SQLSTATE 45000 aborts the UPDATE with the given message.
DELIMITER $$
CREATE TRIGGER trg_emp_no_decrease BEFORE UPDATE ON Employee FOR EACH ROW
BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be reduced';
    END IF;
END$$
DELIMITER ;
SHOW TRIGGERS LIKE 'Employee';

-- ### TASK 4: AFTER UPDATE trigger that records every salary change in Salary_Audit
-- Only when the salary actually changed (NEW.salary <> OLD.salary), so updating other columns does not create audit rows.
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

-- ### TASK 5: BEFORE INSERT trigger that sets salary to 20000 if inserted as NULL
-- The column is NOT NULL, but a BEFORE trigger runs before the NOT NULL check, so replacing NEW.salary makes the INSERT legal.
-- The new row is rolled back afterwards so later tasks see the five rows of the PDF.
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

-- ### TASK 6: Procedure give_raise(IN d, IN pct) with a cursor that prints each new salary
-- The cursor loops over the employees of one department; each iteration raises the salary and SELECTs a message (a "print").
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

-- ### TASK 7: Call give_raise('IT', 10) and display Employee and Salary_Audit
-- Anil 60000 -> 66000, Bharti 55000 -> 60500; the AFTER UPDATE trigger writes two audit rows.
CALL give_raise('IT', 10);
SELECT * FROM Employee;
SELECT audit_id, emp_id, old_salary, new_salary FROM Salary_Audit;

-- ### TASK 8: Reduce Chirag's salary to 30000 - trigger error
-- 30000 < 40000, so trg_emp_no_decrease signals "Salary cannot be reduced"; the row keeps 40000 and no audit row is written.
UPDATE Employee SET salary = 30000 WHERE name = 'Chirag';
SELECT emp_id, name, salary FROM Employee WHERE name = 'Chirag';

-- ### TASK 9: Function annual_tax(emp_id) - 0% up to 5,00,000 annual, 10% above; list every employee with tax
-- annual = monthly salary x 12; tax = 10% of (annual - 500000) when annual > 500000. Anil 792000 -> 29200, Bharti 726000 -> 22600, Deepa 504000 -> 400, others 0.
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

-- ### TASK 10: Procedure dept_stats(IN d, OUT total, OUT avg_sal) and call it
-- OUT parameters are filled by the procedure and read back through user variables in the same session.
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

-- ### TASK 11: Exception handling (DECLARE ... HANDLER) in give_raise for an invalid department
-- The new version first checks that the department exists and SIGNALs otherwise; an EXIT HANDLER catches any SQL exception, reads its text with
-- GET DIAGNOSTICS and returns it as a normal result instead of an error. Valid departments behave exactly as before.
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

-- ### TASK 12: Run give_raise inside a transaction and ROLLBACK; salaries are restored
-- The procedure itself does not commit, so the caller controls the transaction: the raise (and its audit rows) disappear on ROLLBACK.
SELECT COUNT(*) AS audit_rows_before FROM Salary_Audit;
START TRANSACTION;
CALL give_raise('HR', 20);
SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR';
ROLLBACK;
SELECT emp_id, name, salary FROM Employee WHERE dept = 'HR';
SELECT COUNT(*) AS audit_rows_after FROM Salary_Audit;

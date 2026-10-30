-- Experiment 4B - additional examiner-style queries (run after 03)
USE payroll_4b;

-- ### ADV 1: Total tax payable by the company
SELECT SUM(annual_tax(emp_id)) AS total_tax FROM Employee;

-- ### ADV 2: Highest paid employee of each department using a correlated subquery
SELECT name, dept, salary FROM Employee e WHERE salary = (SELECT MAX(salary) FROM Employee x WHERE x.dept = e.dept);

-- ### ADV 3: Audit trail with the percentage change
SELECT emp_id, old_salary, new_salary, ROUND((new_salary - old_salary) / old_salary * 100, 2) AS pct_change FROM Salary_Audit;

-- ### ADV 4: Equal salary update is allowed and creates no audit row
-- The BEFORE trigger only rejects a LOWER salary; the AFTER trigger logs only real changes.
SELECT COUNT(*) AS audit_before FROM Salary_Audit;
UPDATE Employee SET salary = salary WHERE emp_id = 3;
SELECT COUNT(*) AS audit_after FROM Salary_Audit;

-- ### ADV 5: Trigger rejecting a decrease also protects bulk updates
-- The whole UPDATE fails and is rolled back as one statement, no employee is changed.
SELECT SUM(salary) AS payroll_before FROM Employee;
UPDATE Employee SET salary = salary - 1000;
SELECT SUM(salary) AS payroll_after FROM Employee;

-- ### ADV 6: Dept_stats for an unknown department returns NULLs (no error)
CALL dept_stats('Marketing', @t, @a);
SELECT @t AS total, @a AS average;

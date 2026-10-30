-- Experiment 2A - additional examiner-style queries
USE emp_2a;

-- ### ADV 1: Third highest salary using LIMIT/OFFSET on distinct salaries
SELECT DISTINCT salary FROM Employee ORDER BY salary DESC LIMIT 1 OFFSET 2;

-- ### ADV 2: Managers with the number of direct reports
SELECT m.ename AS manager, COUNT(*) AS reports FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id GROUP BY m.emp_id, m.ename ORDER BY reports DESC;

-- ### ADV 3: Employees earning more than their own manager
SELECT e.ename, e.salary, m.ename AS manager, m.salary AS manager_salary FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id WHERE e.salary > m.salary;

-- ### ADV 4: Departments with no employees using NOT EXISTS
SELECT d.dept_name FROM Department d WHERE NOT EXISTS (SELECT 1 FROM Employee e WHERE e.dept_no = d.dept_no);

-- ### ADV 5: Salary rank within each department
SELECT ename, dept_no, salary, RANK() OVER (PARTITION BY dept_no ORDER BY salary DESC) AS dept_rank FROM Employee WHERE dept_no IS NOT NULL;

-- ### ADV 6: Employees earning more than ANY Analyst
-- ANY = greater than the minimum Analyst salary (60000).
SELECT ename, salary FROM Employee WHERE salary > ANY (SELECT salary FROM Employee WHERE job = 'Analyst');

-- ### ADV 7: FULL OUTER JOIN emulation (MySQL has none) - all employees and all departments
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d USING (dept_no)
UNION
SELECT e.ename, d.dept_name FROM Employee e RIGHT JOIN Department d USING (dept_no);

-- ### ADV 8: Updatable view with CHECK OPTION blocks rows leaving the view
-- Moving an Analyst to salary 10 would still pass, but changing job to 'Clerk' violates the view predicate -> error 1369.
CREATE OR REPLACE VIEW analysts AS SELECT emp_id, ename, job, salary FROM Employee WHERE job = 'Analyst' WITH CHECK OPTION;
UPDATE analysts SET job = 'Clerk' WHERE emp_id = 3;
DROP VIEW analysts;

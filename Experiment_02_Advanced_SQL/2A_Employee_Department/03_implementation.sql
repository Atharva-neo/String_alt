-- Experiment 2A - Employee-Department : 12 tasks
/* @CONCEPTS
* **INNER JOIN** keeps only matching rows (Nikhil, who has no department, disappears). **LEFT JOIN** keeps all rows of the left table; **RIGHT JOIN** is the mirror image.
* **Self join**: the same table used twice with different aliases (employee `e`, manager `m`).
* **Correlated subquery**: the inner query refers to the outer row and is evaluated once per outer row.
* `> ALL (subquery)` = greater than the maximum; `> ANY (subquery)` = greater than the minimum.
* **WHERE** filters rows, **HAVING** filters groups. Window functions (`DENSE_RANK`) are MySQL 8 / Oracle.
* A view is a stored SELECT; a *simple* view (one table, no aggregates/DISTINCT/GROUP BY) is updatable, a *complex* one is not.
*/

-- ### TASK 1: Employee name with department name (INNER JOIN)
-- Only employees whose dept_no matches a department are returned: 7 rows (Nikhil has NULL dept_no and is excluded).
SELECT e.ename, d.dept_name FROM Employee e INNER JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id;

-- ### TASK 2: All departments with their employees, including empty departments (LEFT JOIN)
-- Department is the left table so Operations (40) appears once with NULL employee columns.
SELECT d.dept_no, d.dept_name, e.ename FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no ORDER BY d.dept_no, e.emp_id;

-- ### TASK 3: All employees including those without a department (LEFT and RIGHT join forms)
-- Both statements return the same 8 rows; Nikhil shows NULL dept_name. RIGHT JOIN is simply LEFT JOIN with the tables swapped.
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id;
SELECT e.ename, d.dept_name FROM Department d RIGHT JOIN Employee e ON d.dept_no = e.dept_no ORDER BY e.emp_id;

-- ### TASK 4: Employee with the name of their manager (self join)
-- LEFT JOIN so the president (manager_id NULL) is still listed with NULL manager.
SELECT e.ename AS employee, m.ename AS manager FROM Employee e LEFT JOIN Employee m ON m.emp_id = e.manager_id ORDER BY e.emp_id;

-- ### TASK 5: Employees earning more than the average of their own department (correlated subquery)
-- For each outer row the inner AVG is recomputed for that row's dept_no. Averages: dept 10=150000, 20=71666.67, 30=52666.67.
SELECT e.ename, e.salary, e.dept_no FROM Employee e
WHERE e.salary > (SELECT AVG(x.salary) FROM Employee x WHERE x.dept_no = e.dept_no);

-- ### TASK 6: Employees earning more than every Salesman (ALL)
-- Salesmen earn 35000 and 38000, so `> ALL` means > 38000: every non-salesman except Nikhil (25000).
SELECT ename, job, salary FROM Employee WHERE salary > ALL (SELECT salary FROM Employee WHERE job = 'Salesman') ORDER BY salary DESC;

-- ### TASK 7: Department-wise count, total and average salary, only departments with more than 2 employees
-- GROUP BY dept_no then HAVING COUNT(*) > 2: Research (3) and Sales (3). Accounts (1) is filtered out. The NULL-department group is dropped by the INNER JOIN.
SELECT d.dept_name, COUNT(*) AS emp_count, SUM(e.salary) AS total_salary, ROUND(AVG(e.salary),2) AS avg_salary
FROM Employee e JOIN Department d ON d.dept_no = e.dept_no
GROUP BY d.dept_no, d.dept_name HAVING COUNT(*) > 2;

-- ### TASK 8: Employee(s) with the second highest salary
-- (a) Two nested MAX: highest salary below the maximum. (b) DENSE_RANK() handles ties and is easily generalised to "Nth highest".
SELECT ename, salary FROM Employee WHERE salary = (SELECT MAX(salary) FROM Employee WHERE salary < (SELECT MAX(salary) FROM Employee));
SELECT ename, salary FROM (SELECT ename, salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk FROM Employee) t WHERE rnk = 2;

-- ### TASK 9: Department with the highest total salary
-- Group by department, order by the sum descending, take one row. Research = 215000 (Anita 90000 + Rohit 60000 + Kavya 65000).
SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Employee e JOIN Department d USING (dept_no) GROUP BY d.dept_no, d.dept_name ORDER BY total_salary DESC LIMIT 1;

-- ### TASK 10: Employees hired after 2019 in Research, ordered by salary descending
-- "After 2019" is read as YEAR(hire_date) > 2019, so Rohit (2019-07-01) is excluded; only Kavya (2020-02-20) qualifies.
SELECT e.ename, e.hire_date, e.salary FROM Employee e JOIN Department d USING (dept_no) WHERE d.dept_name = 'Research' AND YEAR(e.hire_date) > 2019 ORDER BY e.salary DESC;

-- ### TASK 11: Views emp_no_dept and dept_summary
-- emp_no_dept is a simple filtered view; dept_summary is a complex (aggregating) view.
CREATE VIEW emp_no_dept AS SELECT emp_id, ename, job, salary FROM Employee WHERE dept_no IS NULL;
CREATE VIEW dept_summary AS SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no GROUP BY d.dept_no, d.dept_name;
SELECT * FROM emp_no_dept;
SELECT * FROM dept_summary;

-- ### TASK 12: Update a salary through a simple view, show base table, DROP the views
-- A simple view maps 1:1 to base rows, so UPDATE passes through (Nikhil 25000 -> 27000). The aggregate view is NOT updatable (error 1288).
UPDATE emp_no_dept SET salary = 27000 WHERE ename = 'Nikhil';
SELECT emp_id, ename, salary FROM Employee WHERE ename = 'Nikhil';
UPDATE dept_summary SET total_salary = 1 WHERE dept_name = 'Sales';
DROP VIEW emp_no_dept, dept_summary;
SHOW FULL TABLES WHERE Table_type = 'VIEW';

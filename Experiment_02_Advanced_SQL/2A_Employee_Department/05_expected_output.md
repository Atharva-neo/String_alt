# Expected output - Experiment_02_Advanced_SQL / 2A_Employee_Department

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Employee name with department name (INNER JOIN)

```sql
SELECT e.ename, d.dept_name FROM Employee e INNER JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id;
```

**Output**

```text
SELECT e.ename, d.dept_name FROM Employee e INNER JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id

+---------+-----------+
| ename   | dept_name |
+---------+-----------+
| Suresh  | Accounts  |
| Anita   | Research  |
| Rohit   | Research  |
| Kavya   | Research  |
| Manoj   | Sales     |
| Tejas   | Sales     |
| Pallavi | Sales     |
+---------+-----------+
7 rows in set
```

**Why this output is correct:** Only employees whose dept_no matches a department are returned: 7 rows (Nikhil has NULL dept_no and is excluded).

### Task 2 - All departments with their employees, including empty departments (LEFT JOIN)

```sql
SELECT d.dept_no, d.dept_name, e.ename FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no ORDER BY d.dept_no, e.emp_id;
```

**Output**

```text
SELECT d.dept_no, d.dept_name, e.ename FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no ORDER BY d.dept_no, e.emp_id

+---------+------------+---------+
| dept_no | dept_name  | ename   |
+---------+------------+---------+
|      10 | Accounts   | Suresh  |
|      20 | Research   | Anita   |
|      20 | Research   | Rohit   |
|      20 | Research   | Kavya   |
|      30 | Sales      | Manoj   |
|      30 | Sales      | Tejas   |
|      30 | Sales      | Pallavi |
|      40 | Operations | NULL    |
+---------+------------+---------+
8 rows in set
```

**Why this output is correct:** Department is the left table so Operations (40) appears once with NULL employee columns.

### Task 3 - All employees including those without a department (LEFT and RIGHT join forms)

```sql
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id;
SELECT e.ename, d.dept_name FROM Department d RIGHT JOIN Employee e ON d.dept_no = e.dept_no ORDER BY e.emp_id;
```

**Output**

```text
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d ON d.dept_no = e.dept_no ORDER BY e.emp_id

+---------+-----------+
| ename   | dept_name |
+---------+-----------+
| Suresh  | Accounts  |
| Anita   | Research  |
| Rohit   | Research  |
| Kavya   | Research  |
| Manoj   | Sales     |
| Tejas   | Sales     |
| Pallavi | Sales     |
| Nikhil  | NULL      |
+---------+-----------+
8 rows in set

SELECT e.ename, d.dept_name FROM Department d RIGHT JOIN Employee e ON d.dept_no = e.dept_no ORDER BY e.emp_id

+---------+-----------+
| ename   | dept_name |
+---------+-----------+
| Suresh  | Accounts  |
| Anita   | Research  |
| Rohit   | Research  |
| Kavya   | Research  |
| Manoj   | Sales     |
| Tejas   | Sales     |
| Pallavi | Sales     |
| Nikhil  | NULL      |
+---------+-----------+
8 rows in set
```

**Why this output is correct:** Both statements return the same 8 rows; Nikhil shows NULL dept_name. RIGHT JOIN is simply LEFT JOIN with the tables swapped.

### Task 4 - Employee with the name of their manager (self join)

```sql
SELECT e.ename AS employee, m.ename AS manager FROM Employee e LEFT JOIN Employee m ON m.emp_id = e.manager_id ORDER BY e.emp_id;
```

**Output**

```text
SELECT e.ename AS employee, m.ename AS manager FROM Employee e LEFT JOIN Employee m ON m.emp_id = e.manager_id ORDER BY e.emp_id

+----------+---------+
| employee | manager |
+----------+---------+
| Suresh   | NULL    |
| Anita    | Suresh  |
| Rohit    | Anita   |
| Kavya    | Anita   |
| Manoj    | Suresh  |
| Tejas    | Manoj   |
| Pallavi  | Manoj   |
| Nikhil   | Suresh  |
+----------+---------+
8 rows in set
```

**Why this output is correct:** LEFT JOIN so the president (manager_id NULL) is still listed with NULL manager.

### Task 5 - Employees earning more than the average of their own department (correlated subquery)

```sql
SELECT e.ename, e.salary, e.dept_no FROM Employee e
WHERE e.salary > (SELECT AVG(x.salary) FROM Employee x WHERE x.dept_no = e.dept_no);
```

**Output**

```text
SELECT e.ename, e.salary, e.dept_no FROM Employee e
WHERE e.salary > (SELECT AVG(x.salary) FROM Employee x WHERE x.dept_no = e.dept_no)

+-------+--------+---------+
| ename | salary | dept_no |
+-------+--------+---------+
| Anita |  90000 |      20 |
| Manoj |  85000 |      30 |
+-------+--------+---------+
2 rows in set
```

**Why this output is correct:** For each outer row the inner AVG is recomputed for that row's dept_no. Averages: dept 10=150000, 20=71666.67, 30=52666.67.

### Task 6 - Employees earning more than every Salesman (ALL)

```sql
SELECT ename, job, salary FROM Employee WHERE salary > ALL (SELECT salary FROM Employee WHERE job = 'Salesman') ORDER BY salary DESC;
```

**Output**

```text
SELECT ename, job, salary FROM Employee WHERE salary > ALL (SELECT salary FROM Employee WHERE job = 'Salesman') ORDER BY salary DESC

+--------+-----------+--------+
| ename  | job       | salary |
+--------+-----------+--------+
| Suresh | President | 150000 |
| Anita  | Manager   |  90000 |
| Manoj  | Manager   |  85000 |
| Kavya  | Analyst   |  65000 |
| Rohit  | Analyst   |  60000 |
+--------+-----------+--------+
5 rows in set
```

**Why this output is correct:** Salesmen earn 35000 and 38000, so `> ALL` means > 38000: every non-salesman except Nikhil (25000).

### Task 7 - Department-wise count, total and average salary, only departments with more than 2 employees

```sql
SELECT d.dept_name, COUNT(*) AS emp_count, SUM(e.salary) AS total_salary, ROUND(AVG(e.salary),2) AS avg_salary
FROM Employee e JOIN Department d ON d.dept_no = e.dept_no
GROUP BY d.dept_no, d.dept_name HAVING COUNT(*) > 2;
```

**Output**

```text
SELECT d.dept_name, COUNT(*) AS emp_count, SUM(e.salary) AS total_salary, ROUND(AVG(e.salary),2) AS avg_salary
FROM Employee e JOIN Department d ON d.dept_no = e.dept_no
GROUP BY d.dept_no, d.dept_name HAVING COUNT(*) > 2

+-----------+-----------+--------------+------------+
| dept_name | emp_count | total_salary | avg_salary |
+-----------+-----------+--------------+------------+
| Research  |         3 |       215000 |   71666.67 |
| Sales     |         3 |       158000 |   52666.67 |
+-----------+-----------+--------------+------------+
2 rows in set
```

**Why this output is correct:** GROUP BY dept_no then HAVING COUNT(*) > 2: Research (3) and Sales (3). Accounts (1) is filtered out. The NULL-department group is dropped by the INNER JOIN.

### Task 8 - Employee(s) with the second highest salary

```sql
SELECT ename, salary FROM Employee WHERE salary = (SELECT MAX(salary) FROM Employee WHERE salary < (SELECT MAX(salary) FROM Employee));
SELECT ename, salary FROM (SELECT ename, salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk FROM Employee) t WHERE rnk = 2;
```

**Output**

```text
SELECT ename, salary FROM Employee WHERE salary = (SELECT MAX(salary) FROM Employee WHERE salary < (SELECT MAX(salary) FROM Employee))

+-------+--------+
| ename | salary |
+-------+--------+
| Anita |  90000 |
+-------+--------+
1 row in set

SELECT ename, salary FROM (SELECT ename, salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk FROM Employee) t WHERE rnk = 2

+-------+--------+
| ename | salary |
+-------+--------+
| Anita |  90000 |
+-------+--------+
1 row in set
```

**Why this output is correct:** (a) Two nested MAX: highest salary below the maximum. (b) DENSE_RANK() handles ties and is easily generalised to "Nth highest".

### Task 9 - Department with the highest total salary

```sql
SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Employee e JOIN Department d USING (dept_no) GROUP BY d.dept_no, d.dept_name ORDER BY total_salary DESC LIMIT 1;
```

**Output**

```text
SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Employee e JOIN Department d USING (dept_no) GROUP BY d.dept_no, d.dept_name ORDER BY total_salary DESC LIMIT 1

+-----------+--------------+
| dept_name | total_salary |
+-----------+--------------+
| Research  |       215000 |
+-----------+--------------+
1 row in set
```

**Why this output is correct:** Group by department, order by the sum descending, take one row. Research = 215000 (Anita 90000 + Rohit 60000 + Kavya 65000).

### Task 10 - Employees hired after 2019 in Research, ordered by salary descending

```sql
SELECT e.ename, e.hire_date, e.salary FROM Employee e JOIN Department d USING (dept_no) WHERE d.dept_name = 'Research' AND YEAR(e.hire_date) > 2019 ORDER BY e.salary DESC;
```

**Output**

```text
SELECT e.ename, e.hire_date, e.salary FROM Employee e JOIN Department d USING (dept_no) WHERE d.dept_name = 'Research' AND YEAR(e.hire_date) > 2019 ORDER BY e.salary DESC

+-------+------------+--------+
| ename | hire_date  | salary |
+-------+------------+--------+
| Kavya | 2020-02-20 |  65000 |
+-------+------------+--------+
1 row in set
```

**Why this output is correct:** "After 2019" is read as YEAR(hire_date) > 2019, so Rohit (2019-07-01) is excluded; only Kavya (2020-02-20) qualifies.

### Task 11 - Views emp_no_dept and dept_summary

```sql
CREATE VIEW emp_no_dept AS SELECT emp_id, ename, job, salary FROM Employee WHERE dept_no IS NULL;
CREATE VIEW dept_summary AS SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no GROUP BY d.dept_no, d.dept_name;
SELECT * FROM emp_no_dept;
SELECT * FROM dept_summary;
```

**Output**

```text
CREATE VIEW emp_no_dept AS SELECT emp_id, ename, job, salary FROM Employee WHERE dept_no IS NULL

Query OK, 0 rows affected

CREATE VIEW dept_summary AS SELECT d.dept_name, SUM(e.salary) AS total_salary FROM Department d LEFT JOIN Employee e ON e.dept_no = d.dept_no GROUP BY d.dept_no, d.dept_name

Query OK, 0 rows affected

SELECT * FROM emp_no_dept

+--------+--------+-------+--------+
| emp_id | ename  | job   | salary |
+--------+--------+-------+--------+
|      8 | Nikhil | Clerk |  25000 |
+--------+--------+-------+--------+
1 row in set

SELECT * FROM dept_summary

+------------+--------------+
| dept_name  | total_salary |
+------------+--------------+
| Accounts   |       150000 |
| Research   |       215000 |
| Sales      |       158000 |
| Operations |         NULL |
+------------+--------------+
4 rows in set
```

**Why this output is correct:** emp_no_dept is a simple filtered view; dept_summary is a complex (aggregating) view.

### Task 12 - Update a salary through a simple view, show base table, DROP the views

```sql
UPDATE emp_no_dept SET salary = 27000 WHERE ename = 'Nikhil';
SELECT emp_id, ename, salary FROM Employee WHERE ename = 'Nikhil';
UPDATE dept_summary SET total_salary = 1 WHERE dept_name = 'Sales';
DROP VIEW emp_no_dept, dept_summary;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

**Output**

```text
UPDATE emp_no_dept SET salary = 27000 WHERE ename = 'Nikhil'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT emp_id, ename, salary FROM Employee WHERE ename = 'Nikhil'

+--------+--------+--------+
| emp_id | ename  | salary |
+--------+--------+--------+
|      8 | Nikhil |  27000 |
+--------+--------+--------+
1 row in set

UPDATE dept_summary SET total_salary = 1 WHERE dept_name = 'Sales'

ERROR 1288 (HY000) at line 3: The target table dept_summary of the UPDATE is not updatable
DROP VIEW emp_no_dept, dept_summary

Query OK, 0 rows affected

SHOW FULL TABLES WHERE Table_type = 'VIEW'

Empty set
```

**Why this output is correct:** A simple view maps 1:1 to base rows, so UPDATE passes through (Nikhil 25000 -> 27000). The aggregate view is NOT updatable (error 1288).


## Advanced / examiner-style queries

### Adv 1 - Third highest salary using LIMIT/OFFSET on distinct salaries

```sql
SELECT DISTINCT salary FROM Employee ORDER BY salary DESC LIMIT 1 OFFSET 2;
```

**Output**

```text
SELECT DISTINCT salary FROM Employee ORDER BY salary DESC LIMIT 1 OFFSET 2

+--------+
| salary |
+--------+
|  85000 |
+--------+
1 row in set
```

### Adv 2 - Managers with the number of direct reports

```sql
SELECT m.ename AS manager, COUNT(*) AS reports FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id GROUP BY m.emp_id, m.ename ORDER BY reports DESC;
```

**Output**

```text
SELECT m.ename AS manager, COUNT(*) AS reports FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id GROUP BY m.emp_id, m.ename ORDER BY reports DESC

+---------+---------+
| manager | reports |
+---------+---------+
| Suresh  |       3 |
| Anita   |       2 |
| Manoj   |       2 |
+---------+---------+
3 rows in set
```

### Adv 3 - Employees earning more than their own manager

```sql
SELECT e.ename, e.salary, m.ename AS manager, m.salary AS manager_salary FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id WHERE e.salary > m.salary;
```

**Output**

```text
SELECT e.ename, e.salary, m.ename AS manager, m.salary AS manager_salary FROM Employee e JOIN Employee m ON m.emp_id = e.manager_id WHERE e.salary > m.salary

Empty set
```

### Adv 4 - Departments with no employees using NOT EXISTS

```sql
SELECT d.dept_name FROM Department d WHERE NOT EXISTS (SELECT 1 FROM Employee e WHERE e.dept_no = d.dept_no);
```

**Output**

```text
SELECT d.dept_name FROM Department d WHERE NOT EXISTS (SELECT 1 FROM Employee e WHERE e.dept_no = d.dept_no)

+------------+
| dept_name  |
+------------+
| Operations |
+------------+
1 row in set
```

### Adv 5 - Salary rank within each department

```sql
SELECT ename, dept_no, salary, RANK() OVER (PARTITION BY dept_no ORDER BY salary DESC) AS dept_rank FROM Employee WHERE dept_no IS NOT NULL;
```

**Output**

```text
SELECT ename, dept_no, salary, RANK() OVER (PARTITION BY dept_no ORDER BY salary DESC) AS dept_rank FROM Employee WHERE dept_no IS NOT NULL

+---------+---------+--------+-----------+
| ename   | dept_no | salary | dept_rank |
+---------+---------+--------+-----------+
| Suresh  |      10 | 150000 |         1 |
| Anita   |      20 |  90000 |         1 |
| Kavya   |      20 |  65000 |         2 |
| Rohit   |      20 |  60000 |         3 |
| Manoj   |      30 |  85000 |         1 |
| Pallavi |      30 |  38000 |         2 |
| Tejas   |      30 |  35000 |         3 |
+---------+---------+--------+-----------+
7 rows in set
```

### Adv 6 - Employees earning more than ANY Analyst

```sql
SELECT ename, salary FROM Employee WHERE salary > ANY (SELECT salary FROM Employee WHERE job = 'Analyst');
```

**Output**

```text
SELECT ename, salary FROM Employee WHERE salary > ANY (SELECT salary FROM Employee WHERE job = 'Analyst')

+--------+--------+
| ename  | salary |
+--------+--------+
| Suresh | 150000 |
| Anita  |  90000 |
| Kavya  |  65000 |
| Manoj  |  85000 |
+--------+--------+
4 rows in set
```

**Why this output is correct:** ANY = greater than the minimum Analyst salary (60000).

### Adv 7 - FULL OUTER JOIN emulation (MySQL has none) - all employees and all departments

```sql
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d USING (dept_no)
UNION
SELECT e.ename, d.dept_name FROM Employee e RIGHT JOIN Department d USING (dept_no);
```

**Output**

```text
SELECT e.ename, d.dept_name FROM Employee e LEFT JOIN Department d USING (dept_no)
UNION
SELECT e.ename, d.dept_name FROM Employee e RIGHT JOIN Department d USING (dept_no)

+---------+------------+
| ename   | dept_name  |
+---------+------------+
| Suresh  | Accounts   |
| Anita   | Research   |
| Rohit   | Research   |
| Kavya   | Research   |
| Manoj   | Sales      |
| Tejas   | Sales      |
| Pallavi | Sales      |
| Nikhil  | NULL       |
| NULL    | Operations |
+---------+------------+
9 rows in set
```

### Adv 8 - Updatable view with CHECK OPTION blocks rows leaving the view

```sql
CREATE OR REPLACE VIEW analysts AS SELECT emp_id, ename, job, salary FROM Employee WHERE job = 'Analyst' WITH CHECK OPTION;
UPDATE analysts SET job = 'Clerk' WHERE emp_id = 3;
DROP VIEW analysts;
```

**Output**

```text
CREATE OR REPLACE VIEW analysts AS SELECT emp_id, ename, job, salary FROM Employee WHERE job = 'Analyst' WITH CHECK OPTION

Query OK, 0 rows affected

UPDATE analysts SET job = 'Clerk' WHERE emp_id = 3

ERROR 1369 (HY000) at line 2: CHECK OPTION failed 'emp_2a.analysts'
DROP VIEW analysts

Query OK, 0 rows affected
```

**Why this output is correct:** Moving an Analyst to salary 10 would still pass, but changing job to 'Clerk' violates the view predicate -> error 1369.

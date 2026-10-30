# Expected output - Experiment_03_Normalization_BCNF / 3C_Employee_Project

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Identify the non-atomic attribute and convert to atomic values (1NF)

```sql
SELECT EmpID, Skills FROM Employee_Project_UNF WHERE Skills LIKE '%,%';
SELECT * FROM EP_1NF ORDER BY EmpID, ProjectID, Skill;
```

**Output**

```text
SELECT EmpID, Skills FROM Employee_Project_UNF WHERE Skills LIKE '%,%'

+-------+--------------+
| EmpID | Skills       |
+-------+--------------+
| E1    | Python, SQL  |
| E1    | Python, SQL  |
| E3    | SQL, Tableau |
+-------+--------------+
3 rows in set

SELECT * FROM EP_1NF ORDER BY EmpID, ProjectID, Skill

+-------+---------+--------+----------+-----------+-------------+-------+---------+
| EmpID | EmpName | DeptID | DeptName | ProjectID | ProjectName | Hours | Skill   |
+-------+---------+--------+----------+-----------+-------------+-------+---------+
| E1    | Ravi    | D1     | R&D      | PR1       | Chatbot     |    20 | Python  |
| E1    | Ravi    | D1     | R&D      | PR1       | Chatbot     |    20 | SQL     |
| E1    | Ravi    | D1     | R&D      | PR2       | Vision      |    15 | Python  |
| E1    | Ravi    | D1     | R&D      | PR2       | Vision      |    15 | SQL     |
| E2    | Sneha   | D2     | IT       | PR1       | Chatbot     |    30 | Java    |
| E3    | Amol    | D1     | R&D      | PR3       | Analytics   |    25 | SQL     |
| E3    | Amol    | D1     | R&D      | PR3       | Analytics   |    25 | Tableau |
+-------+---------+--------+----------+-----------+-------------+-------+---------+
7 rows in set
```

**Why this output is correct:** Skills holds 'Python, SQL' / 'SQL, Tableau'. The 1NF table EP_1NF repeats the project row once per skill (7 rows instead of 4).

### Task 2 - Anomalies in the original table

```sql
INSERT INTO Employee_Project_UNF (DeptID, DeptName) VALUES ('D3', 'Finance');
START TRANSACTION;
UPDATE Employee_Project_UNF SET DeptName = 'Research' WHERE EmpID = 'E1' AND ProjectID = 'PR1';
SELECT DeptID, DeptName, COUNT(*) AS rows_ FROM Employee_Project_UNF WHERE DeptID = 'D1' GROUP BY DeptID, DeptName;
ROLLBACK;
START TRANSACTION;
DELETE FROM Employee_Project_UNF WHERE EmpID = 'E2';
SELECT DISTINCT DeptID, DeptName FROM Employee_Project_UNF;
ROLLBACK;
```

**Output**

```text
INSERT INTO Employee_Project_UNF (DeptID, DeptName) VALUES ('D3', 'Finance')

ERROR 1364 (HY000) at line 1: Field 'EmpID' doesn't have a default value
START TRANSACTION

Query OK, 0 rows affected

UPDATE Employee_Project_UNF SET DeptName = 'Research' WHERE EmpID = 'E1' AND ProjectID = 'PR1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT DeptID, DeptName, COUNT(*) AS rows_ FROM Employee_Project_UNF WHERE DeptID = 'D1' GROUP BY DeptID, DeptName

+--------+----------+-------+
| DeptID | DeptName | rows_ |
+--------+----------+-------+
| D1     | Research |     1 |
| D1     | R&D      |     2 |
+--------+----------+-------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

DELETE FROM Employee_Project_UNF WHERE EmpID = 'E2'

Query OK, 1 row affected

SELECT DISTINCT DeptID, DeptName FROM Employee_Project_UNF

+--------+----------+
| DeptID | DeptName |
+--------+----------+
| D1     | R&D      |
+--------+----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** INSERT: a new project PR9 or a new department D3 cannot be stored without an employee (EmpID part of the key) -> error. UPDATE: department of Ravi stored in 2 rows (4 in 1NF); changing 1 row leaves D1 with two names. DELETE: deleting Sneha's only row deletes the fact that department D2 is called IT.

### Task 3 - Find the candidate key

```sql
SELECT COUNT(*) AS rows_, COUNT(DISTINCT EmpID, ProjectID) AS pairs, COUNT(DISTINCT EmpID, ProjectID, Skill) AS triples FROM EP_1NF;
```

**Output**

```text
SELECT COUNT(*) AS rows_, COUNT(DISTINCT EmpID, ProjectID) AS pairs, COUNT(DISTINCT EmpID, ProjectID, Skill) AS triples FROM EP_1NF

+-------+-------+---------+
| rows_ | pairs | triples |
+-------+-------+---------+
|     7 |     4 |       7 |
+-------+-------+---------+
1 row in set
```

**Why this output is correct:** EmpID+ = {EmpID, EmpName, DeptID, DeptName}; {EmpID,ProjectID}+ adds ProjectName and Hours but not Skill; Skill is on the right of no FD, so every key must contain it => the only candidate key is {EmpID, ProjectID, Skill} (fd_analysis.py).

### Task 4 - Partial and transitive dependencies

```sql
SELECT 'EmpID -> EmpName, DeptID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'ProjectID -> ProjectName', 'Partial' UNION ALL
SELECT '{EmpID, ProjectID} -> Hours', 'Partial (needs only 2 of the 3 key columns)' UNION ALL
SELECT 'DeptID -> DeptName', 'Transitive (EmpID -> DeptID -> DeptName)';
```

**Output**

```text
SELECT 'EmpID -> EmpName, DeptID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'ProjectID -> ProjectName', 'Partial' UNION ALL
SELECT '{EmpID, ProjectID} -> Hours', 'Partial (needs only 2 of the 3 key columns)' UNION ALL
SELECT 'DeptID -> DeptName', 'Transitive (EmpID -> DeptID -> DeptName)'

+-----------------------------+---------------------------------------------+
| fd                          | kind                                        |
+-----------------------------+---------------------------------------------+
| EmpID -> EmpName, DeptID    | Partial                                     |
| ProjectID -> ProjectName    | Partial                                     |
| {EmpID, ProjectID} -> Hours | Partial (needs only 2 of the 3 key columns) |
| DeptID -> DeptName          | Transitive (EmpID -> DeptID -> DeptName)    |
+-----------------------------+---------------------------------------------+
4 rows in set
```

**Why this output is correct:** Partial: EmpID -> EmpName, DeptID (EmpID is only part of the key); ProjectID -> ProjectName; {EmpID,ProjectID} -> Hours is partial w.r.t. the 3-column key (Skill missing). Transitive: EmpID -> DeptID -> DeptName.

### Task 5 - Normalise to 2NF and 3NF

```sql
CREATE TABLE Emp_2NF AS SELECT DISTINCT EmpID, EmpName, DeptID, DeptName FROM EP_1NF;
CREATE TABLE Project_2NF AS SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF;
CREATE TABLE Works_On_2NF AS SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF;
SELECT * FROM Emp_2NF; SELECT * FROM Project_2NF; SELECT * FROM Works_On_2NF;
DROP TABLE Emp_2NF, Project_2NF, Works_On_2NF;
```

**Output**

```text
CREATE TABLE Emp_2NF AS SELECT DISTINCT EmpID, EmpName, DeptID, DeptName FROM EP_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Project_2NF AS SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Works_On_2NF AS SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT * FROM Emp_2NF

+-------+---------+--------+----------+
| EmpID | EmpName | DeptID | DeptName |
+-------+---------+--------+----------+
| E1    | Ravi    | D1     | R&D      |
| E2    | Sneha   | D2     | IT       |
| E3    | Amol    | D1     | R&D      |
+-------+---------+--------+----------+
3 rows in set

SELECT * FROM Project_2NF

+-----------+-------------+
| ProjectID | ProjectName |
+-----------+-------------+
| PR1       | Chatbot     |
| PR2       | Vision      |
| PR3       | Analytics   |
+-----------+-------------+
3 rows in set

SELECT * FROM Works_On_2NF

+-------+-----------+-------+
| EmpID | ProjectID | Hours |
+-------+-----------+-------+
| E1    | PR1       |    20 |
| E1    | PR2       |    15 |
| E2    | PR1       |    30 |
| E3    | PR3       |    25 |
+-------+-----------+-------+
4 rows in set

DROP TABLE Emp_2NF, Project_2NF, Works_On_2NF

Query OK, 0 rows affected
```

**Why this output is correct:** 2NF: Employee(EmpID, EmpName, DeptID, DeptName), Project(ProjectID, ProjectName), Works_On(EmpID, ProjectID, Hours), Emp_Skill(EmpID, Skill). 3NF: split Department(DeptID, DeptName) out of Employee. (Tables are created in Task 7.)

### Task 6 - BCNF check and the multivalued dependency EmpID ->> Skills (4NF idea)

```sql
SELECT EmpID, Skill, COUNT(*) AS times_stored FROM EP_1NF GROUP BY EmpID, Skill HAVING COUNT(*) > 1;
```

**Output**

```text
SELECT EmpID, Skill, COUNT(*) AS times_stored FROM EP_1NF GROUP BY EmpID, Skill HAVING COUNT(*) > 1

+-------+--------+--------------+
| EmpID | Skill  | times_stored |
+-------+--------+--------------+
| E1    | Python |            2 |
| E1    | SQL    |            2 |
+-------+--------+--------------+
2 rows in set
```

**Why this output is correct:** All FD determinants are keys of the final tables => BCNF. But EP_1NF still stores Python/SQL for Ravi twice (once per project): that redundancy is not caused by an FD but by the MVD EmpID ->> Skill (skills are independent of projects). Fix: Emp_Skill(EmpID, Skill) separate from Works_On. The query shows the repetition.

### Task 7 - Create the tables in SQL with keys

```sql
CREATE TABLE Department (
    DeptID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    DeptName VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Employee (
    EmpID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    EmpName VARCHAR(40) NOT NULL,
    DeptID  VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_emp_dept FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
) ENGINE=InnoDB;
CREATE TABLE Project (
    ProjectID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    ProjectName VARCHAR(40) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Works_On (
    EmpID     VARCHAR(5) NOT NULL,
    ProjectID VARCHAR(5) NOT NULL,
    Hours     INT        NOT NULL,
    PRIMARY KEY (EmpID, ProjectID),
    CONSTRAINT fk_wo_emp  FOREIGN KEY (EmpID)     REFERENCES Employee(EmpID),
    CONSTRAINT fk_wo_proj FOREIGN KEY (ProjectID) REFERENCES Project(ProjectID),
    CONSTRAINT chk_wo_hours CHECK (Hours >= 0)
) ENGINE=InnoDB;
CREATE TABLE Emp_Skill (
    EmpID VARCHAR(5)  NOT NULL,
    Skill VARCHAR(30) NOT NULL,
    PRIMARY KEY (EmpID, Skill),
    CONSTRAINT fk_es_emp FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
) ENGINE=InnoDB;
SHOW TABLES;
```

**Output**

```text
CREATE TABLE Department (
    DeptID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    DeptName VARCHAR(30) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Employee (
    EmpID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    EmpName VARCHAR(40) NOT NULL,
    DeptID  VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_emp_dept FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Project (
    ProjectID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    ProjectName VARCHAR(40) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Works_On (
    EmpID     VARCHAR(5) NOT NULL,
    ProjectID VARCHAR(5) NOT NULL,
    Hours     INT        NOT NULL,
    PRIMARY KEY (EmpID, ProjectID),
    CONSTRAINT fk_wo_emp  FOREIGN KEY (EmpID)     REFERENCES Employee(EmpID),
    CONSTRAINT fk_wo_proj FOREIGN KEY (ProjectID) REFERENCES Project(ProjectID),
    CONSTRAINT chk_wo_hours CHECK (Hours >= 0)
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Emp_Skill (
    EmpID VARCHAR(5)  NOT NULL,
    Skill VARCHAR(30) NOT NULL,
    PRIMARY KEY (EmpID, Skill),
    CONSTRAINT fk_es_emp FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
) ENGINE=InnoDB

Query OK, 0 rows affected

SHOW TABLES

+----------------------+
| Tables_in_norm_3c    |
+----------------------+
| department           |
| emp_skill            |
| employee             |
| employee_project_unf |
| ep_1nf               |
| project              |
| works_on             |
+----------------------+
7 rows in set
```

### Task 8 - Insert the data

```sql
INSERT INTO Department SELECT DISTINCT DeptID, DeptName FROM EP_1NF;
INSERT INTO Employee   SELECT DISTINCT EmpID, EmpName, DeptID FROM EP_1NF;
INSERT INTO Project    SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF;
INSERT INTO Works_On   SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF;
INSERT INTO Emp_Skill  SELECT DISTINCT EmpID, Skill FROM EP_1NF;
SELECT (SELECT COUNT(*) FROM Department) AS depts, (SELECT COUNT(*) FROM Employee) AS emps, (SELECT COUNT(*) FROM Project) AS projects,
       (SELECT COUNT(*) FROM Works_On) AS works_on, (SELECT COUNT(*) FROM Emp_Skill) AS skills;
```

**Output**

```text
INSERT INTO Department SELECT DISTINCT DeptID, DeptName FROM EP_1NF

Query OK, 2 rows affected
Records: 2  Duplicates: 0  Warnings: 0

INSERT INTO Employee   SELECT DISTINCT EmpID, EmpName, DeptID FROM EP_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Project    SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Works_On   SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

INSERT INTO Emp_Skill  SELECT DISTINCT EmpID, Skill FROM EP_1NF

Query OK, 5 rows affected
Records: 5  Duplicates: 0  Warnings: 0

SELECT (SELECT COUNT(*) FROM Department) AS depts, (SELECT COUNT(*) FROM Employee) AS emps, (SELECT COUNT(*) FROM Project) AS projects,
       (SELECT COUNT(*) FROM Works_On) AS works_on, (SELECT COUNT(*) FROM Emp_Skill) AS skills

+-------+------+----------+----------+--------+
| depts | emps | projects | works_on | skills |
+-------+------+----------+----------+--------+
|     2 |    3 |        3 |        4 |      5 |
+-------+------+----------+----------+--------+
1 row in set
```

### Task 9 - Employees with total project hours

```sql
SELECT e.EmpID, e.EmpName, SUM(w.Hours) AS total_hours FROM Employee e JOIN Works_On w USING (EmpID) GROUP BY e.EmpID, e.EmpName;
```

**Output**

```text
SELECT e.EmpID, e.EmpName, SUM(w.Hours) AS total_hours FROM Employee e JOIN Works_On w USING (EmpID) GROUP BY e.EmpID, e.EmpName

+-------+---------+-------------+
| EmpID | EmpName | total_hours |
+-------+---------+-------------+
| E1    | Ravi    |          35 |
| E2    | Sneha   |          30 |
| E3    | Amol    |          25 |
+-------+---------+-------------+
3 rows in set
```

**Why this output is correct:** Ravi 20+15 = 35, Sneha 30, Amol 25.

### Task 10 - Each project with the employees working on it

```sql
SELECT p.ProjectID, p.ProjectName, GROUP_CONCAT(e.EmpName ORDER BY e.EmpName) AS employees FROM Project p JOIN Works_On w USING (ProjectID) JOIN Employee e USING (EmpID) GROUP BY p.ProjectID, p.ProjectName;
```

**Output**

```text
SELECT p.ProjectID, p.ProjectName, GROUP_CONCAT(e.EmpName ORDER BY e.EmpName) AS employees FROM Project p JOIN Works_On w USING (ProjectID) JOIN Employee e USING (EmpID) GROUP BY p.ProjectID, p.ProjectName

+-----------+-------------+------------+
| ProjectID | ProjectName | employees  |
+-----------+-------------+------------+
| PR1       | Chatbot     | Ravi,Sneha |
| PR2       | Vision      | Ravi       |
| PR3       | Analytics   | Amol       |
+-----------+-------------+------------+
3 rows in set
```

**Why this output is correct:** GROUP_CONCAT collapses the employee names of one project into one cell (Oracle: LISTAGG).

### Task 11 - Employees who know both Python and SQL

```sql
SELECT e.EmpName FROM Employee e JOIN Emp_Skill s USING (EmpID) WHERE s.Skill IN ('Python', 'SQL') GROUP BY e.EmpID, e.EmpName HAVING COUNT(DISTINCT s.Skill) = 2;
```

**Output**

```text
SELECT e.EmpName FROM Employee e JOIN Emp_Skill s USING (EmpID) WHERE s.Skill IN ('Python', 'SQL') GROUP BY e.EmpID, e.EmpName HAVING COUNT(DISTINCT s.Skill) = 2

+---------+
| EmpName |
+---------+
| Ravi    |
+---------+
1 row in set
```

**Why this output is correct:** Group the skill rows per employee and require both skills to be present. Only Ravi.

### Task 12 - Department with the highest total project hours

```sql
SELECT d.DeptName, SUM(w.Hours) AS total_hours FROM Department d JOIN Employee e USING (DeptID) JOIN Works_On w USING (EmpID) GROUP BY d.DeptID, d.DeptName ORDER BY total_hours DESC LIMIT 1;
```

**Output**

```text
SELECT d.DeptName, SUM(w.Hours) AS total_hours FROM Department d JOIN Employee e USING (DeptID) JOIN Works_On w USING (EmpID) GROUP BY d.DeptID, d.DeptName ORDER BY total_hours DESC LIMIT 1

+----------+-------------+
| DeptName | total_hours |
+----------+-------------+
| R&D      |          60 |
+----------+-------------+
1 row in set
```

**Why this output is correct:** R&D: Ravi 35 + Amol 25 = 60; IT: Sneha 30.


## Advanced / examiner-style queries

### Adv 1 - Reconstruct the 1NF table (lossless-join check)

```sql
CREATE VIEW ep_rebuilt AS
SELECT e.EmpID, e.EmpName, d.DeptID, d.DeptName, p.ProjectID, p.ProjectName, w.Hours, s.Skill
FROM Employee e JOIN Department d USING (DeptID) JOIN Works_On w USING (EmpID) JOIN Project p USING (ProjectID) JOIN Emp_Skill s USING (EmpID);
SELECT COUNT(*) AS rebuilt_rows,
       (SELECT COUNT(*) FROM EP_1NF o WHERE NOT EXISTS (SELECT 1 FROM ep_rebuilt r WHERE r.EmpID=o.EmpID AND r.ProjectID=o.ProjectID AND r.Skill=o.Skill AND r.Hours=o.Hours AND r.DeptName=o.DeptName)) AS missing
FROM ep_rebuilt;
```

**Output**

```text
CREATE VIEW ep_rebuilt AS
SELECT e.EmpID, e.EmpName, d.DeptID, d.DeptName, p.ProjectID, p.ProjectName, w.Hours, s.Skill
FROM Employee e JOIN Department d USING (DeptID) JOIN Works_On w USING (EmpID) JOIN Project p USING (ProjectID) JOIN Emp_Skill s USING (EmpID)

Query OK, 0 rows affected

SELECT COUNT(*) AS rebuilt_rows,
       (SELECT COUNT(*) FROM EP_1NF o WHERE NOT EXISTS (SELECT 1 FROM ep_rebuilt r WHERE r.EmpID=o.EmpID AND r.ProjectID=o.ProjectID AND r.Skill=o.Skill AND r.Hours=o.Hours AND r.DeptName=o.DeptName)) AS missing
FROM ep_rebuilt

+--------------+---------+
| rebuilt_rows | missing |
+--------------+---------+
|            7 |       0 |
+--------------+---------+
1 row in set
```

**Why this output is correct:** Joining Employee-Department-Works_On-Project-Emp_Skill gives 7 rows, identical to EP_1NF.

### Adv 2 - Add a skill for Sneha without touching any project row

```sql
INSERT INTO Emp_Skill VALUES ('E2', 'SQL');
SELECT * FROM Emp_Skill WHERE EmpID = 'E2';
```

**Output**

```text
INSERT INTO Emp_Skill VALUES ('E2', 'SQL')

Query OK, 1 row affected

SELECT * FROM Emp_Skill WHERE EmpID = 'E2'

+-------+-------+
| EmpID | Skill |
+-------+-------+
| E2    | Java  |
| E2    | SQL   |
+-------+-------+
2 rows in set
```

**Why this output is correct:** With Emp_Skill the MVD no longer forces extra project rows.

### Adv 3 - In EP_1NF the same change needs one row per project

```sql
SELECT COUNT(*) AS rows_needed_in_1nf_to_add_one_skill_for_ravi FROM Works_On WHERE EmpID = 'E1';
```

**Output**

```text
SELECT COUNT(*) AS rows_needed_in_1nf_to_add_one_skill_for_ravi FROM Works_On WHERE EmpID = 'E1'

+----------------------------------------------+
| rows_needed_in_1nf_to_add_one_skill_for_ravi |
+----------------------------------------------+
|                                            2 |
+----------------------------------------------+
1 row in set
```

**Why this output is correct:** Sneha works on one project only, but Ravi (2 projects) adding a skill 'Docker' would need 2 new rows:

### Adv 4 - Employees without any project

```sql
SELECT e.EmpName FROM Employee e LEFT JOIN Works_On w USING (EmpID) WHERE w.ProjectID IS NULL;
```

**Output**

```text
SELECT e.EmpName FROM Employee e LEFT JOIN Works_On w USING (EmpID) WHERE w.ProjectID IS NULL

Empty set
```

### Adv 5 - Duplicate skill for the same employee

```sql
INSERT INTO Emp_Skill VALUES ('E1', 'SQL');
```

**Output**

```text
INSERT INTO Emp_Skill VALUES ('E1', 'SQL')

ERROR 1062 (23000) at line 1: Duplicate entry 'E1-SQL' for key 'emp_skill.PRIMARY'
```

**Why this output is correct:** Error 1062: the composite key (EmpID, Skill) prevents it.

### Adv 6 - Negative hours

```sql
INSERT INTO Works_On VALUES ('E2', 'PR3', -5);
```

**Output**

```text
INSERT INTO Works_On VALUES ('E2', 'PR3', -5)

ERROR 3819 (HY000) at line 1: Check constraint 'chk_wo_hours' is violated.
```

**Why this output is correct:** Error 3819.


## Functional-dependency analysis (Python, `fd_analysis.py`)

```text
=== 3C: EP_1NF (Skills made atomic; Skill is determined by nothing, so it joins the key) ===
Attributes : {DeptID, DeptName, EmpID, EmpName, Hours, ProjectID, ProjectName, Skill}
FDs        : {EmpID} -> {DeptID, EmpName}; {DeptID} -> {DeptName}; {ProjectID} -> {ProjectName}; {EmpID, ProjectID} -> {Hours}
Closure {EmpID}+ = {DeptID, DeptName, EmpID, EmpName}
Closure {EmpID, ProjectID}+ = {DeptID, DeptName, EmpID, EmpName, Hours, ProjectID, ProjectName}
Closure {EmpID, ProjectID, Skill}+ = {DeptID, DeptName, EmpID, EmpName, Hours, ProjectID, ProjectName, Skill}
Candidate keys : {EmpID, ProjectID, Skill}
Prime attributes : {EmpID, ProjectID, Skill}
Partial dependencies (2NF violations) : {EmpID}->{DeptID, DeptName, EmpName}; {ProjectID}->{ProjectName}; {EmpID, ProjectID}->{Hours}
3NF violations : {DeptID}->{DeptName}; {EmpID}->{DeptID, DeptName, EmpName}; {ProjectID}->{ProjectName}; {EmpID, ProjectID}->{Hours}
BCNF violations : {DeptID}->{DeptName}; {EmpID}->{DeptID, DeptName, EmpName}; {ProjectID}->{ProjectName}; {EmpID, ProjectID}->{Hours}

=== 3C: FD part (Skill removed) -> Department | Employee | Project | Works_On ===
Attributes : {DeptID, DeptName, EmpID, EmpName, Hours, ProjectID, ProjectName}
FDs        : {EmpID} -> {DeptID, EmpName}; {DeptID} -> {DeptName}; {ProjectID} -> {ProjectName}; {EmpID, ProjectID} -> {Hours}
Decomposition : {DeptID, DeptName} | {DeptID, EmpID, EmpName} | {ProjectID, ProjectName} | {EmpID, Hours, ProjectID}
Lossless join : True
Dependency preserving : True 
  relation {DeptID, DeptName}: keys ['{DeptID}'], BCNF violations none
  relation {DeptID, EmpID, EmpName}: keys ['{EmpID}'], BCNF violations none
  relation {ProjectID, ProjectName}: keys ['{ProjectID}'], BCNF violations none
  relation {EmpID, Hours, ProjectID}: keys ['{EmpID, ProjectID}'], BCNF violations none

=== 3C: MVD EmpID ->> Skill checked on the data ===
rows in EP_1NF                : 7
rows in Emp_Skill projection  : 5 [('E1', 'Python'), ('E1', 'SQL'), ('E2', 'Java'), ('E3', 'SQL'), ('E3', 'Tableau')]
rows in 'rest' projection     : 4
natural join reproduces 1NF   : True (7 rows)
```

-- Experiment 3C - Employee_Project : 12 tasks
/* @CONCEPTS
* **Atomicity**: Skills = 'Python, SQL' is a list, so the table is not in 1NF.
* **Multivalued dependency** `EmpID ->> Skill`: an employee's skills are independent of the projects he works on. Storing both in one relation forces every skill to be repeated for every project (and the other way round).
* **4NF idea**: a relation with two independent multivalued facts about the same key is split so that each fact has its own table (Emp_Skill and Works_On).
* Candidate key of the 1NF relation = {EmpID, ProjectID, Skill} because Skill is not determined by the other columns.
*/

-- ### TASK 1: Identify the non-atomic attribute and convert to atomic values (1NF)
-- Skills holds 'Python, SQL' / 'SQL, Tableau'. The 1NF table EP_1NF repeats the project row once per skill (7 rows instead of 4).
SELECT EmpID, Skills FROM Employee_Project_UNF WHERE Skills LIKE '%,%';
SELECT * FROM EP_1NF ORDER BY EmpID, ProjectID, Skill;

-- ### TASK 2: Anomalies in the original table
-- INSERT: a new project PR9 or a new department D3 cannot be stored without an employee (EmpID part of the key) -> error.
-- UPDATE: department of Ravi stored in 2 rows (4 in 1NF); changing 1 row leaves D1 with two names.
-- DELETE: deleting Sneha's only row deletes the fact that department D2 is called IT.
INSERT INTO Employee_Project_UNF (DeptID, DeptName) VALUES ('D3', 'Finance');
START TRANSACTION;
UPDATE Employee_Project_UNF SET DeptName = 'Research' WHERE EmpID = 'E1' AND ProjectID = 'PR1';
SELECT DeptID, DeptName, COUNT(*) AS rows_ FROM Employee_Project_UNF WHERE DeptID = 'D1' GROUP BY DeptID, DeptName;
ROLLBACK;
START TRANSACTION;
DELETE FROM Employee_Project_UNF WHERE EmpID = 'E2';
SELECT DISTINCT DeptID, DeptName FROM Employee_Project_UNF;
ROLLBACK;

-- ### TASK 3: Find the candidate key
-- EmpID+ = {EmpID, EmpName, DeptID, DeptName}; {EmpID,ProjectID}+ adds ProjectName and Hours but not Skill;
-- Skill is on the right of no FD, so every key must contain it => the only candidate key is {EmpID, ProjectID, Skill} (fd_analysis.py).
SELECT COUNT(*) AS rows_, COUNT(DISTINCT EmpID, ProjectID) AS pairs, COUNT(DISTINCT EmpID, ProjectID, Skill) AS triples FROM EP_1NF;

-- ### TASK 4: Partial and transitive dependencies
-- Partial: EmpID -> EmpName, DeptID (EmpID is only part of the key); ProjectID -> ProjectName; {EmpID,ProjectID} -> Hours is partial w.r.t. the 3-column key (Skill missing).
-- Transitive: EmpID -> DeptID -> DeptName.
SELECT 'EmpID -> EmpName, DeptID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'ProjectID -> ProjectName', 'Partial' UNION ALL
SELECT '{EmpID, ProjectID} -> Hours', 'Partial (needs only 2 of the 3 key columns)' UNION ALL
SELECT 'DeptID -> DeptName', 'Transitive (EmpID -> DeptID -> DeptName)';

-- ### TASK 5: Normalise to 2NF and 3NF
-- 2NF: Employee(EmpID, EmpName, DeptID, DeptName), Project(ProjectID, ProjectName), Works_On(EmpID, ProjectID, Hours), Emp_Skill(EmpID, Skill).
-- 3NF: split Department(DeptID, DeptName) out of Employee. (Tables are created in Task 7.)
CREATE TABLE Emp_2NF AS SELECT DISTINCT EmpID, EmpName, DeptID, DeptName FROM EP_1NF;
CREATE TABLE Project_2NF AS SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF;
CREATE TABLE Works_On_2NF AS SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF;
SELECT * FROM Emp_2NF; SELECT * FROM Project_2NF; SELECT * FROM Works_On_2NF;
DROP TABLE Emp_2NF, Project_2NF, Works_On_2NF;

-- ### TASK 6: BCNF check and the multivalued dependency EmpID ->> Skills (4NF idea)
-- All FD determinants are keys of the final tables => BCNF. But EP_1NF still stores Python/SQL for Ravi twice (once per project): that redundancy is not caused
-- by an FD but by the MVD EmpID ->> Skill (skills are independent of projects). Fix: Emp_Skill(EmpID, Skill) separate from Works_On. The query shows the repetition.
SELECT EmpID, Skill, COUNT(*) AS times_stored FROM EP_1NF GROUP BY EmpID, Skill HAVING COUNT(*) > 1;

-- ### TASK 7: Create the tables in SQL with keys
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

-- ### TASK 8: Insert the data
INSERT INTO Department SELECT DISTINCT DeptID, DeptName FROM EP_1NF;
INSERT INTO Employee   SELECT DISTINCT EmpID, EmpName, DeptID FROM EP_1NF;
INSERT INTO Project    SELECT DISTINCT ProjectID, ProjectName FROM EP_1NF;
INSERT INTO Works_On   SELECT DISTINCT EmpID, ProjectID, Hours FROM EP_1NF;
INSERT INTO Emp_Skill  SELECT DISTINCT EmpID, Skill FROM EP_1NF;
SELECT (SELECT COUNT(*) FROM Department) AS depts, (SELECT COUNT(*) FROM Employee) AS emps, (SELECT COUNT(*) FROM Project) AS projects,
       (SELECT COUNT(*) FROM Works_On) AS works_on, (SELECT COUNT(*) FROM Emp_Skill) AS skills;

-- ### TASK 9: Employees with total project hours
-- Ravi 20+15 = 35, Sneha 30, Amol 25.
SELECT e.EmpID, e.EmpName, SUM(w.Hours) AS total_hours FROM Employee e JOIN Works_On w USING (EmpID) GROUP BY e.EmpID, e.EmpName;

-- ### TASK 10: Each project with the employees working on it
-- GROUP_CONCAT collapses the employee names of one project into one cell (Oracle: LISTAGG).
SELECT p.ProjectID, p.ProjectName, GROUP_CONCAT(e.EmpName ORDER BY e.EmpName) AS employees FROM Project p JOIN Works_On w USING (ProjectID) JOIN Employee e USING (EmpID) GROUP BY p.ProjectID, p.ProjectName;

-- ### TASK 11: Employees who know both Python and SQL
-- Group the skill rows per employee and require both skills to be present. Only Ravi.
SELECT e.EmpName FROM Employee e JOIN Emp_Skill s USING (EmpID) WHERE s.Skill IN ('Python', 'SQL') GROUP BY e.EmpID, e.EmpName HAVING COUNT(DISTINCT s.Skill) = 2;

-- ### TASK 12: Department with the highest total project hours
-- R&D: Ravi 35 + Amol 25 = 60; IT: Sneha 30.
SELECT d.DeptName, SUM(w.Hours) AS total_hours FROM Department d JOIN Employee e USING (DeptID) JOIN Works_On w USING (EmpID) GROUP BY d.DeptID, d.DeptName ORDER BY total_hours DESC LIMIT 1;

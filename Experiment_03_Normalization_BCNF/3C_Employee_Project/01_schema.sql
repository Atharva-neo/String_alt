-- Experiment 3C - Employee_Project : unnormalised table (multi-valued Skills) and its 1NF form
-- @DB norm_3c
/* @ER
flowchart LR
    UNF["Employee_Project_UNF<br/>Skills = 'Python, SQL'"] -->|"Task 1: atomic Skill"| N1["1NF: EP_1NF<br/>PK (EmpID, ProjectID, Skill)"]
    N1 -->|"Tasks 4-5: partial + transitive FDs"| N3["3NF: Department | Employee | Project | Works_On"]
    N1 -->|"Task 6: MVD EmpID ->> Skill (4NF idea)"| N4["Emp_Skill(EmpID, Skill)"]
*/
DROP DATABASE IF EXISTS norm_3c;
CREATE DATABASE norm_3c;
USE norm_3c;

CREATE TABLE Employee_Project_UNF (
    EmpID       VARCHAR(5)  NOT NULL,
    EmpName     VARCHAR(40) NOT NULL,
    DeptID      VARCHAR(5)  NOT NULL,
    DeptName    VARCHAR(30) NOT NULL,
    ProjectID   VARCHAR(5)  NOT NULL,
    ProjectName VARCHAR(40) NOT NULL,
    Hours       INT         NOT NULL,
    Skills      VARCHAR(60) NOT NULL,       -- 'Python, SQL' : not atomic
    PRIMARY KEY (EmpID, ProjectID)
) ENGINE=InnoDB;

-- 1NF: Skills made atomic; the key grows to (EmpID, ProjectID, Skill)
CREATE TABLE EP_1NF (
    EmpID       VARCHAR(5)  NOT NULL,
    EmpName     VARCHAR(40) NOT NULL,
    DeptID      VARCHAR(5)  NOT NULL,
    DeptName    VARCHAR(30) NOT NULL,
    ProjectID   VARCHAR(5)  NOT NULL,
    ProjectName VARCHAR(40) NOT NULL,
    Hours       INT         NOT NULL,
    Skill       VARCHAR(30) NOT NULL,
    PRIMARY KEY (EmpID, ProjectID, Skill)
) ENGINE=InnoDB;

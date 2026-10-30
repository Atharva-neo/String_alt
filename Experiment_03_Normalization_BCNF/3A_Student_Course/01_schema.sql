-- Experiment 3A - Student_Course : the UNNORMALISED table and its 1NF form (normalised tables are created in Task 9)
-- @DB norm_3a
/* @ER
flowchart LR
    UNF["UNF: Student_Course_UNF<br/>multi-valued cells"] -->|"Task 2: atomic values"| NF1["1NF: Student_Course_1NF<br/>PK (RollNo, CourseID)"]
    NF1 -->|"Task 6: remove partial FDs"| NF2["2NF: Student | Course_Faculty | Enrolment"]
    NF2 -->|"Task 7: remove transitive FD"| NF3["3NF = BCNF: Student | Faculty | Course | Enrolment"]
*/
DROP DATABASE IF EXISTS norm_3a;
CREATE DATABASE norm_3a;
USE norm_3a;

-- As printed in the PDF: several values are packed into one cell (violates 1NF)
CREATE TABLE Student_Course_UNF (
    RollNo       INT NOT NULL PRIMARY KEY,
    Name         VARCHAR(40),
    CourseID     VARCHAR(30),      -- 'C1, C2'
    CourseName   VARCHAR(60),      -- 'DBMS, ML'
    Faculty      VARCHAR(60),
    FacultyPhone VARCHAR(60),
    Grade        VARCHAR(20)
) ENGINE=InnoDB;

-- 1NF: one value per cell, key = (RollNo, CourseID)
CREATE TABLE Student_Course_1NF (
    RollNo       INT         NOT NULL,
    Name         VARCHAR(40) NOT NULL,
    CourseID     VARCHAR(5)  NOT NULL,
    CourseName   VARCHAR(40) NOT NULL,
    Faculty      VARCHAR(40) NOT NULL,
    FacultyPhone VARCHAR(15) NOT NULL,
    Grade        VARCHAR(3)  NOT NULL,
    PRIMARY KEY (RollNo, CourseID)
) ENGINE=InnoDB;

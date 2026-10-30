-- Experiment 2C - University results : schema
-- @DB univ_2c
/* @ER
erDiagram
    STUDENT ||--o{ MARKS : "scores (1 : N)"
    SUBJECT ||--o{ MARKS : "graded in (1 : N)"
    STUDENT {
        int roll_no PK
        varchar name
        varchar dept
    }
    SUBJECT {
        varchar sub_id PK
        varchar sub_name
        int max_marks
    }
    MARKS {
        int roll_no PK, FK
        varchar sub_id PK, FK
        int marks
    }
*/
DROP DATABASE IF EXISTS univ_2c;
CREATE DATABASE univ_2c;
USE univ_2c;

CREATE TABLE Student (
    roll_no INT NOT NULL PRIMARY KEY,
    name    VARCHAR(40) NOT NULL,
    dept    VARCHAR(10) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Subject (
    sub_id    VARCHAR(5) NOT NULL PRIMARY KEY,
    sub_name  VARCHAR(30) NOT NULL,
    max_marks INT NOT NULL DEFAULT 100
) ENGINE=InnoDB;
CREATE TABLE Marks (
    roll_no INT NOT NULL,
    sub_id  VARCHAR(5) NOT NULL,
    marks   INT NOT NULL,
    PRIMARY KEY (roll_no, sub_id),
    CONSTRAINT fk_m_student FOREIGN KEY (roll_no) REFERENCES Student(roll_no),
    CONSTRAINT fk_m_subject FOREIGN KEY (sub_id)  REFERENCES Subject(sub_id),
    CONSTRAINT chk_marks CHECK (marks >= 0)
) ENGINE=InnoDB;

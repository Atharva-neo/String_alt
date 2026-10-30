-- Experiment 1C - College | Task 1 (ER with the M:N Enrolment) and Task 2 (tables)
-- @DB college_1c
/* @ER
erDiagram
    DEPARTMENT ||--o{ STUDENT : "has (1 : N)"
    DEPARTMENT ||--o{ COURSE  : "offers (1 : N)"
    STUDENT    ||--o{ ENROLMENT : "enrols (1 : N)"
    COURSE     ||--o{ ENROLMENT : "taken by (1 : N)"
    DEPARTMENT {
        varchar dept_id PK
        varchar dept_name
        varchar hod
    }
    STUDENT {
        int roll_no PK
        varchar name
        varchar dept_id FK
        int year
        decimal cgpa "CHECK 0..10"
    }
    COURSE {
        varchar course_id PK
        varchar course_name
        int credits "CHECK > 0"
        varchar dept_id FK
    }
    ENROLMENT {
        int roll_no PK, FK
        varchar course_id PK, FK
    }
*/

DROP DATABASE IF EXISTS college_1c;
CREATE DATABASE college_1c;
USE college_1c;

CREATE TABLE Department (
    dept_id   VARCHAR(5)  NOT NULL PRIMARY KEY,
    dept_name VARCHAR(30) NOT NULL UNIQUE,
    hod       VARCHAR(40)
) ENGINE=InnoDB;

CREATE TABLE Student (
    roll_no INT          NOT NULL PRIMARY KEY,
    name    VARCHAR(50)  NOT NULL,
    dept_id VARCHAR(5)   NOT NULL,
    year    INT          NOT NULL DEFAULT 1,
    cgpa    DECIMAL(3,1) NOT NULL,
    CONSTRAINT fk_student_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    CONSTRAINT chk_student_cgpa CHECK (cgpa BETWEEN 0 AND 10)
) ENGINE=InnoDB;

CREATE TABLE Course (
    course_id   VARCHAR(8)  NOT NULL PRIMARY KEY,
    course_name VARCHAR(40) NOT NULL,
    credits     INT         NOT NULL,
    dept_id     VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_course_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    CONSTRAINT chk_course_credits CHECK (credits > 0)
) ENGINE=InnoDB;

-- M:N between Student and Course -> junction table with a composite primary key
CREATE TABLE Enrolment (
    roll_no   INT         NOT NULL,
    course_id VARCHAR(8)  NOT NULL,
    PRIMARY KEY (roll_no, course_id),
    CONSTRAINT fk_enr_student FOREIGN KEY (roll_no)   REFERENCES Student(roll_no),
    CONSTRAINT fk_enr_course  FOREIGN KEY (course_id) REFERENCES Course(course_id)
) ENGINE=InnoDB;

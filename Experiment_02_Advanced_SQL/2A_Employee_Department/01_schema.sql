-- Experiment 2A - Employee-Department : schema
-- @DB emp_2a
/* @ER
erDiagram
    DEPARTMENT ||--o{ EMPLOYEE : "employs (1 : N, optional)"
    EMPLOYEE   ||--o{ EMPLOYEE : "manages (self, 1 : N)"
    DEPARTMENT {
        int dept_no PK
        varchar dept_name
        varchar location
    }
    EMPLOYEE {
        int emp_id PK
        varchar ename
        varchar job
        int manager_id FK "self reference, NULL for the president"
        int salary
        int dept_no FK "NULL allowed (Nikhil)"
        date hire_date
    }
*/
DROP DATABASE IF EXISTS emp_2a;
CREATE DATABASE emp_2a;
USE emp_2a;

CREATE TABLE Department (
    dept_no   INT         NOT NULL PRIMARY KEY,
    dept_name VARCHAR(30) NOT NULL,
    location  VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE Employee (
    emp_id     INT         NOT NULL PRIMARY KEY,
    ename      VARCHAR(40) NOT NULL,
    job        VARCHAR(30),
    manager_id INT         NULL,
    salary     INT         NOT NULL,
    dept_no    INT         NULL,
    hire_date  DATE,
    CONSTRAINT fk_emp_mgr  FOREIGN KEY (manager_id) REFERENCES Employee(emp_id),
    CONSTRAINT fk_emp_dept FOREIGN KEY (dept_no)    REFERENCES Department(dept_no)
) ENGINE=InnoDB;

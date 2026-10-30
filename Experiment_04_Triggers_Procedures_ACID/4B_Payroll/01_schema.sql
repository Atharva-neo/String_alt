-- Experiment 4B - Payroll : Tasks 1 and 2 (tables)
-- @DB payroll_4b
/* @ER
erDiagram
    EMPLOYEE ||--o{ SALARY_AUDIT : "changes recorded by trigger"
    EMPLOYEE {
        int emp_id PK
        varchar name
        varchar dept
        decimal salary "NOT NULL, BEFORE INSERT trigger defaults NULL to 20000"
    }
    SALARY_AUDIT {
        int audit_id PK
        int emp_id
        decimal old_salary
        decimal new_salary
        datetime changed_on
    }
*/
DROP DATABASE IF EXISTS payroll_4b;
CREATE DATABASE payroll_4b;
USE payroll_4b;

CREATE TABLE Employee (
    emp_id INT           NOT NULL PRIMARY KEY,
    name   VARCHAR(40)   NOT NULL,
    dept   VARCHAR(20)   NOT NULL,
    salary DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Salary_Audit (
    audit_id   INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    emp_id     INT           NOT NULL,
    old_salary DECIMAL(10,2) NOT NULL,
    new_salary DECIMAL(10,2) NOT NULL,
    changed_on DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

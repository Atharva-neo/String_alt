-- Experiment 1B - Bank | Task 1 (ER) and Task 2 (tables with CHECK / DEFAULT)
-- @DB bank_1b
/* @ER
erDiagram
    BRANCH   ||--o{ ACCOUNT : "holds (1 : N)"
    CUSTOMER ||--o{ ACCOUNT : "owns (1 : N)"
    BRANCH {
        varchar branch_id PK
        varchar branch_name
        varchar city
    }
    CUSTOMER {
        varchar cust_id PK
        varchar name
        varchar city
        date dob
    }
    ACCOUNT {
        int acc_no PK
        varchar cust_id FK
        varchar branch_id FK
        varchar acc_type "CHECK IN (Savings, Current), DEFAULT Savings"
        decimal balance "CHECK >= 1000"
    }
*/

DROP DATABASE IF EXISTS bank_1b;
CREATE DATABASE bank_1b;
USE bank_1b;

CREATE TABLE Branch (
    branch_id   VARCHAR(5)  NOT NULL PRIMARY KEY,
    branch_name VARCHAR(40) NOT NULL,
    city        VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Customer (
    cust_id VARCHAR(5)  NOT NULL PRIMARY KEY,
    name    VARCHAR(50) NOT NULL,
    city    VARCHAR(30),
    dob     DATE
) ENGINE=InnoDB;

CREATE TABLE Account (
    acc_no    INT           NOT NULL PRIMARY KEY,
    cust_id   VARCHAR(5)    NOT NULL,
    branch_id VARCHAR(5)    NOT NULL,
    acc_type  VARCHAR(10)   NOT NULL DEFAULT 'Savings',
    balance   DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_acc_cust   FOREIGN KEY (cust_id)   REFERENCES Customer(cust_id),
    CONSTRAINT fk_acc_branch FOREIGN KEY (branch_id) REFERENCES Branch(branch_id),
    CONSTRAINT chk_acc_balance CHECK (balance >= 1000),
    CONSTRAINT chk_acc_type    CHECK (acc_type IN ('Savings','Current'))
) ENGINE=InnoDB;

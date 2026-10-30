-- Experiment 4A - Bank transfer : Task 1 (tables)
-- @DB bank_4a
/* @ER
erDiagram
    ACCOUNT ||--o{ TXN_LOG : "is logged in (trigger-filled)"
    ACCOUNT {
        int acc_no PK
        varchar holder
        decimal balance
    }
    TXN_LOG {
        int log_id PK "AUTO_INCREMENT"
        int acc_no FK
        varchar txn_type "Debit / Credit"
        decimal amount
        datetime txn_time
    }
*/
DROP DATABASE IF EXISTS bank_4a;
CREATE DATABASE bank_4a;
USE bank_4a;

CREATE TABLE Account (
    acc_no  INT           NOT NULL PRIMARY KEY,
    holder  VARCHAR(40)   NOT NULL,
    balance DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;                       -- InnoDB is required for transactions, row locks and FKs

CREATE TABLE Txn_Log (
    log_id   INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    acc_no   INT           NOT NULL,
    txn_type VARCHAR(10)   NOT NULL,
    amount   DECIMAL(12,2) NOT NULL,
    txn_time DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_acc FOREIGN KEY (acc_no) REFERENCES Account(acc_no)
) ENGINE=InnoDB;

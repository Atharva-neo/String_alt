-- Experiment 5A - Lost update on stock : Task 1 (InnoDB table)
-- @DB stock_5a
-- @NOEXEC   (the numbered tasks need two live sessions; 05_expected_output.md is produced by run_demo.py)
/* @ER
sequenceDiagram
    participant S1 as Session 1
    participant DB as Stock(item 1)
    participant S2 as Session 2
    S1->>DB: read qty = 100
    S2->>DB: read qty = 100
    S1->>DB: write qty = 100-30 = 70, commit
    S2->>DB: write qty = 100-50 = 50, commit
    Note over DB: final 50 - S1's update is lost (correct: 20)
*/
DROP DATABASE IF EXISTS stock_5a;
CREATE DATABASE stock_5a;
USE stock_5a;

CREATE TABLE Stock (
    item_id   INT         NOT NULL PRIMARY KEY,
    item_name VARCHAR(30) NOT NULL,
    qty       INT         NOT NULL
) ENGINE=InnoDB;                        -- InnoDB: row-level locks + transactions (MyISAM would ignore both)

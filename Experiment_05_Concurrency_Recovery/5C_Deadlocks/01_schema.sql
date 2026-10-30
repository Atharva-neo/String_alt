-- Experiment 5C - Deadlock : Task 1
-- @DB deadlock_5c
-- @NOEXEC   (needs live sessions; 05_expected_output.md is produced by run_demo.py)
/* @ER
flowchart LR
    T1["T1: holds row 1"] -- "waits for row 2" --> T2["T2: holds row 2"]
    T2 -- "waits for row 1" --> T1
*/
DROP DATABASE IF EXISTS deadlock_5c;
CREATE DATABASE deadlock_5c;
USE deadlock_5c;

CREATE TABLE Account (
    acc_no  INT           NOT NULL PRIMARY KEY,
    balance DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

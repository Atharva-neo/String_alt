-- Experiment 5B - Isolation levels on seat booking : Task 1
-- @DB seats_5b
-- @NOEXEC   (two live sessions are needed; 05_expected_output.md is produced by run_demo.py)
/* @ER
flowchart LR
    subgraph Anomalies
      D["Dirty read<br/>(reads uncommitted data)"]
      N["Non-repeatable read<br/>(same row, two values)"]
      P["Phantom<br/>(new row appears)"]
    end
    RU["READ UNCOMMITTED"] --> D
    RC["READ COMMITTED"] --> N
    RR["REPEATABLE READ"] --> P
    SER["SERIALIZABLE"] --> OK["no anomaly"]
*/
DROP DATABASE IF EXISTS seats_5b;
CREATE DATABASE seats_5b;
USE seats_5b;

CREATE TABLE Seats (
    seat_no VARCHAR(4)  NOT NULL PRIMARY KEY,
    status  VARCHAR(10) NOT NULL,
    CONSTRAINT chk_seat_status CHECK (status IN ('Free', 'Booked'))
) ENGINE=InnoDB;

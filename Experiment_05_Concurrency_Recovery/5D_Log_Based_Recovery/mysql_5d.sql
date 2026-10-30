-- Experiment 5D Task 12 - the table main.py creates (shown here so you can also run it by hand)
CREATE DATABASE IF NOT EXISTS recovery_5d;
USE recovery_5d;
DROP TABLE IF EXISTS db_values;
CREATE TABLE db_values (item VARCHAR(5) NOT NULL PRIMARY KEY, value INT NOT NULL) ENGINE=InnoDB;

-- state after the crash (immediate update: every write reached the database)
INSERT INTO db_values VALUES ('A', 900), ('B', 2050), ('C', 600), ('D', 800);

-- the recovery program applies the UNDO / REDO results in ONE transaction:
START TRANSACTION;
UPDATE db_values SET value = 950 WHERE item = 'A';   -- UNDO <T2, A, 950, 900>
UPDATE db_values SET value = 700 WHERE item = 'C';   -- UNDO <T2, C, 700, 600>
UPDATE db_values SET value = 800 WHERE item = 'D';   -- REDO <T3, D, 500, 800>
COMMIT;
SELECT * FROM db_values ORDER BY item;               -- A=950 B=2050 C=700 D=800

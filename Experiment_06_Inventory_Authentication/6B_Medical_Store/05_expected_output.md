# Expected output - Experiment_06_Inventory_Authentication / 6B_Medical_Store

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Medicine_Batch with FK to Supplier and CHECK (expiry_date > mfg_date); insert the data

```sql
CREATE TABLE Medicine_Batch (
    batch_no    VARCHAR(6)  NOT NULL PRIMARY KEY,
    med_name    VARCHAR(40) NOT NULL,
    qty         INT         NOT NULL,
    mfg_date    DATE        NOT NULL,
    expiry_date DATE        NOT NULL,
    supplier_id VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT chk_batch_dates CHECK (expiry_date > mfg_date),
    CONSTRAINT chk_batch_qty CHECK (qty >= 0)
) ENGINE=InnoDB;
INSERT INTO Medicine_Batch VALUES
('BT01', 'Paracetamol 500', 200, '2025-01-10', '2026-11-15', 'S1'),
('BT02', 'Amoxicillin 250',  80, '2025-06-01', '2027-05-30', 'S2'),
('BT03', 'Cough Syrup',      40, '2024-12-01', '2026-11-05', 'S3'),
('BT04', 'Vitamin D3',      120, '2025-09-01', '2027-08-31', 'S1');
SELECT * FROM Medicine_Batch;
INSERT INTO Medicine_Batch VALUES ('BT99', 'Bad Dates', 10, '2026-05-01', '2026-01-01', 'S1');
```

**Output**

```text
CREATE TABLE Medicine_Batch (
    batch_no    VARCHAR(6)  NOT NULL PRIMARY KEY,
    med_name    VARCHAR(40) NOT NULL,
    qty         INT         NOT NULL,
    mfg_date    DATE        NOT NULL,
    expiry_date DATE        NOT NULL,
    supplier_id VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT chk_batch_dates CHECK (expiry_date > mfg_date),
    CONSTRAINT chk_batch_qty CHECK (qty >= 0)
) ENGINE=InnoDB

Query OK, 0 rows affected

INSERT INTO Medicine_Batch VALUES
('BT01', 'Paracetamol 500', 200, '2025-01-10', '2026-11-15', 'S1'),
('BT02', 'Amoxicillin 250',  80, '2025-06-01', '2027-05-30', 'S2'),
('BT03', 'Cough Syrup',      40, '2024-12-01', '2026-11-05', 'S3'),
('BT04', 'Vitamin D3',      120, '2025-09-01', '2027-08-31', 'S1')

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT * FROM Medicine_Batch

+----------+-----------------+-----+------------+-------------+-------------+
| batch_no | med_name        | qty | mfg_date   | expiry_date | supplier_id |
+----------+-----------------+-----+------------+-------------+-------------+
| BT01     | Paracetamol 500 | 200 | 2025-01-10 | 2026-11-15  | S1          |
| BT02     | Amoxicillin 250 |  80 | 2025-06-01 | 2027-05-30  | S2          |
| BT03     | Cough Syrup     |  40 | 2024-12-01 | 2026-11-05  | S3          |
| BT04     | Vitamin D3      | 120 | 2025-09-01 | 2027-08-31  | S1          |
+----------+-----------------+-----+------------+-------------+-------------+
4 rows in set

INSERT INTO Medicine_Batch VALUES ('BT99', 'Bad Dates', 10, '2026-05-01', '2026-01-01', 'S1')

ERROR 3819 (HY000) at line 18: Check constraint 'chk_batch_dates' is violated.
```

### Task 2 - Medicines expiring in the next 30 days

```sql
SELECT batch_no, med_name, expiry_date, DATEDIFF(expiry_date, CURRENT_DATE) AS days_left
FROM Medicine_Batch WHERE expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) ORDER BY expiry_date;
```

**Output**

```text
SELECT batch_no, med_name, expiry_date, DATEDIFF(expiry_date, CURRENT_DATE) AS days_left
FROM Medicine_Batch WHERE expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) ORDER BY expiry_date

+----------+-----------------+-------------+-----------+
| batch_no | med_name        | expiry_date | days_left |
+----------+-----------------+-------------+-----------+
| BT03     | Cough Syrup     | 2026-11-05  |         6 |
| BT01     | Paracetamol 500 | 2026-11-15  |        16 |
+----------+-----------------+-------------+-----------+
2 rows in set
```

**Why this output is correct:** Window = today .. today + 30 days. With the run date shown in the output header this selects BT01 (2026-11-15) and BT03 (2026-11-05).

### Task 3 - Medicines already expired as of today

```sql
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < CURRENT_DATE;
SET @as_of = '2026-12-01';
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < @as_of ORDER BY expiry_date;
```

**Output**

```text
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < CURRENT_DATE

Empty set

SET @as_of = '2026-12-01'

Query OK, 0 rows affected

SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < @as_of ORDER BY expiry_date

+----------+-----------------+-------------+
| batch_no | med_name        | expiry_date |
+----------+-----------------+-------------+
| BT03     | Cough Syrup     | 2026-11-05  |
| BT01     | Paracetamol 500 | 2026-11-15  |
+----------+-----------------+-------------+
2 rows in set
```

**Why this output is correct:** On the run date nothing is expired yet (earliest expiry 2026-11-05). To prove the query the same statement is evaluated "as of" 2026-12-01 using a variable.

### Task 4 - Supplier-wise total quantity supplied

```sql
SELECT s.supplier_id, s.sname, SUM(b.qty) AS total_qty FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id GROUP BY s.supplier_id, s.sname;
```

**Output**

```text
SELECT s.supplier_id, s.sname, SUM(b.qty) AS total_qty FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id GROUP BY s.supplier_id, s.sname

+-------------+-----------------+-----------+
| supplier_id | sname           | total_qty |
+-------------+-----------------+-----------+
| S1          | Om Distributors |       320 |
| S2          | Shree Agencies  |        80 |
| S3          | Global Supplies |        40 |
+-------------+-----------------+-----------+
3 rows in set
```

### Task 5 - Batch with the maximum quantity for each supplier

```sql
SELECT b.supplier_id, b.batch_no, b.med_name, b.qty FROM Medicine_Batch b
WHERE b.qty = (SELECT MAX(x.qty) FROM Medicine_Batch x WHERE x.supplier_id = b.supplier_id) ORDER BY b.supplier_id;
```

**Output**

```text
SELECT b.supplier_id, b.batch_no, b.med_name, b.qty FROM Medicine_Batch b
WHERE b.qty = (SELECT MAX(x.qty) FROM Medicine_Batch x WHERE x.supplier_id = b.supplier_id) ORDER BY b.supplier_id

+-------------+----------+-----------------+-----+
| supplier_id | batch_no | med_name        | qty |
+-------------+----------+-----------------+-----+
| S1          | BT01     | Paracetamol 500 | 200 |
| S2          | BT02     | Amoxicillin 250 |  80 |
| S3          | BT03     | Cough Syrup     |  40 |
+-------------+----------+-----------------+-----+
3 rows in set
```

**Why this output is correct:** Correlated subquery picks the largest qty of the same supplier: S1 -> BT01 (200 > 120), S2 -> BT02, S3 -> BT03.

### Task 6 - Trigger that blocks insertion of an already expired batch

```sql
DELIMITER $$
CREATE TRIGGER trg_batch_not_expired BEFORE INSERT ON Medicine_Batch FOR EACH ROW
BEGIN
    IF NEW.expiry_date < CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot add an already expired batch';
    END IF;
END$$
DELIMITER ;
INSERT INTO Medicine_Batch VALUES ('BT05', 'Old Stock', 25, '2024-01-01', '2025-01-01', 'S2');
INSERT INTO Medicine_Batch VALUES ('BT06', 'Fresh Stock', 25, '2026-09-01', '2028-09-01', 'S2');
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch ORDER BY batch_no;
DELETE FROM Medicine_Batch WHERE batch_no = 'BT06';
```

**Output**

```text
CREATE TRIGGER trg_batch_not_expired BEFORE INSERT ON Medicine_Batch FOR EACH ROW
BEGIN
    IF NEW.expiry_date < CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot add an already expired batch';
    END IF;
END

Query OK, 0 rows affected

INSERT INTO Medicine_Batch VALUES ('BT05', 'Old Stock', 25, '2024-01-01', '2025-01-01', 'S2')

ERROR 1644 (45000) at line 9: Cannot add an already expired batch
INSERT INTO Medicine_Batch VALUES ('BT06', 'Fresh Stock', 25, '2026-09-01', '2028-09-01', 'S2')

Query OK, 1 row affected

SELECT batch_no, med_name, expiry_date FROM Medicine_Batch ORDER BY batch_no

+----------+-----------------+-------------+
| batch_no | med_name        | expiry_date |
+----------+-----------------+-------------+
| BT01     | Paracetamol 500 | 2026-11-15  |
| BT02     | Amoxicillin 250 | 2027-05-30  |
| BT03     | Cough Syrup     | 2026-11-05  |
| BT04     | Vitamin D3      | 2027-08-31  |
| BT06     | Fresh Stock     | 2028-09-01  |
+----------+-----------------+-------------+
5 rows in set

DELETE FROM Medicine_Batch WHERE batch_no = 'BT06'

Query OK, 1 row affected
```

**Why this output is correct:** BEFORE INSERT compares expiry_date with CURRENT_DATE (a CHECK constraint may not use it).

### Task 7 - Procedure that deletes expired batches and returns the count deleted

```sql
DELIMITER $$
CREATE PROCEDURE delete_expired(OUT p_deleted INT)
BEGIN
    DELETE FROM Medicine_Batch WHERE expiry_date < CURRENT_DATE;
    SET p_deleted = ROW_COUNT();
END$$
DELIMITER ;
CALL delete_expired(@n);
SELECT @n AS deleted_now;
START TRANSACTION;
UPDATE Medicine_Batch SET expiry_date = '2026-10-01' WHERE batch_no = 'BT03';
CALL delete_expired(@n);
SELECT @n AS deleted_after_backdating_BT03;
SELECT batch_no FROM Medicine_Batch ORDER BY batch_no;
ROLLBACK;
SELECT batch_no FROM Medicine_Batch ORDER BY batch_no;
```

**Output**

```text
CREATE PROCEDURE delete_expired(OUT p_deleted INT)
BEGIN
    DELETE FROM Medicine_Batch WHERE expiry_date < CURRENT_DATE;
    SET p_deleted = ROW_COUNT();
END

Query OK, 0 rows affected

CALL delete_expired(@n)

Query OK, 0 rows affected

SELECT @n AS deleted_now

+-------------+
| deleted_now |
+-------------+
|           0 |
+-------------+
1 row in set

START TRANSACTION

Query OK, 0 rows affected

UPDATE Medicine_Batch SET expiry_date = '2026-10-01' WHERE batch_no = 'BT03'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

CALL delete_expired(@n)

Query OK, 1 row affected

SELECT @n AS deleted_after_backdating_BT03

+-------------------------------+
| deleted_after_backdating_BT03 |
+-------------------------------+
|                             1 |
+-------------------------------+
1 row in set

SELECT batch_no FROM Medicine_Batch ORDER BY batch_no

+----------+
| batch_no |
+----------+
| BT01     |
| BT02     |
| BT04     |
+----------+
3 rows in set

ROLLBACK

Query OK, 0 rows affected

SELECT batch_no FROM Medicine_Batch ORDER BY batch_no

+----------+
| batch_no |
+----------+
| BT01     |
| BT02     |
| BT03     |
| BT04     |
+----------+
4 rows in set
```

**Why this output is correct:** OUT parameter p_deleted = ROW_COUNT() of the DELETE. On the run date no batch is expired (returns 0); inside a transaction one batch is back-dated to show a deletion (then rolled back).

### Task 8 - sell_medicine(batch, qty): reduce qty, block sales from an expired batch

```sql
DELIMITER $$
CREATE PROCEDURE sell_medicine(IN p_batch VARCHAR(6), IN p_qty INT)
BEGIN
    DECLARE v_qty INT;
    DECLARE v_exp DATE;
    SELECT qty, expiry_date INTO v_qty, v_exp FROM Medicine_Batch WHERE batch_no = p_batch FOR UPDATE;
    IF v_qty IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch not found';
    END IF;
    IF v_exp < CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch expired - sale blocked';
    END IF;
    IF p_qty <= 0 OR p_qty > v_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid quantity or not enough stock in batch';
    END IF;
    UPDATE Medicine_Batch SET qty = qty - p_qty WHERE batch_no = p_batch;
END$$
DELIMITER ;
START TRANSACTION;
CALL sell_medicine('BT01', 20);
SELECT batch_no, qty FROM Medicine_Batch WHERE batch_no = 'BT01';
CALL sell_medicine('BT01', 5000);
UPDATE Medicine_Batch SET expiry_date = '2026-10-01' WHERE batch_no = 'BT03';
CALL sell_medicine('BT03', 1);
CALL sell_medicine('BT77', 1);
ROLLBACK;
SELECT batch_no, qty, expiry_date FROM Medicine_Batch ORDER BY batch_no;
```

**Output**

```text
CREATE PROCEDURE sell_medicine(IN p_batch VARCHAR(6), IN p_qty INT)
BEGIN
    DECLARE v_qty INT;
    DECLARE v_exp DATE;
    SELECT qty, expiry_date INTO v_qty, v_exp FROM Medicine_Batch WHERE batch_no = p_batch FOR UPDATE;
    IF v_qty IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch not found';
    END IF;
    IF v_exp < CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch expired - sale blocked';
    END IF;
    IF p_qty <= 0 OR p_qty > v_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid quantity or not enough stock in batch';
    END IF;
    UPDATE Medicine_Batch SET qty = qty - p_qty WHERE batch_no = p_batch;
END

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

CALL sell_medicine('BT01', 20)

Query OK, 1 row affected

SELECT batch_no, qty FROM Medicine_Batch WHERE batch_no = 'BT01'

+----------+-----+
| batch_no | qty |
+----------+-----+
| BT01     | 180 |
+----------+-----+
1 row in set

CALL sell_medicine('BT01', 5000)

ERROR 1644 (45000) at line 22: Invalid quantity or not enough stock in batch
UPDATE Medicine_Batch SET expiry_date = '2026-10-01' WHERE batch_no = 'BT03'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

CALL sell_medicine('BT03', 1)

ERROR 1644 (45000) at line 24: Batch expired - sale blocked
CALL sell_medicine('BT77', 1)

ERROR 1644 (45000) at line 25: Batch not found
ROLLBACK

Query OK, 0 rows affected

SELECT batch_no, qty, expiry_date FROM Medicine_Batch ORDER BY batch_no

+----------+-----+-------------+
| batch_no | qty | expiry_date |
+----------+-----+-------------+
| BT01     | 200 | 2026-11-15  |
| BT02     |  80 | 2027-05-30  |
| BT03     |  40 | 2026-11-05  |
| BT04     | 120 | 2027-08-31  |
+----------+-----+-------------+
4 rows in set
```

**Why this output is correct:** FOR UPDATE locks the batch row; checks existence, expiry and quantity; then reduces qty. Tested with a valid sale, too many units, and a back-dated (expired) batch.

### Task 9 - View low_stock (qty < 50)

```sql
CREATE VIEW low_stock AS SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE qty < 50;
SELECT * FROM low_stock;
```

**Output**

```text
CREATE VIEW low_stock AS SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE qty < 50

Query OK, 0 rows affected

SELECT * FROM low_stock

+----------+-------------+-----+-------------+
| batch_no | med_name    | qty | expiry_date |
+----------+-------------+-----+-------------+
| BT03     | Cough Syrup |  40 | 2026-11-05  |
+----------+-------------+-----+-------------+
1 row in set
```

### Task 10 - User pharmacist: SELECT on the view, UPDATE(qty) on Medicine_Batch

```sql
DROP USER IF EXISTS 'pharmacist'@'localhost';
CREATE USER 'pharmacist'@'localhost' IDENTIFIED BY 'Pharma@12345';
GRANT SELECT ON medical_6b.low_stock TO 'pharmacist'@'localhost';
GRANT UPDATE (qty) ON medical_6b.Medicine_Batch TO 'pharmacist'@'localhost';
SHOW GRANTS FOR 'pharmacist'@'localhost';
-- @as pharmacist Pharma@12345
-- | SELECT * FROM low_stock;
-- | SELECT * FROM Medicine_Batch;
-- | UPDATE Medicine_Batch SET qty = qty - 1 WHERE batch_no = 'BT03';
-- | UPDATE Medicine_Batch SET qty = 40;
-- | UPDATE Medicine_Batch SET med_name = 'X';
-- The constant UPDATE above really overwrote every quantity with 40 (that is the danger of column grants). The DBA restores the original quantities:
UPDATE Medicine_Batch SET qty = CASE batch_no WHEN 'BT01' THEN 200 WHEN 'BT02' THEN 80 WHEN 'BT03' THEN 40 WHEN 'BT04' THEN 120 END;
SELECT batch_no, qty FROM Medicine_Batch ORDER BY batch_no;
```

**Output**

```text
DROP USER IF EXISTS 'pharmacist'@'localhost'

Query OK, 0 rows affected, 1 warning

CREATE USER 'pharmacist'@'localhost' IDENTIFIED BY 'Pharma@12345'

Query OK, 0 rows affected

GRANT SELECT ON medical_6b.low_stock TO 'pharmacist'@'localhost'

Query OK, 0 rows affected

GRANT UPDATE (qty) ON medical_6b.Medicine_Batch TO 'pharmacist'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'pharmacist'@'localhost'

+-----------------------------------------------------------------------------------+
| Grants for pharmacist@localhost                                                   |
+-----------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `pharmacist`@`localhost`                                    |
| GRANT SELECT ON `medical_6b`.`low_stock` TO `pharmacist`@`localhost`              |
| GRANT UPDATE (`qty`) ON `medical_6b`.`medicine_batch` TO `pharmacist`@`localhost` |
+-----------------------------------------------------------------------------------+
3 rows in set

[session: user 'pharmacist']
SELECT * FROM low_stock

+----------+-------------+-----+-------------+
| batch_no | med_name    | qty | expiry_date |
+----------+-------------+-----+-------------+
| BT03     | Cough Syrup |  40 | 2026-11-05  |
+----------+-------------+-----+-------------+
1 row in set

SELECT * FROM Medicine_Batch

ERROR 1142 (42000) at line 2: SELECT command denied to user 'pharmacist'@'localhost' for table 'medicine_batch'
UPDATE Medicine_Batch SET qty = qty - 1 WHERE batch_no = 'BT03'

ERROR 1143 (42000) at line 3: SELECT command denied to user 'pharmacist'@'localhost' for column 'batch_no' in table 'medicine_batch'
UPDATE Medicine_Batch SET qty = 40

Query OK, 3 rows affected
Rows matched: 4  Changed: 3  Warnings: 0

UPDATE Medicine_Batch SET med_name = 'X'

ERROR 1143 (42000) at line 5: UPDATE command denied to user 'pharmacist'@'localhost' for column 'med_name' in table 'medicine_batch'

UPDATE Medicine_Batch SET qty = CASE batch_no WHEN 'BT01' THEN 200 WHEN 'BT02' THEN 80 WHEN 'BT03' THEN 40 WHEN 'BT04' THEN 120 END

Query OK, 3 rows affected
Rows matched: 4  Changed: 3  Warnings: 0

SELECT batch_no, qty FROM Medicine_Batch ORDER BY batch_no

+----------+-----+
| batch_no | qty |
+----------+-----+
| BT01     | 200 |
| BT02     |  80 |
| BT03     |  40 |
| BT04     | 120 |
+----------+-----+
4 rows in set
```

**Why this output is correct:** The pharmacist can read only the low-stock rows through the view and may change only qty. Because reading columns needs SELECT, an UPDATE that references qty or batch_no on the right-hand side / in WHERE is denied (ERROR 1143); a constant assignment without WHERE passes - a good argument for giving such users only procedures (sell_medicine) instead of column rights.

### Task 11 - User auditor with SELECT-only access on all tables; an INSERT is denied

```sql
DROP USER IF EXISTS 'auditor'@'localhost';
CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'Audit@12345';
GRANT SELECT ON medical_6b.* TO 'auditor'@'localhost';
SHOW GRANTS FOR 'auditor'@'localhost';
-- @as auditor Audit@12345
-- | SELECT batch_no, med_name, qty FROM Medicine_Batch LIMIT 2;
-- | INSERT INTO Medicine_Batch VALUES ('BT08', 'Hack', 1, '2026-01-01', '2028-01-01', 'S1');
-- | DELETE FROM Supplier;
```

**Output**

```text
DROP USER IF EXISTS 'auditor'@'localhost'

Query OK, 0 rows affected

CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'Audit@12345'

Query OK, 0 rows affected

GRANT SELECT ON medical_6b.* TO 'auditor'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'auditor'@'localhost'

+---------------------------------------------------------+
| Grants for auditor@localhost                            |
+---------------------------------------------------------+
| GRANT USAGE ON *.* TO `auditor`@`localhost`             |
| GRANT SELECT ON `medical_6b`.* TO `auditor`@`localhost` |
+---------------------------------------------------------+
2 rows in set

[session: user 'auditor']
SELECT batch_no, med_name, qty FROM Medicine_Batch LIMIT 2

+----------+-----------------+-----+
| batch_no | med_name        | qty |
+----------+-----------------+-----+
| BT01     | Paracetamol 500 | 200 |
| BT02     | Amoxicillin 250 |  80 |
+----------+-----------------+-----+
2 rows in set

INSERT INTO Medicine_Batch VALUES ('BT08', 'Hack', 1, '2026-01-01', '2028-01-01', 'S1')

ERROR 1142 (42000) at line 2: INSERT command denied to user 'auditor'@'localhost' for table 'medicine_batch'
DELETE FROM Supplier

ERROR 1142 (42000) at line 3: DELETE command denied to user 'auditor'@'localhost' for table 'supplier'
```

### Task 12 - REVOKE privileges from pharmacist and drop the user

```sql
REVOKE SELECT ON medical_6b.low_stock FROM 'pharmacist'@'localhost';
REVOKE UPDATE (qty) ON medical_6b.Medicine_Batch FROM 'pharmacist'@'localhost';
SHOW GRANTS FOR 'pharmacist'@'localhost';
DROP USER 'pharmacist'@'localhost';
SELECT user FROM mysql.user WHERE user IN ('pharmacist', 'auditor');
```

**Output**

```text
REVOKE SELECT ON medical_6b.low_stock FROM 'pharmacist'@'localhost'

Query OK, 0 rows affected

REVOKE UPDATE (qty) ON medical_6b.Medicine_Batch FROM 'pharmacist'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'pharmacist'@'localhost'

+------------------------------------------------+
| Grants for pharmacist@localhost                |
+------------------------------------------------+
| GRANT USAGE ON *.* TO `pharmacist`@`localhost` |
+------------------------------------------------+
1 row in set

DROP USER 'pharmacist'@'localhost'

Query OK, 0 rows affected

SELECT user FROM mysql.user WHERE user IN ('pharmacist', 'auditor')

+---------+
| user    |
+---------+
| auditor |
+---------+
1 row in set
```


## Advanced / examiner-style queries

### Adv 1 - FEFO picking list (first expired, first out): batches ordered by expiry

```sql
SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE expiry_date >= CURRENT_DATE ORDER BY expiry_date;
```

**Output**

```text
SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE expiry_date >= CURRENT_DATE ORDER BY expiry_date

+----------+-----------------+-----+-------------+
| batch_no | med_name        | qty | expiry_date |
+----------+-----------------+-----+-------------+
| BT03     | Cough Syrup     |  40 | 2026-11-05  |
| BT01     | Paracetamol 500 | 200 | 2026-11-15  |
| BT02     | Amoxicillin 250 |  80 | 2027-05-30  |
| BT04     | Vitamin D3      | 120 | 2027-08-31  |
+----------+-----------------+-----+-------------+
4 rows in set
```

### Adv 2 - Expiry status of every batch

```sql
SELECT batch_no, med_name, expiry_date,
       CASE WHEN expiry_date < CURRENT_DATE THEN 'EXPIRED'
            WHEN expiry_date <= DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) THEN 'EXPIRING SOON'
            ELSE 'OK' END AS status
FROM Medicine_Batch ORDER BY expiry_date;
```

**Output**

```text
SELECT batch_no, med_name, expiry_date,
       CASE WHEN expiry_date < CURRENT_DATE THEN 'EXPIRED'
            WHEN expiry_date <= DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) THEN 'EXPIRING SOON'
            ELSE 'OK' END AS status
FROM Medicine_Batch ORDER BY expiry_date

+----------+-----------------+-------------+---------------+
| batch_no | med_name        | expiry_date | status        |
+----------+-----------------+-------------+---------------+
| BT03     | Cough Syrup     | 2026-11-05  | EXPIRING SOON |
| BT01     | Paracetamol 500 | 2026-11-15  | EXPIRING SOON |
| BT02     | Amoxicillin 250 | 2027-05-30  | OK            |
| BT04     | Vitamin D3      | 2027-08-31  | OK            |
+----------+-----------------+-------------+---------------+
4 rows in set
```

### Adv 3 - Value at risk - quantity expiring within 30 days per supplier

```sql
SELECT s.sname, COALESCE(SUM(b.qty), 0) AS qty_expiring_soon
FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id AND b.expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY s.supplier_id, s.sname;
```

**Output**

```text
SELECT s.sname, COALESCE(SUM(b.qty), 0) AS qty_expiring_soon
FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id AND b.expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY s.supplier_id, s.sname

+-----------------+-------------------+
| sname           | qty_expiring_soon |
+-----------------+-------------------+
| Om Distributors |               200 |
| Shree Agencies  |                 0 |
| Global Supplies |                40 |
+-----------------+-------------------+
3 rows in set
```

### Adv 4 - Negative quantity

```sql
UPDATE Medicine_Batch SET qty = -1 WHERE batch_no = 'BT02';
```

**Output**

```text
UPDATE Medicine_Batch SET qty = -1 WHERE batch_no = 'BT02'

ERROR 3819 (HY000) at line 1: Check constraint 'chk_batch_qty' is violated.
```

**Why this output is correct:** Error 3819 (chk_batch_qty).

### Adv 5 - Batch of an unknown supplier

```sql
INSERT INTO Medicine_Batch VALUES ('BT09', 'Ghost', 5, '2026-01-01', '2028-01-01', 'S9');
```

**Output**

```text
INSERT INTO Medicine_Batch VALUES ('BT09', 'Ghost', 5, '2026-01-01', '2028-01-01', 'S9')

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`medical_6b`.`medicine_batch`, CONSTRAINT `fk_batch_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`supplier_id`))
```

**Why this output is correct:** Error 1452.

### Adv 6 - View is read-only for the auditor but the underlying data is the same

```sql
START TRANSACTION;
CALL sell_medicine('BT04', 100);
SELECT * FROM low_stock;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

CALL sell_medicine('BT04', 100)

Query OK, 1 row affected

SELECT * FROM low_stock

+----------+-------------+-----+-------------+
| batch_no | med_name    | qty | expiry_date |
+----------+-------------+-----+-------------+
| BT03     | Cough Syrup |  40 | 2026-11-05  |
| BT04     | Vitamin D3  |  20 | 2027-08-31  |
+----------+-------------+-----+-------------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** low_stock follows the data: after the sale of 5 units BT01 (200) is still not low stock, BT03 stays listed.

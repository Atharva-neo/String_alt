-- Experiment 6B - Medical store : 12 tasks (the clock of this run: CURRENT_DATE = the date printed in 05_expected_output.md)
/* @CONCEPTS
* **Batch/expiry management**: each delivery is a batch with manufacturing and expiry dates; sales must come only from non-expired batches.
* `CHECK (expiry_date > mfg_date)` guards data entry; a BEFORE INSERT trigger additionally refuses batches that are *already* expired (a CHECK cannot use CURRENT_DATE).
* Date windows: `expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL 30 DAY` (Oracle: `SYSDATE + 30`).
* Per-group maximum: correlated subquery `qty = (SELECT MAX(qty) ... same supplier)`.
* **Privileges**: `GRANT SELECT ON view` exposes only the view's rows/columns. `UPDATE (qty)` alone is not enough for `SET qty = qty - 1 WHERE batch_no = ...` because reading columns needs SELECT.
* Procedures with OUT parameters return counts: `CALL delete_expired(@n); SELECT @n;`.
*/

-- ### TASK 1: Create Medicine_Batch with FK to Supplier and CHECK (expiry_date > mfg_date); insert the data
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

-- ### TASK 2: Medicines expiring in the next 30 days
-- Window = today .. today + 30 days. With the run date shown in the output header this selects BT01 (2026-11-15) and BT03 (2026-11-05).
SELECT batch_no, med_name, expiry_date, DATEDIFF(expiry_date, CURRENT_DATE) AS days_left
FROM Medicine_Batch WHERE expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) ORDER BY expiry_date;

-- ### TASK 3: Medicines already expired as of today
-- On the run date nothing is expired yet (earliest expiry 2026-11-05). To prove the query the same statement is evaluated "as of" 2026-12-01 using a variable.
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < CURRENT_DATE;
SET @as_of = '2026-12-01';
SELECT batch_no, med_name, expiry_date FROM Medicine_Batch WHERE expiry_date < @as_of ORDER BY expiry_date;

-- ### TASK 4: Supplier-wise total quantity supplied
SELECT s.supplier_id, s.sname, SUM(b.qty) AS total_qty FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id GROUP BY s.supplier_id, s.sname;

-- ### TASK 5: Batch with the maximum quantity for each supplier
-- Correlated subquery picks the largest qty of the same supplier: S1 -> BT01 (200 > 120), S2 -> BT02, S3 -> BT03.
SELECT b.supplier_id, b.batch_no, b.med_name, b.qty FROM Medicine_Batch b
WHERE b.qty = (SELECT MAX(x.qty) FROM Medicine_Batch x WHERE x.supplier_id = b.supplier_id) ORDER BY b.supplier_id;

-- ### TASK 6: Trigger that blocks insertion of an already expired batch
-- BEFORE INSERT compares expiry_date with CURRENT_DATE (a CHECK constraint may not use it).
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

-- ### TASK 7: Procedure that deletes expired batches and returns the count deleted
-- OUT parameter p_deleted = ROW_COUNT() of the DELETE. On the run date no batch is expired (returns 0); inside a transaction one batch is back-dated to show a deletion (then rolled back).
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

-- ### TASK 8: sell_medicine(batch, qty): reduce qty, block sales from an expired batch
-- FOR UPDATE locks the batch row; checks existence, expiry and quantity; then reduces qty. Tested with a valid sale, too many units, and a back-dated (expired) batch.
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

-- ### TASK 9: View low_stock (qty < 50)
CREATE VIEW low_stock AS SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE qty < 50;
SELECT * FROM low_stock;

-- ### TASK 10: User pharmacist: SELECT on the view, UPDATE(qty) on Medicine_Batch
-- The pharmacist can read only the low-stock rows through the view and may change only qty. Because reading columns needs SELECT, an UPDATE that
-- references qty or batch_no on the right-hand side / in WHERE is denied (ERROR 1143); a constant assignment without WHERE passes - a good argument for
-- giving such users only procedures (sell_medicine) instead of column rights.
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

-- ### TASK 11: User auditor with SELECT-only access on all tables; an INSERT is denied
DROP USER IF EXISTS 'auditor'@'localhost';
CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'Audit@12345';
GRANT SELECT ON medical_6b.* TO 'auditor'@'localhost';
SHOW GRANTS FOR 'auditor'@'localhost';
-- @as auditor Audit@12345
-- | SELECT batch_no, med_name, qty FROM Medicine_Batch LIMIT 2;
-- | INSERT INTO Medicine_Batch VALUES ('BT08', 'Hack', 1, '2026-01-01', '2028-01-01', 'S1');
-- | DELETE FROM Supplier;

-- ### TASK 12: REVOKE privileges from pharmacist and drop the user
REVOKE SELECT ON medical_6b.low_stock FROM 'pharmacist'@'localhost';
REVOKE UPDATE (qty) ON medical_6b.Medicine_Batch FROM 'pharmacist'@'localhost';
SHOW GRANTS FOR 'pharmacist'@'localhost';
DROP USER 'pharmacist'@'localhost';
SELECT user FROM mysql.user WHERE user IN ('pharmacist', 'auditor');

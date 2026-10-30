-- Experiment 6B - additional examiner-style queries (run after 03)
USE medical_6b;

-- ### ADV 1: FEFO picking list (first expired, first out): batches ordered by expiry
SELECT batch_no, med_name, qty, expiry_date FROM Medicine_Batch WHERE expiry_date >= CURRENT_DATE ORDER BY expiry_date;

-- ### ADV 2: Expiry status of every batch
SELECT batch_no, med_name, expiry_date,
       CASE WHEN expiry_date < CURRENT_DATE THEN 'EXPIRED'
            WHEN expiry_date <= DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) THEN 'EXPIRING SOON'
            ELSE 'OK' END AS status
FROM Medicine_Batch ORDER BY expiry_date;

-- ### ADV 3: Value at risk - quantity expiring within 30 days per supplier
SELECT s.sname, COALESCE(SUM(b.qty), 0) AS qty_expiring_soon
FROM Supplier s LEFT JOIN Medicine_Batch b ON b.supplier_id = s.supplier_id AND b.expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY s.supplier_id, s.sname;

-- ### ADV 4: Negative quantity
-- Error 3819 (chk_batch_qty).
UPDATE Medicine_Batch SET qty = -1 WHERE batch_no = 'BT02';

-- ### ADV 5: Batch of an unknown supplier
-- Error 1452.
INSERT INTO Medicine_Batch VALUES ('BT09', 'Ghost', 5, '2026-01-01', '2028-01-01', 'S9');

-- ### ADV 6: View is read-only for the auditor but the underlying data is the same
-- low_stock follows the data: after the sale of 5 units BT01 (200) is still not low stock, BT03 stays listed.
START TRANSACTION;
CALL sell_medicine('BT04', 100);
SELECT * FROM low_stock;
ROLLBACK;

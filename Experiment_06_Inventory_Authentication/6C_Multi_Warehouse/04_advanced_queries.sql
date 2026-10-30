-- Experiment 6C - additional examiner-style queries (run after 03)
USE warehouse_6c;

-- ### ADV 1: Conservation check - total stock of a product never changes by a transfer
SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id;
CALL transfer_stock('W1', 'W2', 'P1', 3);
SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id;

-- ### ADV 2: Transfer to a warehouse that never stocked the product creates its row
-- W2 never held P2 before; after moving 2 monitors W1 -> W2 a new row (W2, P2, 2) appears.
CALL transfer_stock('W1', 'W2', 'P2', 2);
SELECT * FROM Wh_Stock WHERE prod_id = 'P2';

-- ### ADV 3: Transfer to an unknown warehouse
-- The FK on Wh_Stock rejects the destination row, the handler rolls everything back (the source decrement too).
SELECT qty AS w1_p1_before FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1';
CALL transfer_stock('W1', 'W9', 'P1', 1);
SELECT qty AS w1_p1_after FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1';

-- ### ADV 4: Which warehouse should supply a reorder? (largest stock of the product)
SELECT w.prod_id, w.wh_id, w.qty FROM Wh_Stock w WHERE w.qty = (SELECT MAX(x.qty) FROM Wh_Stock x WHERE x.prod_id = w.prod_id) ORDER BY w.prod_id;

-- ### ADV 5: Transfer history per product
SELECT prod_id, COUNT(*) AS transfers, SUM(qty) AS units_moved FROM Transfer_Log GROUP BY prod_id;

-- ### ADV 6: Negative stock via direct update
-- Error 3819 (chk_whs_qty): even a user holding UPDATE on Wh_Stock cannot make stock negative.
UPDATE Wh_Stock SET qty = -1 WHERE wh_id = 'W1' AND prod_id = 'P1';

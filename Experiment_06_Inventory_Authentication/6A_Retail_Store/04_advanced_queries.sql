-- Experiment 6A - additional examiner-style queries (run after 03)
USE inventory_6a;

-- ### ADV 1: Stock level equals purchases minus sales plus opening stock (reconciliation)
-- Opening values (from the PDF) + all purchases - all sales must equal qty_in_stock for every product.
SELECT p.prod_id, p.qty_in_stock,
       (CASE p.prod_id WHEN 'P1' THEN 40 WHEN 'P2' THEN 8 WHEN 'P3' THEN 6 WHEN 'P4' THEN 150 WHEN 'P5' THEN 12 END)
       + COALESCE((SELECT SUM(qty) FROM Purchase x WHERE x.prod_id = p.prod_id), 0)
       - COALESCE((SELECT SUM(qty) FROM Sale x WHERE x.prod_id = p.prod_id), 0) AS recomputed
FROM Product p;

-- ### ADV 2: Selling exactly the whole stock is allowed, one more is not
START TRANSACTION;
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 8, 'root');
SELECT qty_in_stock FROM Product WHERE prod_id = 'P2';
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 1, 'root');
ROLLBACK;

-- ### ADV 3: Zero or negative sale quantity
-- Error 3819 (chk_sale_qty).
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P4', 0, 'root');

-- ### ADV 4: Reorder suggestion: how many units to order to reach 2 x reorder level
SELECT prod_id, pname, qty_in_stock, reorder_level, GREATEST(2 * reorder_level - qty_in_stock, 0) AS suggested_order_qty FROM Product ORDER BY suggested_order_qty DESC;

-- ### ADV 5: Sales per user
SELECT sold_by, COUNT(*) AS sales, SUM(qty) AS units FROM Sale GROUP BY sold_by;

-- ### ADV 6: Unknown product in a purchase
-- Error 1452 (fk_purchase_product).
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P9', 'S1', 5);

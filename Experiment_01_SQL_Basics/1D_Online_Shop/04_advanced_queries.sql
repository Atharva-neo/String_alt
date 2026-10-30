-- Experiment 1D - additional examiner-style queries (run after 03: customer 1 was cascade-deleted there)
USE shop_1d;

-- ### ADV 1: Order value per order
SELECT o.order_id, SUM(i.qty * p.price) AS order_total FROM Orders o JOIN Order_Item i USING (order_id) JOIN Product p USING (prod_id) GROUP BY o.order_id;

-- ### ADV 2: Customers who never ordered
SELECT c.cust_id, c.name FROM Customer c LEFT JOIN Orders o USING (cust_id) WHERE o.order_id IS NULL;

-- ### ADV 3: Category-wise product count and average price
SELECT category, COUNT(*) AS products, ROUND(AVG(price), 2) AS avg_price FROM Product GROUP BY category;

-- ### ADV 4: Order item for a product that does not exist
-- Error 1452 (fk_item_product).
INSERT INTO Order_Item VALUES (1002, 'P99', 1);

-- ### ADV 5: Negative stock via UPDATE
-- Error 3819: CHECK (stock >= 0) also protects UPDATE, not only INSERT.
UPDATE Product SET stock = stock - 1000 WHERE prod_id = 'P1';

-- ### ADV 6: Same product twice in one order (composite PK)
-- Error 1062: (1002, 'P3') already exists; the application should UPDATE qty instead.
INSERT INTO Order_Item VALUES (1002, 'P3', 1);

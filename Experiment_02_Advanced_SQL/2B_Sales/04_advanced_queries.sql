-- Experiment 2B - additional examiner-style queries
USE sales_2b;

-- ### ADV 1: Running total of revenue by order date (window function)
SELECT o.order_id, o.order_date, o.qty * p.price AS amount, SUM(o.qty * p.price) OVER (ORDER BY o.order_date, o.order_id) AS running_total
FROM Orders o JOIN Product p USING (prod_id);

-- ### ADV 2: Rank customers by revenue (RANK)
SELECT cname, revenue, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank FROM customer_revenue;

-- ### ADV 3: Each customer's share of total revenue (%)
SELECT cname, revenue, ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct FROM customer_revenue;

-- ### ADV 4: NOT IN trap - a NULL in the subquery makes NOT IN return no rows
-- The subquery contains a NULL, so `x NOT IN (..., NULL)` is UNKNOWN for every x and the result is empty. NOT EXISTS is NULL-safe.
SELECT cname FROM Customer WHERE cust_id NOT IN (SELECT 1 UNION SELECT NULL);
SELECT cname FROM Customer c WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 AS v UNION SELECT NULL) t WHERE t.v = c.cust_id);

-- ### ADV 5: Orders with an invalid status
-- CHECK (status IN ('Delivered','Pending')) rejects it with error 3819.
INSERT INTO Orders VALUES (7, 1, 'P2', 1, '2026-10-12', 'Cancelled');

-- ### ADV 6: Products ordered by more than one distinct customer
SELECT p.pname, COUNT(DISTINCT o.cust_id) AS customers FROM Orders o JOIN Product p USING (prod_id) GROUP BY p.prod_id, p.pname HAVING COUNT(DISTINCT o.cust_id) > 1;

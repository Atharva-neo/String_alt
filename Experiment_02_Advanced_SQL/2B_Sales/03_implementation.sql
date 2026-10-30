-- Experiment 2B - Sales : 12 tasks
/* @CONCEPTS
* Amount = `qty * price`, computed in the SELECT list after joining Orders to Product.
* Top-N = `ORDER BY ... DESC LIMIT N`. NOT EXISTS / NOT IN are two ways of writing an anti-join; **NOT IN breaks with NULLs** in the subquery.
* `DATE_FORMAT(order_date,'%Y-%m')` groups by month; HAVING filters on the group total.
* "Customers who ordered **every** product of X" is relational division, written with a double NOT EXISTS.
* Views can wrap a join and a filter; views can be queried like tables, including with further WHERE conditions.
*/

-- ### TASK 1: order_id, customer name, product name and amount (qty x price)
-- Joins Orders with Customer and Product; amount is calculated per order row.
SELECT o.order_id, c.cname, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id ORDER BY o.order_id;

-- ### TASK 2: Total amount spent by each customer
-- Ganesh Traders 30000+13500+25200=68700; Shree Mart 31500+37500=69000; Om Stores 15000; City Bazaar has no orders so LEFT JOIN shows 0.
SELECT c.cname, COALESCE(SUM(o.qty * p.price), 0) AS total_spent
FROM Customer c LEFT JOIN Orders o ON o.cust_id = c.cust_id LEFT JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC;

-- ### TASK 3: Top 3 customers by total purchase amount
-- Same aggregation, ordered descending and cut with LIMIT 3.
SELECT c.cname, SUM(o.qty * p.price) AS total_spent
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC LIMIT 3;

-- ### TASK 4: Products never ordered (NOT EXISTS) and customers who never ordered (NOT IN)
-- Tea (P4) is never ordered; City Bazaar has no orders. NOT IN is safe here because Orders.cust_id is NOT NULL (a NULL in the list would make NOT IN return nothing).
SELECT p.prod_id, p.pname FROM Product p WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.prod_id = p.prod_id);
SELECT c.cust_id, c.cname FROM Customer c WHERE c.cust_id NOT IN (SELECT cust_id FROM Orders);

-- ### TASK 5: Month-wise revenue, only months above 50,000
-- Aug = 30000+31500 = 61500, Sep = 13500+15000 = 28500 (filtered out), Oct = 37500+25200 = 62700.
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m') HAVING SUM(o.qty * p.price) > 50000 ORDER BY month;

-- ### TASK 6: Most ordered product by total quantity
-- Rice 25 kg: 20 + 10 + 25 = 55 units, far above oil (27) and sugar (30).
SELECT p.pname, SUM(o.qty) AS total_qty FROM Orders o JOIN Product p ON p.prod_id = o.prod_id GROUP BY p.prod_id, p.pname ORDER BY total_qty DESC LIMIT 1;

-- ### TASK 7: City-wise number of orders and revenue
SELECT c.city, COUNT(*) AS orders, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.city ORDER BY revenue DESC;

-- ### TASK 8: Orders whose amount is above the average order amount
-- Average amount = 152700 / 6 = 25450. Orders 1 (30000), 2 (31500) and 5 (37500) exceed it; order 6 (25200) is just below.
SELECT o.order_id, o.qty * p.price AS amount
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
WHERE o.qty * p.price > (SELECT AVG(o2.qty * p2.price) FROM Orders o2 JOIN Product p2 ON p2.prod_id = o2.prod_id);

-- ### TASK 9: Customers who ordered every product that Ganesh Traders ordered
-- Relational division with double NOT EXISTS: there must be no product ordered by Ganesh that this customer did not order.
-- Ganesh ordered P1, P2, P3, so only Ganesh himself qualifies; the second query excludes him and returns an empty set.
SELECT c.cname FROM Customer c WHERE NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id));
SELECT c.cname FROM Customer c WHERE c.cname <> 'Ganesh Traders' AND NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id));

-- ### TASK 10: Count orders by status
SELECT status, COUNT(*) AS orders FROM Orders GROUP BY status;

-- ### TASK 11: View pending_orders; query it for Pune customers
-- The view hides the join; filtering on city requires city in the view, so it is included. Shree Mart's pending order 5 = 25 x 1500.
CREATE VIEW pending_orders AS
SELECT o.order_id, c.cname, c.city, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id WHERE o.status = 'Pending';
SELECT * FROM pending_orders;
SELECT * FROM pending_orders WHERE city = 'Pune';

-- ### TASK 12: View customer_revenue; customers whose revenue exceeds 30,000
-- Ganesh Traders (68700) and Shree Mart (69000) qualify; Om Stores (15000) does not.
CREATE VIEW customer_revenue AS
SELECT c.cust_id, c.cname, SUM(o.qty * p.price) AS revenue
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.cust_id, c.cname;
SELECT cname, revenue FROM customer_revenue WHERE revenue > 30000;

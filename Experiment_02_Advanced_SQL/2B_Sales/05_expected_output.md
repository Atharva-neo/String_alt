# Expected output - Experiment_02_Advanced_SQL / 2B_Sales

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - order_id, customer name, product name and amount (qty x price)

```sql
SELECT o.order_id, c.cname, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id ORDER BY o.order_id;
```

**Output**

```text
SELECT o.order_id, c.cname, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id ORDER BY o.order_id

+----------+----------------+-------------+--------+
| order_id | cname          | pname       | amount |
+----------+----------------+-------------+--------+
|        1 | Ganesh Traders | Rice 25 kg  |  30000 |
|        2 | Shree Mart     | Oil 15 L    |  31500 |
|        3 | Ganesh Traders | Sugar 10 kg |  13500 |
|        4 | Om Stores      | Rice 25 kg  |  15000 |
|        5 | Shree Mart     | Rice 25 kg  |  37500 |
|        6 | Ganesh Traders | Oil 15 L    |  25200 |
+----------+----------------+-------------+--------+
6 rows in set
```

**Why this output is correct:** Joins Orders with Customer and Product; amount is calculated per order row.

### Task 2 - Total amount spent by each customer

```sql
SELECT c.cname, COALESCE(SUM(o.qty * p.price), 0) AS total_spent
FROM Customer c LEFT JOIN Orders o ON o.cust_id = c.cust_id LEFT JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC;
```

**Output**

```text
SELECT c.cname, COALESCE(SUM(o.qty * p.price), 0) AS total_spent
FROM Customer c LEFT JOIN Orders o ON o.cust_id = c.cust_id LEFT JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC

+----------------+-------------+
| cname          | total_spent |
+----------------+-------------+
| Shree Mart     |       69000 |
| Ganesh Traders |       68700 |
| Om Stores      |       15000 |
| City Bazaar    |           0 |
+----------------+-------------+
4 rows in set
```

**Why this output is correct:** Ganesh Traders 30000+13500+25200=68700; Shree Mart 31500+37500=69000; Om Stores 15000; City Bazaar has no orders so LEFT JOIN shows 0.

### Task 3 - Top 3 customers by total purchase amount

```sql
SELECT c.cname, SUM(o.qty * p.price) AS total_spent
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC LIMIT 3;
```

**Output**

```text
SELECT c.cname, SUM(o.qty * p.price) AS total_spent
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id
GROUP BY c.cust_id, c.cname ORDER BY total_spent DESC LIMIT 3

+----------------+-------------+
| cname          | total_spent |
+----------------+-------------+
| Shree Mart     |       69000 |
| Ganesh Traders |       68700 |
| Om Stores      |       15000 |
+----------------+-------------+
3 rows in set
```

**Why this output is correct:** Same aggregation, ordered descending and cut with LIMIT 3.

### Task 4 - Products never ordered (NOT EXISTS) and customers who never ordered (NOT IN)

```sql
SELECT p.prod_id, p.pname FROM Product p WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.prod_id = p.prod_id);
SELECT c.cust_id, c.cname FROM Customer c WHERE c.cust_id NOT IN (SELECT cust_id FROM Orders);
```

**Output**

```text
SELECT p.prod_id, p.pname FROM Product p WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.prod_id = p.prod_id)

+---------+----------+
| prod_id | pname    |
+---------+----------+
| P4      | Tea 1 kg |
+---------+----------+
1 row in set

SELECT c.cust_id, c.cname FROM Customer c WHERE c.cust_id NOT IN (SELECT cust_id FROM Orders)

+---------+-------------+
| cust_id | cname       |
+---------+-------------+
|       4 | City Bazaar |
+---------+-------------+
1 row in set
```

**Why this output is correct:** Tea (P4) is never ordered; City Bazaar has no orders. NOT IN is safe here because Orders.cust_id is NOT NULL (a NULL in the list would make NOT IN return nothing).

### Task 5 - Month-wise revenue, only months above 50,000

```sql
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m') HAVING SUM(o.qty * p.price) > 50000 ORDER BY month;
```

**Output**

```text
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m') HAVING SUM(o.qty * p.price) > 50000 ORDER BY month

+---------+---------+
| month   | revenue |
+---------+---------+
| 2026-08 |   61500 |
| 2026-10 |   62700 |
+---------+---------+
2 rows in set
```

**Why this output is correct:** Aug = 30000+31500 = 61500, Sep = 13500+15000 = 28500 (filtered out), Oct = 37500+25200 = 62700.

### Task 6 - Most ordered product by total quantity

```sql
SELECT p.pname, SUM(o.qty) AS total_qty FROM Orders o JOIN Product p ON p.prod_id = o.prod_id GROUP BY p.prod_id, p.pname ORDER BY total_qty DESC LIMIT 1;
```

**Output**

```text
SELECT p.pname, SUM(o.qty) AS total_qty FROM Orders o JOIN Product p ON p.prod_id = o.prod_id GROUP BY p.prod_id, p.pname ORDER BY total_qty DESC LIMIT 1

+------------+-----------+
| pname      | total_qty |
+------------+-----------+
| Rice 25 kg |        55 |
+------------+-----------+
1 row in set
```

**Why this output is correct:** Rice 25 kg: 20 + 10 + 25 = 55 units, far above oil (27) and sugar (30).

### Task 7 - City-wise number of orders and revenue

```sql
SELECT c.city, COUNT(*) AS orders, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.city ORDER BY revenue DESC;
```

**Output**

```text
SELECT c.city, COUNT(*) AS orders, SUM(o.qty * p.price) AS revenue
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.city ORDER BY revenue DESC

+--------+--------+---------+
| city   | orders | revenue |
+--------+--------+---------+
| Pune   |      2 |   69000 |
| Sangli |      3 |   68700 |
| Satara |      1 |   15000 |
+--------+--------+---------+
3 rows in set
```

### Task 8 - Orders whose amount is above the average order amount

```sql
SELECT o.order_id, o.qty * p.price AS amount
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
WHERE o.qty * p.price > (SELECT AVG(o2.qty * p2.price) FROM Orders o2 JOIN Product p2 ON p2.prod_id = o2.prod_id);
```

**Output**

```text
SELECT o.order_id, o.qty * p.price AS amount
FROM Orders o JOIN Product p ON p.prod_id = o.prod_id
WHERE o.qty * p.price > (SELECT AVG(o2.qty * p2.price) FROM Orders o2 JOIN Product p2 ON p2.prod_id = o2.prod_id)

+----------+--------+
| order_id | amount |
+----------+--------+
|        1 |  30000 |
|        2 |  31500 |
|        5 |  37500 |
+----------+--------+
3 rows in set
```

**Why this output is correct:** Average amount = 152700 / 6 = 25450. Orders 1 (30000), 2 (31500) and 5 (37500) exceed it; order 6 (25200) is just below.

### Task 9 - Customers who ordered every product that Ganesh Traders ordered

```sql
SELECT c.cname FROM Customer c WHERE NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id));
SELECT c.cname FROM Customer c WHERE c.cname <> 'Ganesh Traders' AND NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id));
```

**Output**

```text
SELECT c.cname FROM Customer c WHERE NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id))

+----------------+
| cname          |
+----------------+
| Ganesh Traders |
+----------------+
1 row in set

SELECT c.cname FROM Customer c WHERE c.cname <> 'Ganesh Traders' AND NOT EXISTS (
  SELECT 1 FROM Orders g JOIN Customer gc ON gc.cust_id = g.cust_id AND gc.cname = 'Ganesh Traders'
  WHERE NOT EXISTS (SELECT 1 FROM Orders x WHERE x.cust_id = c.cust_id AND x.prod_id = g.prod_id))

Empty set
```

**Why this output is correct:** Relational division with double NOT EXISTS: there must be no product ordered by Ganesh that this customer did not order. Ganesh ordered P1, P2, P3, so only Ganesh himself qualifies; the second query excludes him and returns an empty set.

### Task 10 - Count orders by status

```sql
SELECT status, COUNT(*) AS orders FROM Orders GROUP BY status;
```

**Output**

```text
SELECT status, COUNT(*) AS orders FROM Orders GROUP BY status

+-----------+--------+
| status    | orders |
+-----------+--------+
| Delivered |      4 |
| Pending   |      2 |
+-----------+--------+
2 rows in set
```

### Task 11 - View pending_orders; query it for Pune customers

```sql
CREATE VIEW pending_orders AS
SELECT o.order_id, c.cname, c.city, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id WHERE o.status = 'Pending';
SELECT * FROM pending_orders;
SELECT * FROM pending_orders WHERE city = 'Pune';
```

**Output**

```text
CREATE VIEW pending_orders AS
SELECT o.order_id, c.cname, c.city, p.pname, o.qty * p.price AS amount
FROM Orders o JOIN Customer c ON c.cust_id = o.cust_id JOIN Product p ON p.prod_id = o.prod_id WHERE o.status = 'Pending'

Query OK, 0 rows affected

SELECT * FROM pending_orders

+----------+----------------+--------+-------------+--------+
| order_id | cname          | city   | pname       | amount |
+----------+----------------+--------+-------------+--------+
|        3 | Ganesh Traders | Sangli | Sugar 10 kg |  13500 |
|        5 | Shree Mart     | Pune   | Rice 25 kg  |  37500 |
+----------+----------------+--------+-------------+--------+
2 rows in set

SELECT * FROM pending_orders WHERE city = 'Pune'

+----------+------------+------+------------+--------+
| order_id | cname      | city | pname      | amount |
+----------+------------+------+------------+--------+
|        5 | Shree Mart | Pune | Rice 25 kg |  37500 |
+----------+------------+------+------------+--------+
1 row in set
```

**Why this output is correct:** The view hides the join; filtering on city requires city in the view, so it is included. Shree Mart's pending order 5 = 25 x 1500.

### Task 12 - View customer_revenue; customers whose revenue exceeds 30,000

```sql
CREATE VIEW customer_revenue AS
SELECT c.cust_id, c.cname, SUM(o.qty * p.price) AS revenue
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.cust_id, c.cname;
SELECT cname, revenue FROM customer_revenue WHERE revenue > 30000;
```

**Output**

```text
CREATE VIEW customer_revenue AS
SELECT c.cust_id, c.cname, SUM(o.qty * p.price) AS revenue
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id JOIN Product p ON p.prod_id = o.prod_id GROUP BY c.cust_id, c.cname

Query OK, 0 rows affected

SELECT cname, revenue FROM customer_revenue WHERE revenue > 30000

+----------------+---------+
| cname          | revenue |
+----------------+---------+
| Ganesh Traders |   68700 |
| Shree Mart     |   69000 |
+----------------+---------+
2 rows in set
```

**Why this output is correct:** Ganesh Traders (68700) and Shree Mart (69000) qualify; Om Stores (15000) does not.


## Advanced / examiner-style queries

### Adv 1 - Running total of revenue by order date (window function)

```sql
SELECT o.order_id, o.order_date, o.qty * p.price AS amount, SUM(o.qty * p.price) OVER (ORDER BY o.order_date, o.order_id) AS running_total
FROM Orders o JOIN Product p USING (prod_id);
```

**Output**

```text
SELECT o.order_id, o.order_date, o.qty * p.price AS amount, SUM(o.qty * p.price) OVER (ORDER BY o.order_date, o.order_id) AS running_total
FROM Orders o JOIN Product p USING (prod_id)

+----------+------------+--------+---------------+
| order_id | order_date | amount | running_total |
+----------+------------+--------+---------------+
|        1 | 2026-08-04 |  30000 |         30000 |
|        2 | 2026-08-19 |  31500 |         61500 |
|        3 | 2026-09-02 |  13500 |         75000 |
|        4 | 2026-09-15 |  15000 |         90000 |
|        5 | 2026-10-01 |  37500 |        127500 |
|        6 | 2026-10-10 |  25200 |        152700 |
+----------+------------+--------+---------------+
6 rows in set
```

### Adv 2 - Rank customers by revenue (RANK)

```sql
SELECT cname, revenue, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank FROM customer_revenue;
```

**Output**

```text
SELECT cname, revenue, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank FROM customer_revenue

+----------------+---------+--------------+
| cname          | revenue | revenue_rank |
+----------------+---------+--------------+
| Shree Mart     |   69000 |            1 |
| Ganesh Traders |   68700 |            2 |
| Om Stores      |   15000 |            3 |
+----------------+---------+--------------+
3 rows in set
```

### Adv 3 - Each customer's share of total revenue (%)

```sql
SELECT cname, revenue, ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct FROM customer_revenue;
```

**Output**

```text
SELECT cname, revenue, ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct FROM customer_revenue

+----------------+---------+-------+
| cname          | revenue | pct   |
+----------------+---------+-------+
| Ganesh Traders |   68700 | 44.99 |
| Shree Mart     |   69000 | 45.19 |
| Om Stores      |   15000 |  9.82 |
+----------------+---------+-------+
3 rows in set
```

### Adv 4 - NOT IN trap - a NULL in the subquery makes NOT IN return no rows

```sql
SELECT cname FROM Customer WHERE cust_id NOT IN (SELECT 1 UNION SELECT NULL);
SELECT cname FROM Customer c WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 AS v UNION SELECT NULL) t WHERE t.v = c.cust_id);
```

**Output**

```text
SELECT cname FROM Customer WHERE cust_id NOT IN (SELECT 1 UNION SELECT NULL)

Empty set

SELECT cname FROM Customer c WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 AS v UNION SELECT NULL) t WHERE t.v = c.cust_id)

+-------------+
| cname       |
+-------------+
| Shree Mart  |
| Om Stores   |
| City Bazaar |
+-------------+
3 rows in set
```

**Why this output is correct:** The subquery contains a NULL, so `x NOT IN (..., NULL)` is UNKNOWN for every x and the result is empty. NOT EXISTS is NULL-safe.

### Adv 5 - Orders with an invalid status

```sql
INSERT INTO Orders VALUES (7, 1, 'P2', 1, '2026-10-12', 'Cancelled');
```

**Output**

```text
INSERT INTO Orders VALUES (7, 1, 'P2', 1, '2026-10-12', 'Cancelled')

ERROR 3819 (HY000) at line 1: Check constraint 'chk_o_status' is violated.
```

**Why this output is correct:** CHECK (status IN ('Delivered','Pending')) rejects it with error 3819.

### Adv 6 - Products ordered by more than one distinct customer

```sql
SELECT p.pname, COUNT(DISTINCT o.cust_id) AS customers FROM Orders o JOIN Product p USING (prod_id) GROUP BY p.prod_id, p.pname HAVING COUNT(DISTINCT o.cust_id) > 1;
```

**Output**

```text
SELECT p.pname, COUNT(DISTINCT o.cust_id) AS customers FROM Orders o JOIN Product p USING (prod_id) GROUP BY p.prod_id, p.pname HAVING COUNT(DISTINCT o.cust_id) > 1

+------------+-----------+
| pname      | customers |
+------------+-----------+
| Rice 25 kg |         3 |
| Oil 15 L   |         2 |
+------------+-----------+
2 rows in set
```

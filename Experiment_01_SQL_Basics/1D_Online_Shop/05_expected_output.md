# Expected output - Experiment_01_SQL_Basics / 1D_Online_Shop

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - ER diagram for Customer, Product, Orders, Order_Item

```sql
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'shop_1d' ORDER BY table_name, constraint_type;
```

**Output**

```text
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'shop_1d' ORDER BY table_name, constraint_type

+------------+-------------------+-----------------+
| TABLE_NAME | CONSTRAINT_NAME   | CONSTRAINT_TYPE |
+------------+-------------------+-----------------+
| customer   | PRIMARY           | PRIMARY KEY     |
| order_item | chk_item_qty      | CHECK           |
| order_item | fk_item_order     | FOREIGN KEY     |
| order_item | fk_item_product   | FOREIGN KEY     |
| order_item | PRIMARY           | PRIMARY KEY     |
| orders     | fk_orders_cust    | FOREIGN KEY     |
| orders     | PRIMARY           | PRIMARY KEY     |
| product    | chk_product_stock | CHECK           |
| product    | PRIMARY           | PRIMARY KEY     |
+------------+-------------------+-----------------+
9 rows in set
```

**Why this output is correct:** Customer 1:N Orders, Orders 1:N Order_Item, Product 1:N Order_Item (Orders M:N Product). See 06_explanation.md.

### Task 2 - Tables with composite PK and CHECKs

```sql
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'shop_1d';
```

**Output**

```text
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'shop_1d'

+-------------------+----------------+
| CONSTRAINT_NAME   | CHECK_CLAUSE   |
+-------------------+----------------+
| chk_item_qty      | (`qty` > 0)    |
| chk_product_stock | (`stock` >= 0) |
+-------------------+----------------+
2 rows in set
```

### Task 3 - Insert data; Order_Item with qty 0 must fail

```sql
SELECT * FROM Order_Item;
INSERT INTO Order_Item VALUES (1003, 'P2', 0);
```

**Output**

```text
SELECT * FROM Order_Item

+----------+---------+-----+
| order_id | prod_id | qty |
+----------+---------+-----+
|     1001 | P1      |   1 |
|     1001 | P2      |   2 |
|     1002 | P3      |  10 |
|     1003 | P4      |   1 |
+----------+---------+-----+
4 rows in set

INSERT INTO Order_Item VALUES (1003, 'P2', 0)

ERROR 3819 (HY000) at line 2: Check constraint 'chk_item_qty' is violated.
```

**Why this output is correct:** qty = 0 violates chk_item_qty (error 3819).

### Task 4 - Product with a duplicate prod_id

```sql
INSERT INTO Product VALUES ('P1', 'Another Laptop', 'Electronics', 40000, 5);
```

**Output**

```text
INSERT INTO Product VALUES ('P1', 'Another Laptop', 'Electronics', 40000, 5)

ERROR 1062 (23000) at line 1: Duplicate entry 'P1' for key 'product.PRIMARY'
```

**Why this output is correct:** 'P1' already exists -> error 1062 Duplicate entry for key 'product.PRIMARY'.

### Task 5 - All orders of Sagar with product names

```sql
SELECT o.order_id, o.order_date, p.name AS product, i.qty, p.price * i.qty AS line_amount
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id
JOIN Order_Item i ON i.order_id = o.order_id
JOIN Product p ON p.prod_id = i.prod_id
WHERE c.name = 'Sagar' ORDER BY o.order_id;
```

**Output**

```text
SELECT o.order_id, o.order_date, p.name AS product, i.qty, p.price * i.qty AS line_amount
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id
JOIN Order_Item i ON i.order_id = o.order_id
JOIN Product p ON p.prod_id = i.prod_id
WHERE c.name = 'Sagar' ORDER BY o.order_id

+----------+------------+-----------+-----+-------------+
| order_id | order_date | product   | qty | line_amount |
+----------+------------+-----------+-----+-------------+
|     1001 | 2026-10-02 | Laptop    |   1 |    55000.00 |
|     1001 | 2026-10-02 | Mouse     |   2 |     1000.00 |
|     1003 | 2026-10-09 | Desk Lamp |   1 |     1200.00 |
+----------+------------+-----------+-----+-------------+
3 rows in set
```

**Why this output is correct:** Customer -> Orders -> Order_Item -> Product join, filtered by customer name; qty*price gives the line amount.

### Task 6 - Reduce stock of each product by the quantity ordered

```sql
UPDATE Product p
JOIN (SELECT prod_id, SUM(qty) AS ordered FROM Order_Item GROUP BY prod_id) o ON o.prod_id = p.prod_id
SET p.stock = p.stock - o.ordered;
SELECT prod_id, name, stock FROM Product;
```

**Output**

```text
UPDATE Product p
JOIN (SELECT prod_id, SUM(qty) AS ordered FROM Order_Item GROUP BY prod_id) o ON o.prod_id = p.prod_id
SET p.stock = p.stock - o.ordered

Query OK, 4 rows affected
Rows matched: 4  Changed: 4  Warnings: 0

SELECT prod_id, name, stock FROM Product

+---------+-----------+-------+
| prod_id | name      | stock |
+---------+-----------+-------+
| P1      | Laptop    |     9 |
| P2      | Mouse     |    98 |
| P3      | Notebook  |   490 |
| P4      | Desk Lamp |    24 |
+---------+-----------+-------+
4 rows in set
```

**Why this output is correct:** The derived table sums quantities per product; the UPDATE joins to it. P1 10->9, P2 100->98, P3 500->490, P4 25->24.

### Task 7 - Products whose stock is below 20

```sql
SELECT prod_id, name, stock FROM Product WHERE stock < 20;
```

**Output**

```text
SELECT prod_id, name, stock FROM Product WHERE stock < 20

+---------+--------+-------+
| prod_id | name   | stock |
+---------+--------+-------+
| P1      | Laptop |     9 |
+---------+--------+-------+
1 row in set
```

**Why this output is correct:** Only the Laptop (9) is below 20 after Task 6.

### Task 8 - Add discount column with DEFAULT 0 and CHECK (discount BETWEEN 0 AND 50)

```sql
ALTER TABLE Product ADD COLUMN discount INT NOT NULL DEFAULT 0, ADD CONSTRAINT chk_product_discount CHECK (discount BETWEEN 0 AND 50);
UPDATE Product SET discount = 60 WHERE prod_id = 'P2';
SELECT prod_id, name, discount FROM Product;
```

**Output**

```text
ALTER TABLE Product ADD COLUMN discount INT NOT NULL DEFAULT 0, ADD CONSTRAINT chk_product_discount CHECK (discount BETWEEN 0 AND 50)

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

UPDATE Product SET discount = 60 WHERE prod_id = 'P2'

ERROR 3819 (HY000) at line 2: Check constraint 'chk_product_discount' is violated.
SELECT prod_id, name, discount FROM Product

+---------+-----------+----------+
| prod_id | name      | discount |
+---------+-----------+----------+
| P1      | Laptop    |        0 |
| P2      | Mouse     |        0 |
| P3      | Notebook  |        0 |
| P4      | Desk Lamp |        0 |
+---------+-----------+----------+
4 rows in set
```

**Why this output is correct:** Existing rows get 0. Value 60 is rejected by the new CHECK.

### Task 9 - Increase Stationery prices by 5%

```sql
UPDATE Product SET price = price * 1.05 WHERE category = 'Stationery';
SELECT prod_id, name, category, price FROM Product;
```

**Output**

```text
UPDATE Product SET price = price * 1.05 WHERE category = 'Stationery'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT prod_id, name, category, price FROM Product

+---------+-----------+-------------+----------+
| prod_id | name      | category    | price    |
+---------+-----------+-------------+----------+
| P1      | Laptop    | Electronics | 55000.00 |
| P2      | Mouse     | Electronics |   500.00 |
| P3      | Notebook  | Stationery  |    63.00 |
| P4      | Desk Lamp | Home        |  1200.00 |
+---------+-----------+-------------+----------+
4 rows in set
```

**Why this output is correct:** Only Notebook (60) changes: 60 * 1.05 = 63.

### Task 10 - Delete customer 1 with a plain FK (error), then with ON DELETE CASCADE

```sql
DELETE FROM Customer WHERE cust_id = 1;
SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items;
ALTER TABLE Orders     DROP FOREIGN KEY fk_orders_cust;
ALTER TABLE Order_Item DROP FOREIGN KEY fk_item_order;
ALTER TABLE Orders     ADD CONSTRAINT fk_orders_cust FOREIGN KEY (cust_id)  REFERENCES Customer(cust_id) ON DELETE CASCADE;
ALTER TABLE Order_Item ADD CONSTRAINT fk_item_order  FOREIGN KEY (order_id) REFERENCES Orders(order_id)  ON DELETE CASCADE;
DELETE FROM Customer WHERE cust_id = 1;
SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items;
SELECT * FROM Orders;
SELECT * FROM Order_Item;
```

**Output**

```text
DELETE FROM Customer WHERE cust_id = 1

ERROR 1451 (23000) at line 1: Cannot delete or update a parent row: a foreign key constraint fails (`shop_1d`.`orders`, CONSTRAINT `fk_orders_cust` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`))
SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items

+-----------+--------+-------+
| customers | orders | items |
+-----------+--------+-------+
|         3 |      3 |     4 |
+-----------+--------+-------+
1 row in set

ALTER TABLE Orders     DROP FOREIGN KEY fk_orders_cust

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

ALTER TABLE Order_Item DROP FOREIGN KEY fk_item_order

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

ALTER TABLE Orders     ADD CONSTRAINT fk_orders_cust FOREIGN KEY (cust_id)  REFERENCES Customer(cust_id) ON DELETE CASCADE

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

ALTER TABLE Order_Item ADD CONSTRAINT fk_item_order  FOREIGN KEY (order_id) REFERENCES Orders(order_id)  ON DELETE CASCADE

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

DELETE FROM Customer WHERE cust_id = 1

Query OK, 1 row affected

SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items

+-----------+--------+-------+
| customers | orders | items |
+-----------+--------+-------+
|         2 |      1 |     1 |
+-----------+--------+-------+
1 row in set

SELECT * FROM Orders

+----------+---------+------------+
| order_id | cust_id | order_date |
+----------+---------+------------+
|     1002 |       2 | 2026-10-05 |
+----------+---------+------------+
1 row in set

SELECT * FROM Order_Item

+----------+---------+-----+
| order_id | prod_id | qty |
+----------+---------+-----+
|     1002 | P3      |  10 |
+----------+---------+-----+
1 row in set
```

**Why this output is correct:** Plain FK: error 1451 because Orders 1001 and 1003 belong to Sagar. The cascade must be defined on Orders->Customer AND Order_Item->Orders because Order_Item rows hang below Orders. After the delete, Sagar, orders 1001/1003 and their 3 items are gone.

### Task 11 - Role sales_staff (SELECT on Product, INSERT on Orders) granted to a new user

```sql
DROP USER IF EXISTS 'shop_user'@'localhost';
DROP ROLE IF EXISTS 'sales_staff';
CREATE ROLE 'sales_staff';
GRANT SELECT ON shop_1d.Product TO 'sales_staff';
GRANT INSERT ON shop_1d.Orders  TO 'sales_staff';
CREATE USER 'shop_user'@'localhost' IDENTIFIED BY 'Shop@12345';
GRANT 'sales_staff' TO 'shop_user'@'localhost';
SET DEFAULT ROLE 'sales_staff' TO 'shop_user'@'localhost';
SHOW GRANTS FOR 'shop_user'@'localhost' USING 'sales_staff';
-- @as shop_user Shop@12345
-- | SELECT prod_id, name FROM Product LIMIT 2;
-- | INSERT INTO Orders VALUES (1004, 2, '2026-10-20');
```

**Output**

```text
DROP USER IF EXISTS 'shop_user'@'localhost'

Query OK, 0 rows affected

DROP ROLE IF EXISTS 'sales_staff'

Query OK, 0 rows affected

CREATE ROLE 'sales_staff'

Query OK, 0 rows affected

GRANT SELECT ON shop_1d.Product TO 'sales_staff'

Query OK, 0 rows affected

GRANT INSERT ON shop_1d.Orders  TO 'sales_staff'

Query OK, 0 rows affected

CREATE USER 'shop_user'@'localhost' IDENTIFIED BY 'Shop@12345'

Query OK, 0 rows affected

GRANT 'sales_staff' TO 'shop_user'@'localhost'

Query OK, 0 rows affected

SET DEFAULT ROLE 'sales_staff' TO 'shop_user'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'shop_user'@'localhost' USING 'sales_staff'

+----------------------------------------------------------------+
| Grants for shop_user@localhost                                 |
+----------------------------------------------------------------+
| GRANT USAGE ON *.* TO `shop_user`@`localhost`                  |
| GRANT INSERT ON `shop_1d`.`orders` TO `shop_user`@`localhost`  |
| GRANT SELECT ON `shop_1d`.`product` TO `shop_user`@`localhost` |
| GRANT `sales_staff`@`%` TO `shop_user`@`localhost`             |
+----------------------------------------------------------------+
4 rows in set

[session: user 'shop_user']
SELECT prod_id, name FROM Product LIMIT 2

+---------+--------+
| prod_id | name   |
+---------+--------+
| P1      | Laptop |
| P2      | Mouse  |
+---------+--------+
2 rows in set

INSERT INTO Orders VALUES (1004, 2, '2026-10-20')

Query OK, 1 row affected
```

**Why this output is correct:** The user inherits privileges through the role. SET DEFAULT ROLE activates it at login.

### Task 12 - Revoke INSERT from the role; the user can no longer insert orders

```sql
DELETE FROM Orders WHERE order_id = 1004;
REVOKE INSERT ON shop_1d.Orders FROM 'sales_staff';
SHOW GRANTS FOR 'shop_user'@'localhost' USING 'sales_staff';
-- @as shop_user Shop@12345
-- | INSERT INTO Orders VALUES (1005, 2, '2026-10-21');
-- | SELECT COUNT(*) AS products_visible FROM Product;
```

**Output**

```text
DELETE FROM Orders WHERE order_id = 1004

Query OK, 1 row affected

REVOKE INSERT ON shop_1d.Orders FROM 'sales_staff'

Query OK, 0 rows affected

SHOW GRANTS FOR 'shop_user'@'localhost' USING 'sales_staff'

+----------------------------------------------------------------+
| Grants for shop_user@localhost                                 |
+----------------------------------------------------------------+
| GRANT USAGE ON *.* TO `shop_user`@`localhost`                  |
| GRANT SELECT ON `shop_1d`.`product` TO `shop_user`@`localhost` |
| GRANT `sales_staff`@`%` TO `shop_user`@`localhost`             |
+----------------------------------------------------------------+
3 rows in set

[session: user 'shop_user']
INSERT INTO Orders VALUES (1005, 2, '2026-10-21')

ERROR 1142 (42000) at line 1: INSERT command denied to user 'shop_user'@'localhost' for table 'orders'
SELECT COUNT(*) AS products_visible FROM Product

+------------------+
| products_visible |
+------------------+
|                4 |
+------------------+
1 row in set
```

**Why this output is correct:** Revoking from the role immediately affects every user holding it. New INSERT -> ERROR 1142.


## Advanced / examiner-style queries

### Adv 1 - Order value per order

```sql
SELECT o.order_id, SUM(i.qty * p.price) AS order_total FROM Orders o JOIN Order_Item i USING (order_id) JOIN Product p USING (prod_id) GROUP BY o.order_id;
```

**Output**

```text
SELECT o.order_id, SUM(i.qty * p.price) AS order_total FROM Orders o JOIN Order_Item i USING (order_id) JOIN Product p USING (prod_id) GROUP BY o.order_id

+----------+-------------+
| order_id | order_total |
+----------+-------------+
|     1002 |      630.00 |
+----------+-------------+
1 row in set
```

### Adv 2 - Customers who never ordered

```sql
SELECT c.cust_id, c.name FROM Customer c LEFT JOIN Orders o USING (cust_id) WHERE o.order_id IS NULL;
```

**Output**

```text
SELECT c.cust_id, c.name FROM Customer c LEFT JOIN Orders o USING (cust_id) WHERE o.order_id IS NULL

+---------+-------+
| cust_id | name  |
+---------+-------+
|       3 | Vikas |
+---------+-------+
1 row in set
```

### Adv 3 - Category-wise product count and average price

```sql
SELECT category, COUNT(*) AS products, ROUND(AVG(price), 2) AS avg_price FROM Product GROUP BY category;
```

**Output**

```text
SELECT category, COUNT(*) AS products, ROUND(AVG(price), 2) AS avg_price FROM Product GROUP BY category

+-------------+----------+-----------+
| category    | products | avg_price |
+-------------+----------+-----------+
| Electronics |        2 |  27750.00 |
| Stationery  |        1 |     63.00 |
| Home        |        1 |   1200.00 |
+-------------+----------+-----------+
3 rows in set
```

### Adv 4 - Order item for a product that does not exist

```sql
INSERT INTO Order_Item VALUES (1002, 'P99', 1);
```

**Output**

```text
INSERT INTO Order_Item VALUES (1002, 'P99', 1)

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`shop_1d`.`order_item`, CONSTRAINT `fk_item_product` FOREIGN KEY (`prod_id`) REFERENCES `product` (`prod_id`))
```

**Why this output is correct:** Error 1452 (fk_item_product).

### Adv 5 - Negative stock via UPDATE

```sql
UPDATE Product SET stock = stock - 1000 WHERE prod_id = 'P1';
```

**Output**

```text
UPDATE Product SET stock = stock - 1000 WHERE prod_id = 'P1'

ERROR 3819 (HY000) at line 1: Check constraint 'chk_product_stock' is violated.
```

**Why this output is correct:** Error 3819: CHECK (stock >= 0) also protects UPDATE, not only INSERT.

### Adv 6 - Same product twice in one order (composite PK)

```sql
INSERT INTO Order_Item VALUES (1002, 'P3', 1);
```

**Output**

```text
INSERT INTO Order_Item VALUES (1002, 'P3', 1)

ERROR 1062 (23000) at line 1: Duplicate entry '1002-P3' for key 'order_item.PRIMARY'
```

**Why this output is correct:** Error 1062: (1002, 'P3') already exists; the application should UPDATE qty instead.

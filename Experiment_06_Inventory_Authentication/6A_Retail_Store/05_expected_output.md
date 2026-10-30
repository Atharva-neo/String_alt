# Expected output - Experiment_06_Inventory_Authentication / 6A_Retail_Store

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - ER diagram, tables with keys and constraints, data

```sql
SELECT * FROM Product;
SELECT * FROM Stock;
```

**Output**

```text
SELECT * FROM Product

+---------+-----------+-------------+---------+--------------+---------------+-------------+
| prod_id | pname     | category    | price   | qty_in_stock | reorder_level | supplier_id |
+---------+-----------+-------------+---------+--------------+---------------+-------------+
| P1      | Keyboard  | Electronics |  700.00 |           40 |            10 | S1          |
| P2      | Monitor   | Electronics | 9000.00 |            8 |             5 | S3          |
| P3      | A4 Paper  | Stationery  |  250.00 |            6 |            20 | S2          |
| P4      | Marker    | Stationery  |   30.00 |          150 |            50 | S2          |
| P5      | USB Drive | Electronics |  450.00 |           12 |            15 | S1          |
+---------+-----------+-------------+---------+--------------+---------------+-------------+
5 rows in set

SELECT * FROM Stock

+---------+-----------+--------------+---------------+---------+
| prod_id | pname     | qty_in_stock | reorder_level | status  |
+---------+-----------+--------------+---------------+---------+
| P1      | Keyboard  |           40 |            10 | OK      |
| P2      | Monitor   |            8 |             5 | OK      |
| P3      | A4 Paper  |            6 |            20 | REORDER |
| P4      | Marker    |          150 |            50 | OK      |
| P5      | USB Drive |           12 |            15 | REORDER |
+---------+-----------+--------------+---------------+---------+
5 rows in set
```

**Why this output is correct:** The ER diagram is in 06_explanation.md. Product.category is a FK to Category; Purchase/Sale reference Product; CHECKs keep price > 0 and stock >= 0.

### Task 2 - AFTER INSERT trigger on Purchase adds qty to stock

```sql
DELIMITER $$
CREATE TRIGGER trg_purchase_add_stock AFTER INSERT ON Purchase FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock + NEW.qty WHERE prod_id = NEW.prod_id;
END$$
DELIMITER ;
SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a';
```

**Output**

```text
CREATE TRIGGER trg_purchase_add_stock AFTER INSERT ON Purchase FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock + NEW.qty WHERE prod_id = NEW.prod_id;
END

Query OK, 0 rows affected

SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a'

+------------------------+--------------------+---------------+--------------------+
| TRIGGER_NAME           | EVENT_OBJECT_TABLE | ACTION_TIMING | EVENT_MANIPULATION |
+------------------------+--------------------+---------------+--------------------+
| trg_purchase_add_stock | purchase           | AFTER         | INSERT             |
+------------------------+--------------------+---------------+--------------------+
1 row in set
```

### Task 3 - BEFORE INSERT trigger on Sale blocks the sale if stock is short

```sql
DELIMITER $$
CREATE TRIGGER trg_sale_check_stock BEFORE INSERT ON Sale FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    SELECT qty_in_stock INTO v_stock FROM Product WHERE prod_id = NEW.prod_id;
    IF v_stock IS NULL OR NEW.qty > v_stock THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for this sale';
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a' ORDER BY trigger_name;
```

**Output**

```text
CREATE TRIGGER trg_sale_check_stock BEFORE INSERT ON Sale FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    SELECT qty_in_stock INTO v_stock FROM Product WHERE prod_id = NEW.prod_id;
    IF v_stock IS NULL OR NEW.qty > v_stock THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for this sale';
    END IF;
END

Query OK, 0 rows affected

SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a' ORDER BY trigger_name

+------------------------+--------------------+---------------+--------------------+
| TRIGGER_NAME           | EVENT_OBJECT_TABLE | ACTION_TIMING | EVENT_MANIPULATION |
+------------------------+--------------------+---------------+--------------------+
| trg_purchase_add_stock | purchase           | AFTER         | INSERT             |
| trg_sale_check_stock   | sale               | BEFORE        | INSERT             |
+------------------------+--------------------+---------------+--------------------+
2 rows in set
```

**Why this output is correct:** Reads the current stock; if NEW.qty is bigger it SIGNALs 'Insufficient stock' and the INSERT is rejected before anything is written.

### Task 4 - AFTER INSERT trigger on Sale reduces stock

```sql
DELIMITER $$
CREATE TRIGGER trg_sale_reduce_stock AFTER INSERT ON Sale FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock - NEW.qty WHERE prod_id = NEW.prod_id;
END$$
DELIMITER ;
SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a' ORDER BY trigger_name;
```

**Output**

```text
CREATE TRIGGER trg_sale_reduce_stock AFTER INSERT ON Sale FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock - NEW.qty WHERE prod_id = NEW.prod_id;
END

Query OK, 0 rows affected

SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a' ORDER BY trigger_name

+------------------------+--------------------+---------------+--------------------+
| TRIGGER_NAME           | EVENT_OBJECT_TABLE | ACTION_TIMING | EVENT_MANIPULATION |
+------------------------+--------------------+---------------+--------------------+
| trg_purchase_add_stock | purchase           | AFTER         | INSERT             |
| trg_sale_check_stock   | sale               | BEFORE        | INSERT             |
| trg_sale_reduce_stock  | sale               | AFTER         | INSERT             |
+------------------------+--------------------+---------------+--------------------+
3 rows in set
```

### Task 5 - Insert purchase (P3, S2, 50) and sale (P2, 10) - show the result and the error

```sql
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P3', 'S2', 50);
INSERT INTO Sale (prod_id, qty) VALUES ('P2', 10);
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P1', 5, 'root');
SELECT prod_id, pname, qty_in_stock FROM Product ORDER BY prod_id;
SELECT * FROM Purchase; SELECT * FROM Sale;
```

**Output**

```text
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P3', 'S2', 50)

Query OK, 1 row affected

INSERT INTO Sale (prod_id, qty) VALUES ('P2', 10)

ERROR 1644 (45000) at line 2: Insufficient stock for this sale
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P1', 5, 'root')

Query OK, 1 row affected

SELECT prod_id, pname, qty_in_stock FROM Product ORDER BY prod_id

+---------+-----------+--------------+
| prod_id | pname     | qty_in_stock |
+---------+-----------+--------------+
| P1      | Keyboard  |           35 |
| P2      | Monitor   |            8 |
| P3      | A4 Paper  |           56 |
| P4      | Marker    |          150 |
| P5      | USB Drive |           12 |
+---------+-----------+--------------+
5 rows in set

SELECT * FROM Purchase

+--------+---------+-------------+-----+------------+
| pur_id | prod_id | supplier_id | qty | pur_date   |
+--------+---------+-------------+-----+------------+
|      1 | P3      | S2          |  50 | 2026-10-30 |
+--------+---------+-------------+-----+------------+
1 row in set

SELECT * FROM Sale

+---------+---------+-----+------------+---------+
| sale_id | prod_id | qty | sale_date  | sold_by |
+---------+---------+-----+------------+---------+
|       1 | P1      |   5 | 2026-10-30 | root    |
+---------+---------+-----+------------+---------+
1 row in set
```

**Why this output is correct:** Purchase: A4 Paper stock 6 + 50 = 56. Sale of 10 monitors: stock is only 8, so the BEFORE trigger raises 'Insufficient stock' and stock stays 8. A valid sale (P1, 5) is added afterwards to show the AFTER trigger: Keyboard 40 -> 35.

### Task 6 - Products at or below reorder level with supplier name and phone

```sql
SELECT p.prod_id, p.pname, p.qty_in_stock, p.reorder_level, s.sname, s.phone
FROM Product p JOIN Supplier s ON s.supplier_id = p.supplier_id
WHERE p.qty_in_stock <= p.reorder_level ORDER BY p.prod_id;
```

**Output**

```text
SELECT p.prod_id, p.pname, p.qty_in_stock, p.reorder_level, s.sname, s.phone
FROM Product p JOIN Supplier s ON s.supplier_id = p.supplier_id
WHERE p.qty_in_stock <= p.reorder_level ORDER BY p.prod_id

+---------+-----------+--------------+---------------+-----------------+------------+
| prod_id | pname     | qty_in_stock | reorder_level | sname           | phone      |
+---------+-----------+--------------+---------------+-----------------+------------+
| P5      | USB Drive |           12 |            15 | Om Distributors | 9850011111 |
+---------+-----------+--------------+---------------+-----------------+------------+
1 row in set
```

**Why this output is correct:** After task 5 the A4 paper is 56 (> 20); only the USB Drive (12 <= 15) needs re-ordering.

### Task 7 - Category-wise stock value (qty x price)

```sql
SELECT category, SUM(qty_in_stock * price) AS stock_value, SUM(qty_in_stock) AS units FROM Product GROUP BY category;
```

**Output**

```text
SELECT category, SUM(qty_in_stock * price) AS stock_value, SUM(qty_in_stock) AS units FROM Product GROUP BY category

+-------------+-------------+-------+
| category    | stock_value | units |
+-------------+-------------+-------+
| Electronics |   101900.00 |    55 |
| Stationery  |    18500.00 |   206 |
+-------------+-------------+-------+
2 rows in set
```

### Task 8 - Roles admin, store_manager, clerk and their privileges

```sql
DROP USER IF EXISTS 'mgr1'@'localhost';
DROP USER IF EXISTS 'clerk1'@'localhost';
DROP ROLE IF EXISTS 'admin', 'store_manager', 'clerk';
CREATE ROLE 'admin', 'store_manager', 'clerk';
GRANT ALL PRIVILEGES ON inventory_6a.* TO 'admin';
GRANT SELECT, UPDATE (price) ON inventory_6a.Product TO 'store_manager';
GRANT INSERT ON inventory_6a.Sale TO 'clerk';
GRANT SELECT ON inventory_6a.Product TO 'clerk';
SHOW GRANTS FOR 'store_manager';
SHOW GRANTS FOR 'clerk';
```

**Output**

```text
DROP USER IF EXISTS 'mgr1'@'localhost'

Query OK, 0 rows affected

DROP USER IF EXISTS 'clerk1'@'localhost'

Query OK, 0 rows affected

DROP ROLE IF EXISTS 'admin', 'store_manager', 'clerk'

Query OK, 0 rows affected

CREATE ROLE 'admin', 'store_manager', 'clerk'

Query OK, 0 rows affected

GRANT ALL PRIVILEGES ON inventory_6a.* TO 'admin'

Query OK, 0 rows affected

GRANT SELECT, UPDATE (price) ON inventory_6a.Product TO 'store_manager'

Query OK, 0 rows affected

GRANT INSERT ON inventory_6a.Sale TO 'clerk'

Query OK, 0 rows affected

GRANT SELECT ON inventory_6a.Product TO 'clerk'

Query OK, 0 rows affected

SHOW GRANTS FOR 'store_manager'

+-----------------------------------------------------------------------------------+
| Grants for store_manager@%                                                        |
+-----------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `store_manager`@`%`                                         |
| GRANT SELECT, UPDATE (`price`) ON `inventory_6a`.`product` TO `store_manager`@`%` |
+-----------------------------------------------------------------------------------+
2 rows in set

SHOW GRANTS FOR 'clerk'

+---------------------------------------------------------+
| Grants for clerk@%                                      |
+---------------------------------------------------------+
| GRANT USAGE ON *.* TO `clerk`@`%`                       |
| GRANT SELECT ON `inventory_6a`.`product` TO `clerk`@`%` |
| GRANT INSERT ON `inventory_6a`.`sale` TO `clerk`@`%`    |
+---------------------------------------------------------+
3 rows in set
```

**Why this output is correct:** admin: everything on the database; store_manager: read Product and change only price; clerk: read Product and record sales.

### Task 9 - Users mgr1 and clerk1 with their roles (SET DEFAULT ROLE)

```sql
CREATE USER 'mgr1'@'localhost'   IDENTIFIED BY 'Mgr@12345';
CREATE USER 'clerk1'@'localhost' IDENTIFIED BY 'Clerk@12345';
GRANT 'store_manager' TO 'mgr1'@'localhost';
GRANT 'clerk' TO 'clerk1'@'localhost';
SET DEFAULT ROLE 'store_manager' TO 'mgr1'@'localhost';
SET DEFAULT ROLE 'clerk' TO 'clerk1'@'localhost';
SELECT user, host, default_role_user FROM mysql.default_roles WHERE user IN ('mgr1', 'clerk1');
```

**Output**

```text
CREATE USER 'mgr1'@'localhost'   IDENTIFIED BY 'Mgr@12345'

Query OK, 0 rows affected

CREATE USER 'clerk1'@'localhost' IDENTIFIED BY 'Clerk@12345'

Query OK, 0 rows affected

GRANT 'store_manager' TO 'mgr1'@'localhost'

Query OK, 0 rows affected

GRANT 'clerk' TO 'clerk1'@'localhost'

Query OK, 0 rows affected

SET DEFAULT ROLE 'store_manager' TO 'mgr1'@'localhost'

Query OK, 0 rows affected

SET DEFAULT ROLE 'clerk' TO 'clerk1'@'localhost'

Query OK, 0 rows affected

SELECT user, host, default_role_user FROM mysql.default_roles WHERE user IN ('mgr1', 'clerk1')

+--------+-----------+-------------------+
| user   | host      | default_role_user |
+--------+-----------+-------------------+
| clerk1 | localhost | clerk             |
| mgr1   | localhost | store_manager     |
+--------+-----------+-------------------+
2 rows in set
```

### Task 10 - clerk1 tries UPDATE Product SET price = 800 (denied); mgr1 does it (allowed)

```sql
-- @as clerk1 Clerk@12345
-- | UPDATE Product SET price = 800;
-- | SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1';
-- @as mgr1 Mgr@12345
-- | UPDATE Product SET price = 800 WHERE prod_id = 'P1';
-- | SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1';
-- | UPDATE Product SET qty_in_stock = 999 WHERE prod_id = 'P1';
UPDATE Product SET price = 700 WHERE prod_id = 'P1';
```

**Output**

```text
[session: user 'clerk1']
UPDATE Product SET price = 800

ERROR 1142 (42000) at line 1: UPDATE command denied to user 'clerk1'@'localhost' for table 'product'
SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1'

+---------+----------+--------+
| prod_id | pname    | price  |
+---------+----------+--------+
| P1      | Keyboard | 700.00 |
+---------+----------+--------+
1 row in set

[session: user 'mgr1']
UPDATE Product SET price = 800 WHERE prod_id = 'P1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1'

+---------+----------+--------+
| prod_id | pname    | price  |
+---------+----------+--------+
| P1      | Keyboard | 800.00 |
+---------+----------+--------+
1 row in set

UPDATE Product SET qty_in_stock = 999 WHERE prod_id = 'P1'

ERROR 1143 (42000) at line 3: UPDATE command denied to user 'mgr1'@'localhost' for column 'qty_in_stock' in table 'product'

UPDATE Product SET price = 700 WHERE prod_id = 'P1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0
```

**Why this output is correct:** The clerk has no UPDATE privilege on Product at all: ERROR 1142. The manager holds UPDATE(price): allowed. As a safety measure the manager's statement is limited to one product (the PDF statement without WHERE would reprice everything); root then restores the price.

### Task 11 - SHOW GRANTS for each user

```sql
SHOW GRANTS FOR 'mgr1'@'localhost' USING 'store_manager';
SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk';
```

**Output**

```text
SHOW GRANTS FOR 'mgr1'@'localhost' USING 'store_manager'

+----------------------------------------------------------------------------------+
| Grants for mgr1@localhost                                                        |
+----------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `mgr1`@`localhost`                                         |
| GRANT SELECT, UPDATE (`price`) ON `inventory_6a`.`product` TO `mgr1`@`localhost` |
| GRANT `store_manager`@`%` TO `mgr1`@`localhost`                                  |
+----------------------------------------------------------------------------------+
3 rows in set

SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk'

+------------------------------------------------------------------+
| Grants for clerk1@localhost                                      |
+------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `clerk1`@`localhost`                       |
| GRANT SELECT ON `inventory_6a`.`product` TO `clerk1`@`localhost` |
| GRANT INSERT ON `inventory_6a`.`sale` TO `clerk1`@`localhost`    |
| GRANT `clerk`@`%` TO `clerk1`@`localhost`                        |
+------------------------------------------------------------------+
4 rows in set
```

### Task 12 - REVOKE INSERT on Sale from clerk; clerk1 can no longer record a sale

```sql
-- @as clerk1 Clerk@12345
-- | INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3);
-- | SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4';
REVOKE INSERT ON inventory_6a.Sale FROM 'clerk';
SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk';
-- @as clerk1 Clerk@12345
-- | INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3);
-- | SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4';
```

**Output**

```text
[session: user 'clerk1']
INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3)

Query OK, 1 row affected

SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4'

+---------+--------------+
| prod_id | qty_in_stock |
+---------+--------------+
| P4      |          147 |
+---------+--------------+
1 row in set

REVOKE INSERT ON inventory_6a.Sale FROM 'clerk'

Query OK, 0 rows affected

SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk'

+------------------------------------------------------------------+
| Grants for clerk1@localhost                                      |
+------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `clerk1`@`localhost`                       |
| GRANT SELECT ON `inventory_6a`.`product` TO `clerk1`@`localhost` |
| GRANT `clerk`@`%` TO `clerk1`@`localhost`                        |
+------------------------------------------------------------------+
3 rows in set

[session: user 'clerk1']
INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3)

ERROR 1142 (42000) at line 1: INSERT command denied to user 'clerk1'@'localhost' for table 'sale'
SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4'

+---------+--------------+
| prod_id | qty_in_stock |
+---------+--------------+
| P4      |          147 |
+---------+--------------+
1 row in set
```

**Why this output is correct:** Before the revoke clerk1 records a sale (stock of P4 drops 150 -> 147 although the clerk has no UPDATE right: the trigger runs as its definer). The privilege is removed from the ROLE, so every clerk loses it at once. The next INSERT by clerk1 is denied (ERROR 1142) while SELECT on Product still works.


## Advanced / examiner-style queries

### Adv 1 - Stock level equals purchases minus sales plus opening stock (reconciliation)

```sql
SELECT p.prod_id, p.qty_in_stock,
       (CASE p.prod_id WHEN 'P1' THEN 40 WHEN 'P2' THEN 8 WHEN 'P3' THEN 6 WHEN 'P4' THEN 150 WHEN 'P5' THEN 12 END)
       + COALESCE((SELECT SUM(qty) FROM Purchase x WHERE x.prod_id = p.prod_id), 0)
       - COALESCE((SELECT SUM(qty) FROM Sale x WHERE x.prod_id = p.prod_id), 0) AS recomputed
FROM Product p;
```

**Output**

```text
SELECT p.prod_id, p.qty_in_stock,
       (CASE p.prod_id WHEN 'P1' THEN 40 WHEN 'P2' THEN 8 WHEN 'P3' THEN 6 WHEN 'P4' THEN 150 WHEN 'P5' THEN 12 END)
       + COALESCE((SELECT SUM(qty) FROM Purchase x WHERE x.prod_id = p.prod_id), 0)
       - COALESCE((SELECT SUM(qty) FROM Sale x WHERE x.prod_id = p.prod_id), 0) AS recomputed
FROM Product p

+---------+--------------+------------+
| prod_id | qty_in_stock | recomputed |
+---------+--------------+------------+
| P1      |           35 |         35 |
| P2      |            8 |          8 |
| P3      |           56 |         56 |
| P4      |          147 |        147 |
| P5      |           12 |         12 |
+---------+--------------+------------+
5 rows in set
```

**Why this output is correct:** Opening values (from the PDF) + all purchases - all sales must equal qty_in_stock for every product.

### Adv 2 - Selling exactly the whole stock is allowed, one more is not

```sql
START TRANSACTION;
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 8, 'root');
SELECT qty_in_stock FROM Product WHERE prod_id = 'P2';
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 1, 'root');
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 8, 'root')

Query OK, 1 row affected

SELECT qty_in_stock FROM Product WHERE prod_id = 'P2'

+--------------+
| qty_in_stock |
+--------------+
|            0 |
+--------------+
1 row in set

INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P2', 1, 'root')

ERROR 1644 (45000) at line 4: Insufficient stock for this sale
ROLLBACK

Query OK, 0 rows affected
```

### Adv 3 - Zero or negative sale quantity

```sql
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P4', 0, 'root');
```

**Output**

```text
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P4', 0, 'root')

ERROR 3819 (HY000) at line 1: Check constraint 'chk_sale_qty' is violated.
```

**Why this output is correct:** Error 3819 (chk_sale_qty).

### Adv 4 - Reorder suggestion: how many units to order to reach 2 x reorder level

```sql
SELECT prod_id, pname, qty_in_stock, reorder_level, GREATEST(2 * reorder_level - qty_in_stock, 0) AS suggested_order_qty FROM Product ORDER BY suggested_order_qty DESC;
```

**Output**

```text
SELECT prod_id, pname, qty_in_stock, reorder_level, GREATEST(2 * reorder_level - qty_in_stock, 0) AS suggested_order_qty FROM Product ORDER BY suggested_order_qty DESC

+---------+-----------+--------------+---------------+---------------------+
| prod_id | pname     | qty_in_stock | reorder_level | suggested_order_qty |
+---------+-----------+--------------+---------------+---------------------+
| P5      | USB Drive |           12 |            15 |                  18 |
| P2      | Monitor   |            8 |             5 |                   2 |
| P1      | Keyboard  |           35 |            10 |                   0 |
| P3      | A4 Paper  |           56 |            20 |                   0 |
| P4      | Marker    |          147 |            50 |                   0 |
+---------+-----------+--------------+---------------+---------------------+
5 rows in set
```

### Adv 5 - Sales per user

```sql
SELECT sold_by, COUNT(*) AS sales, SUM(qty) AS units FROM Sale GROUP BY sold_by;
```

**Output**

```text
SELECT sold_by, COUNT(*) AS sales, SUM(qty) AS units FROM Sale GROUP BY sold_by

+---------+-------+-------+
| sold_by | sales | units |
+---------+-------+-------+
| root    |     1 |     5 |
| clerk1  |     1 |     3 |
+---------+-------+-------+
2 rows in set
```

### Adv 6 - Unknown product in a purchase

```sql
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P9', 'S1', 5);
```

**Output**

```text
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P9', 'S1', 5)

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`inventory_6a`.`purchase`, CONSTRAINT `fk_purchase_product` FOREIGN KEY (`prod_id`) REFERENCES `product` (`prod_id`))
```

**Why this output is correct:** Error 1452 (fk_purchase_product).

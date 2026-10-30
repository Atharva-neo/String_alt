# Expected output - Experiment_06_Inventory_Authentication / 6C_Multi_Warehouse

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Create Warehouse and Wh_Stock (composite PK wh_id, prod_id) and insert the data

```sql
CREATE TABLE Warehouse (
    wh_id VARCHAR(5)  NOT NULL PRIMARY KEY,
    city  VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Wh_Stock (
    wh_id   VARCHAR(5) NOT NULL,
    prod_id VARCHAR(5) NOT NULL,
    qty     INT        NOT NULL,
    PRIMARY KEY (wh_id, prod_id),
    CONSTRAINT fk_whs_wh   FOREIGN KEY (wh_id)   REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_whs_prod FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_whs_qty CHECK (qty >= 0)
) ENGINE=InnoDB;
INSERT INTO Warehouse VALUES ('W1', 'Sangli'), ('W2', 'Pune');
INSERT INTO Wh_Stock VALUES ('W1','P1',25), ('W1','P2',5), ('W2','P1',15), ('W2','P3',6);
SELECT * FROM Warehouse; SELECT * FROM Wh_Stock;
```

**Output**

```text
CREATE TABLE Warehouse (
    wh_id VARCHAR(5)  NOT NULL PRIMARY KEY,
    city  VARCHAR(30) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Wh_Stock (
    wh_id   VARCHAR(5) NOT NULL,
    prod_id VARCHAR(5) NOT NULL,
    qty     INT        NOT NULL,
    PRIMARY KEY (wh_id, prod_id),
    CONSTRAINT fk_whs_wh   FOREIGN KEY (wh_id)   REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_whs_prod FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_whs_qty CHECK (qty >= 0)
) ENGINE=InnoDB

Query OK, 0 rows affected

INSERT INTO Warehouse VALUES ('W1', 'Sangli'), ('W2', 'Pune')

Query OK, 2 rows affected
Records: 2  Duplicates: 0  Warnings: 0

INSERT INTO Wh_Stock VALUES ('W1','P1',25), ('W1','P2',5), ('W2','P1',15), ('W2','P3',6)

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT * FROM Warehouse

+-------+--------+
| wh_id | city   |
+-------+--------+
| W1    | Sangli |
| W2    | Pune   |
+-------+--------+
2 rows in set

SELECT * FROM Wh_Stock

+-------+---------+-----+
| wh_id | prod_id | qty |
+-------+---------+-----+
| W1    | P1      |  25 |
| W1    | P2      |   5 |
| W2    | P1      |  15 |
| W2    | P3      |   6 |
+-------+---------+-----+
4 rows in set
```

### Task 2 - Stock of each product in each warehouse with the product name

```sql
SELECT w.wh_id, w.city, p.prod_id, p.pname, w.qty FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id ORDER BY w.wh_id, p.prod_id;
```

**Output**

```text
SELECT w.wh_id, w.city, p.prod_id, p.pname, w.qty FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id ORDER BY w.wh_id, p.prod_id

ERROR 1054 (42S22) at line 1: Unknown column 'w.city' in 'field list'
```

### Task 3 - Total stock per product across all warehouses

```sql
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id GROUP BY p.prod_id, p.pname ORDER BY p.prod_id;
```

**Output**

```text
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id GROUP BY p.prod_id, p.pname ORDER BY p.prod_id

+---------+-----------+-------------+
| prod_id | pname     | total_stock |
+---------+-----------+-------------+
| P1      | Keyboard  |          40 |
| P2      | Monitor   |           5 |
| P3      | A4 Paper  |           6 |
| P4      | Marker    |           0 |
| P5      | USB Drive |           0 |
+---------+-----------+-------------+
5 rows in set
```

**Why this output is correct:** LEFT JOIN keeps products that exist in no warehouse (P4, P5) with total 0.

### Task 4 - Procedure transfer_stock(from_wh, to_wh, prod, qty) as one transaction with rollback on shortage

```sql
CREATE TABLE Stock_Transfer (
    transfer_id INT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    from_wh     VARCHAR(5) NOT NULL,
    to_wh       VARCHAR(5) NOT NULL,
    prod_id     VARCHAR(5) NOT NULL,
    qty         INT        NOT NULL,
    CONSTRAINT fk_st_from FOREIGN KEY (from_wh) REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_st_to   FOREIGN KEY (to_wh)   REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_st_prod FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_st_qty CHECK (qty > 0)
) ENGINE=InnoDB;
DELIMITER $$
CREATE PROCEDURE transfer_stock(IN p_from VARCHAR(5), IN p_to VARCHAR(5), IN p_prod VARCHAR(5), IN p_qty INT)
BEGIN
    DECLARE v_have INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF p_from = p_to OR p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid transfer request';
    END IF;
    START TRANSACTION;
    SELECT qty INTO v_have FROM Wh_Stock WHERE wh_id = p_from AND prod_id = p_prod FOR UPDATE;
    IF v_have IS NULL OR v_have < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shortage: source warehouse does not hold enough stock';
    END IF;
    UPDATE Wh_Stock SET qty = qty - p_qty WHERE wh_id = p_from AND prod_id = p_prod;
    INSERT INTO Wh_Stock (wh_id, prod_id, qty) VALUES (p_to, p_prod, p_qty)
        ON DUPLICATE KEY UPDATE qty = qty + p_qty;
    INSERT INTO Stock_Transfer (from_wh, to_wh, prod_id, qty) VALUES (p_from, p_to, p_prod, p_qty);
    COMMIT;
END$$
DELIMITER ;
SHOW PROCEDURE STATUS WHERE Db = 'warehouse_6c';
```

**Output**

```text
CREATE TABLE Stock_Transfer (
    transfer_id INT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    from_wh     VARCHAR(5) NOT NULL,
    to_wh       VARCHAR(5) NOT NULL,
    prod_id     VARCHAR(5) NOT NULL,
    qty         INT        NOT NULL,
    CONSTRAINT fk_st_from FOREIGN KEY (from_wh) REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_st_to   FOREIGN KEY (to_wh)   REFERENCES Warehouse(wh_id),
    CONSTRAINT fk_st_prod FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_st_qty CHECK (qty > 0)
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE PROCEDURE transfer_stock(IN p_from VARCHAR(5), IN p_to VARCHAR(5), IN p_prod VARCHAR(5), IN p_qty INT)
BEGIN
    DECLARE v_have INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF p_from = p_to OR p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid transfer request';
    END IF;
    START TRANSACTION;
    SELECT qty INTO v_have FROM Wh_Stock WHERE wh_id = p_from AND prod_id = p_prod FOR UPDATE;
    IF v_have IS NULL OR v_have < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shortage: source warehouse does not hold enough stock';
    END IF;
    UPDATE Wh_Stock SET qty = qty - p_qty WHERE wh_id = p_from AND prod_id = p_prod;
    INSERT INTO Wh_Stock (wh_id, prod_id, qty) VALUES (p_to, p_prod, p_qty)
        ON DUPLICATE KEY UPDATE qty = qty + p_qty;
    INSERT INTO Stock_Transfer (from_wh, to_wh, prod_id, qty) VALUES (p_from, p_to, p_prod, p_qty);
    COMMIT;
END

Query OK, 0 rows affected

SHOW PROCEDURE STATUS WHERE Db = 'warehouse_6c'

+--------------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| Db           | Name           | Type      | Definer        | Modified            | Created             | Security_type | Comment | character_set_client | collation_connection | Database Collation |
+--------------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
| warehouse_6c | transfer_stock | PROCEDURE | root@localhost | 2026-10-30 10:43:19 | 2026-10-30 10:43:19 | DEFINER       |         | utf8mb4              | utf8mb4_0900_ai_ci   | utf8mb4_0900_ai_ci |
+--------------+----------------+-----------+----------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
1 row in set
```

**Why this output is correct:** (Stock_Transfer is the voucher table used in Task 6; it is created here because the procedure writes to it.) FOR UPDATE locks the source row. Shortage / missing source row / invalid request => SIGNAL => EXIT HANDLER does ROLLBACK + RESIGNAL. The destination row is created if the warehouse never stocked the product (ON DUPLICATE KEY UPDATE adds to the existing quantity).

### Task 5 - Transfer 10 keyboards W1 -> W2, then try 10 monitors and show the rollback

```sql
CALL transfer_stock('W1', 'W2', 'P1', 10);
SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id;
CALL transfer_stock('W1', 'W2', 'P2', 10);
SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id;
SELECT COUNT(*) AS vouchers FROM Stock_Transfer;
```

**Output**

```text
CALL transfer_stock('W1', 'W2', 'P1', 10)

Query OK, 0 rows affected

SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id

+-------+---------+-----+
| wh_id | prod_id | qty |
+-------+---------+-----+
| W1    | P1      |  15 |
| W1    | P2      |   5 |
| W2    | P1      |  25 |
| W2    | P3      |   6 |
+-------+---------+-----+
4 rows in set

CALL transfer_stock('W1', 'W2', 'P2', 10)

ERROR 1644 (45000) at line 3: Shortage: source warehouse does not hold enough stock
SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id

+-------+---------+-----+
| wh_id | prod_id | qty |
+-------+---------+-----+
| W1    | P1      |  15 |
| W1    | P2      |   5 |
| W2    | P1      |  25 |
| W2    | P3      |   6 |
+-------+---------+-----+
4 rows in set

SELECT COUNT(*) AS vouchers FROM Stock_Transfer

+----------+
| vouchers |
+----------+
|        1 |
+----------+
1 row in set
```

**Why this output is correct:** Keyboards: W1 25 -> 15, W2 15 -> 25. Monitors: W1 holds only 5, so the procedure raises 'Shortage' and the handler rolls everything back.

### Task 6 - Trigger that logs every transfer in Transfer_Log

```sql
CREATE TABLE Transfer_Log (
    log_id    INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    from_wh   VARCHAR(5)  NOT NULL,
    to_wh     VARCHAR(5)  NOT NULL,
    prod_id   VARCHAR(5)  NOT NULL,
    qty       INT         NOT NULL,
    logged_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logged_by VARCHAR(80) NOT NULL DEFAULT (USER())      -- USER() = the account that connected (CURRENT_USER() inside a trigger would be the definer)
) ENGINE=InnoDB;
DELIMITER $$
CREATE TRIGGER trg_transfer_log AFTER INSERT ON Stock_Transfer FOR EACH ROW
BEGIN
    INSERT INTO Transfer_Log (from_wh, to_wh, prod_id, qty) VALUES (NEW.from_wh, NEW.to_wh, NEW.prod_id, NEW.qty);
END$$
DELIMITER ;
INSERT INTO Transfer_Log (from_wh, to_wh, prod_id, qty) SELECT from_wh, to_wh, prod_id, qty FROM Stock_Transfer;
CALL transfer_stock('W2', 'W1', 'P1', 2);
CALL transfer_stock('W2', 'W1', 'P2', 99);
SELECT log_id, from_wh, to_wh, prod_id, qty, logged_by FROM Transfer_Log;
SELECT transfer_id, from_wh, to_wh, prod_id, qty FROM Stock_Transfer;
```

**Output**

```text
CREATE TABLE Transfer_Log (
    log_id    INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    from_wh   VARCHAR(5)  NOT NULL,
    to_wh     VARCHAR(5)  NOT NULL,
    prod_id   VARCHAR(5)  NOT NULL,
    qty       INT         NOT NULL,
    logged_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logged_by VARCHAR(80) NOT NULL DEFAULT (USER())
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TRIGGER trg_transfer_log AFTER INSERT ON Stock_Transfer FOR EACH ROW
BEGIN
    INSERT INTO Transfer_Log (from_wh, to_wh, prod_id, qty) VALUES (NEW.from_wh, NEW.to_wh, NEW.prod_id, NEW.qty);
END

Query OK, 0 rows affected

INSERT INTO Transfer_Log (from_wh, to_wh, prod_id, qty) SELECT from_wh, to_wh, prod_id, qty FROM Stock_Transfer

Query OK, 1 row affected
Records: 1  Duplicates: 0  Warnings: 0

CALL transfer_stock('W2', 'W1', 'P1', 2)

Query OK, 0 rows affected

CALL transfer_stock('W2', 'W1', 'P2', 99)

ERROR 1644 (45000) at line 18: Shortage: source warehouse does not hold enough stock
SELECT log_id, from_wh, to_wh, prod_id, qty, logged_by FROM Transfer_Log

+--------+---------+-------+---------+-----+----------------+
| log_id | from_wh | to_wh | prod_id | qty | logged_by      |
+--------+---------+-------+---------+-----+----------------+
|      1 | W1      | W2    | P1      |  10 | root@localhost |
|      2 | W2      | W1    | P1      |   2 | root@localhost |
+--------+---------+-------+---------+-----+----------------+
2 rows in set

SELECT transfer_id, from_wh, to_wh, prod_id, qty FROM Stock_Transfer

+-------------+---------+-------+---------+-----+
| transfer_id | from_wh | to_wh | prod_id | qty |
+-------------+---------+-------+---------+-----+
|           1 | W1      | W2    | P1      |  10 |
|           2 | W2      | W1    | P1      |   2 |
+-------------+---------+-------+---------+-----+
2 rows in set
```

**Why this output is correct:** AFTER INSERT on the voucher table copies the transfer with the user and time. It is created now, so the earlier Task 5 transfer is back-filled once, then new transfers are logged automatically (the test transfer is W2 -> W1 of 2 keyboards).

### Task 7 - Warehouse-wise stock value (qty x price)

```sql
SELECT w.wh_id, wh.city, SUM(w.qty * p.price) AS stock_value, SUM(w.qty) AS units
FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id JOIN Warehouse wh ON wh.wh_id = w.wh_id GROUP BY w.wh_id, wh.city;
```

**Output**

```text
SELECT w.wh_id, wh.city, SUM(w.qty * p.price) AS stock_value, SUM(w.qty) AS units
FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id JOIN Warehouse wh ON wh.wh_id = w.wh_id GROUP BY w.wh_id, wh.city

+-------+--------+-------------+-------+
| wh_id | city   | stock_value | units |
+-------+--------+-------------+-------+
| W1    | Sangli |    56900.00 |    22 |
| W2    | Pune   |    17600.00 |    29 |
+-------+--------+-------------+-------+
2 rows in set
```

### Task 8 - View reorder_list: total stock across warehouses <= reorder_level, with supplier name and phone

```sql
CREATE VIEW reorder_list AS
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock, p.reorder_level, s.sname AS supplier, s.phone AS supplier_phone
FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id JOIN Supplier s ON s.supplier_id = p.supplier_id
GROUP BY p.prod_id, p.pname, p.reorder_level, s.sname, s.phone
HAVING COALESCE(SUM(w.qty), 0) <= p.reorder_level;
SELECT * FROM reorder_list ORDER BY prod_id;
```

**Output**

```text
CREATE VIEW reorder_list AS
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock, p.reorder_level, s.sname AS supplier, s.phone AS supplier_phone
FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id JOIN Supplier s ON s.supplier_id = p.supplier_id
GROUP BY p.prod_id, p.pname, p.reorder_level, s.sname, s.phone
HAVING COALESCE(SUM(w.qty), 0) <= p.reorder_level

Query OK, 0 rows affected

SELECT * FROM reorder_list ORDER BY prod_id

+---------+-----------+-------------+---------------+-----------------+----------------+
| prod_id | pname     | total_stock | reorder_level | supplier        | supplier_phone |
+---------+-----------+-------------+---------------+-----------------+----------------+
| P2      | Monitor   |           5 |             5 | Global Supplies | 9850033333     |
| P3      | A4 Paper  |           6 |            20 | Shree Agencies  | 9850022222     |
| P4      | Marker    |           0 |            50 | Shree Agencies  | 9850022222     |
| P5      | USB Drive |           0 |            15 | Om Distributors | 9850011111     |
+---------+-----------+-------------+---------------+-----------------+----------------+
4 rows in set
```

**Why this output is correct:** Totals (after the transfers): P1 40 (reorder 10) OK; P2 5 <= 5, P3 6 <= 20, P4 0 <= 50, P5 0 <= 15 => these four must be re-ordered.

### Task 9 - User purchase_officer: GRANT SELECT on the view only

```sql
DROP USER IF EXISTS 'purchase_officer'@'localhost';
CREATE USER 'purchase_officer'@'localhost' IDENTIFIED BY 'Officer@12345';
GRANT SELECT ON warehouse_6c.reorder_list TO 'purchase_officer'@'localhost';
SHOW GRANTS FOR 'purchase_officer'@'localhost';
```

**Output**

```text
DROP USER IF EXISTS 'purchase_officer'@'localhost'

Query OK, 0 rows affected

CREATE USER 'purchase_officer'@'localhost' IDENTIFIED BY 'Officer@12345'

Query OK, 0 rows affected

GRANT SELECT ON warehouse_6c.reorder_list TO 'purchase_officer'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'purchase_officer'@'localhost'

+---------------------------------------------------------------------------------+
| Grants for purchase_officer@localhost                                           |
+---------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `purchase_officer`@`localhost`                            |
| GRANT SELECT ON `warehouse_6c`.`reorder_list` TO `purchase_officer`@`localhost` |
+---------------------------------------------------------------------------------+
2 rows in set
```

### Task 10 - SELECT on Product fails for purchase_officer while the view works

```sql
-- @as purchase_officer Officer@12345
-- | SELECT prod_id, pname, total_stock, supplier, supplier_phone FROM reorder_list ORDER BY prod_id;
-- | SELECT * FROM Product;
-- | SELECT * FROM Wh_Stock;
```

**Output**

```text
[session: user 'purchase_officer']
SELECT prod_id, pname, total_stock, supplier, supplier_phone FROM reorder_list ORDER BY prod_id

+---------+-----------+-------------+-----------------+----------------+
| prod_id | pname     | total_stock | supplier        | supplier_phone |
+---------+-----------+-------------+-----------------+----------------+
| P2      | Monitor   |           5 | Global Supplies | 9850033333     |
| P3      | A4 Paper  |           6 | Shree Agencies  | 9850022222     |
| P4      | Marker    |           0 | Shree Agencies  | 9850022222     |
| P5      | USB Drive |           0 | Om Distributors | 9850011111     |
+---------+-----------+-------------+-----------------+----------------+
4 rows in set

SELECT * FROM Product

ERROR 1142 (42000) at line 2: SELECT command denied to user 'purchase_officer'@'localhost' for table 'product'
SELECT * FROM Wh_Stock

ERROR 1142 (42000) at line 3: SELECT command denied to user 'purchase_officer'@'localhost' for table 'wh_stock'
```

**Why this output is correct:** The view runs with the definer's rights, the officer has no right on the base tables: ERROR 1142 on Product / Supplier / Wh_Stock.

### Task 11 - User wh_manager with UPDATE on Wh_Stock and EXECUTE on transfer_stock

```sql
DROP USER IF EXISTS 'wh_manager'@'localhost';
CREATE USER 'wh_manager'@'localhost' IDENTIFIED BY 'WhMgr@12345';
GRANT UPDATE ON warehouse_6c.Wh_Stock TO 'wh_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE warehouse_6c.transfer_stock TO 'wh_manager'@'localhost';
SHOW GRANTS FOR 'wh_manager'@'localhost';
-- @as wh_manager WhMgr@12345
-- | CALL transfer_stock('W1', 'W2', 'P1', 5);
-- | SELECT * FROM Wh_Stock;
-- | INSERT INTO Stock_Transfer (from_wh, to_wh, prod_id, qty) VALUES ('W1','W2','P1',1);
SELECT log_id, from_wh, to_wh, prod_id, qty, logged_by FROM Transfer_Log ORDER BY log_id;
```

**Output**

```text
DROP USER IF EXISTS 'wh_manager'@'localhost'

Query OK, 0 rows affected

CREATE USER 'wh_manager'@'localhost' IDENTIFIED BY 'WhMgr@12345'

Query OK, 0 rows affected

GRANT UPDATE ON warehouse_6c.Wh_Stock TO 'wh_manager'@'localhost'

Query OK, 0 rows affected

GRANT EXECUTE ON PROCEDURE warehouse_6c.transfer_stock TO 'wh_manager'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'wh_manager'@'localhost'

+----------------------------------------------------------------------------------------+
| Grants for wh_manager@localhost                                                        |
+----------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `wh_manager`@`localhost`                                         |
| GRANT UPDATE ON `warehouse_6c`.`wh_stock` TO `wh_manager`@`localhost`                  |
| GRANT EXECUTE ON PROCEDURE `warehouse_6c`.`transfer_stock` TO `wh_manager`@`localhost` |
+----------------------------------------------------------------------------------------+
3 rows in set

[session: user 'wh_manager']
CALL transfer_stock('W1', 'W2', 'P1', 5)

Query OK, 0 rows affected

SELECT * FROM Wh_Stock

ERROR 1142 (42000) at line 2: SELECT command denied to user 'wh_manager'@'localhost' for table 'wh_stock'
INSERT INTO Stock_Transfer (from_wh, to_wh, prod_id, qty) VALUES ('W1','W2','P1',1)

ERROR 1142 (42000) at line 3: INSERT command denied to user 'wh_manager'@'localhost' for table 'stock_transfer'

SELECT log_id, from_wh, to_wh, prod_id, qty, logged_by FROM Transfer_Log ORDER BY log_id

+--------+---------+-------+---------+-----+----------------------+
| log_id | from_wh | to_wh | prod_id | qty | logged_by            |
+--------+---------+-------+---------+-----+----------------------+
|      1 | W1      | W2    | P1      |  10 | root@localhost       |
|      2 | W2      | W1    | P1      |   2 | root@localhost       |
|      3 | W1      | W2    | P1      |   5 | wh_manager@localhost |
+--------+---------+-------+---------+-----+----------------------+
3 rows in set
```

**Why this output is correct:** EXECUTE lets wh_manager run the procedure (which writes the voucher and log with the definer's rights). UPDATE on Wh_Stock is a direct right; INSERT/SELECT are not granted.

### Task 12 - REVOKE EXECUTE and show the procedure call fails

```sql
REVOKE EXECUTE ON PROCEDURE warehouse_6c.transfer_stock FROM 'wh_manager'@'localhost';
SHOW GRANTS FOR 'wh_manager'@'localhost';
-- @as wh_manager WhMgr@12345
-- | CALL transfer_stock('W1', 'W2', 'P1', 5);
```

**Output**

```text
REVOKE EXECUTE ON PROCEDURE warehouse_6c.transfer_stock FROM 'wh_manager'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'wh_manager'@'localhost'

+-----------------------------------------------------------------------+
| Grants for wh_manager@localhost                                       |
+-----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `wh_manager`@`localhost`                        |
| GRANT UPDATE ON `warehouse_6c`.`wh_stock` TO `wh_manager`@`localhost` |
+-----------------------------------------------------------------------+
2 rows in set

[session: user 'wh_manager']
CALL transfer_stock('W1', 'W2', 'P1', 5)

ERROR 1370 (42000) at line 1: execute command denied to user 'wh_manager'@'localhost' for routine 'warehouse_6c.transfer_stock'
```

**Why this output is correct:** After the revoke ERROR 1370 (42000): execute command denied to user 'wh_manager'@'localhost' for routine 'warehouse_6c.transfer_stock'.


## Advanced / examiner-style queries

### Adv 1 - Conservation check - total stock of a product never changes by a transfer

```sql
SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id;
CALL transfer_stock('W1', 'W2', 'P1', 3);
SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id;
```

**Output**

```text
SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id

+---------+-------+
| prod_id | total |
+---------+-------+
| P1      |    40 |
+---------+-------+
1 row in set

CALL transfer_stock('W1', 'W2', 'P1', 3)

Query OK, 0 rows affected

SELECT prod_id, SUM(qty) AS total FROM Wh_Stock WHERE prod_id = 'P1' GROUP BY prod_id

+---------+-------+
| prod_id | total |
+---------+-------+
| P1      |    40 |
+---------+-------+
1 row in set
```

### Adv 2 - Transfer to a warehouse that never stocked the product creates its row

```sql
CALL transfer_stock('W1', 'W2', 'P2', 2);
SELECT * FROM Wh_Stock WHERE prod_id = 'P2';
```

**Output**

```text
CALL transfer_stock('W1', 'W2', 'P2', 2)

Query OK, 0 rows affected

SELECT * FROM Wh_Stock WHERE prod_id = 'P2'

+-------+---------+-----+
| wh_id | prod_id | qty |
+-------+---------+-----+
| W1    | P2      |   3 |
| W2    | P2      |   2 |
+-------+---------+-----+
2 rows in set
```

**Why this output is correct:** W2 never held P2 before; after moving 2 monitors W1 -> W2 a new row (W2, P2, 2) appears.

### Adv 3 - Transfer to an unknown warehouse

```sql
SELECT qty AS w1_p1_before FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1';
CALL transfer_stock('W1', 'W9', 'P1', 1);
SELECT qty AS w1_p1_after FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1';
```

**Output**

```text
SELECT qty AS w1_p1_before FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1'

+--------------+
| w1_p1_before |
+--------------+
|            9 |
+--------------+
1 row in set

CALL transfer_stock('W1', 'W9', 'P1', 1)

ERROR 1452 (23000) at line 2: Cannot add or update a child row: a foreign key constraint fails (`warehouse_6c`.`wh_stock`, CONSTRAINT `fk_whs_wh` FOREIGN KEY (`wh_id`) REFERENCES `warehouse` (`wh_id`))
SELECT qty AS w1_p1_after FROM Wh_Stock WHERE wh_id = 'W1' AND prod_id = 'P1'

+-------------+
| w1_p1_after |
+-------------+
|           9 |
+-------------+
1 row in set
```

**Why this output is correct:** The FK on Wh_Stock rejects the destination row, the handler rolls everything back (the source decrement too).

### Adv 4 - Which warehouse should supply a reorder? (largest stock of the product)

```sql
SELECT w.prod_id, w.wh_id, w.qty FROM Wh_Stock w WHERE w.qty = (SELECT MAX(x.qty) FROM Wh_Stock x WHERE x.prod_id = w.prod_id) ORDER BY w.prod_id;
```

**Output**

```text
SELECT w.prod_id, w.wh_id, w.qty FROM Wh_Stock w WHERE w.qty = (SELECT MAX(x.qty) FROM Wh_Stock x WHERE x.prod_id = w.prod_id) ORDER BY w.prod_id

+---------+-------+-----+
| prod_id | wh_id | qty |
+---------+-------+-----+
| P1      | W2    |  31 |
| P2      | W1    |   3 |
| P3      | W2    |   6 |
+---------+-------+-----+
3 rows in set
```

### Adv 5 - Transfer history per product

```sql
SELECT prod_id, COUNT(*) AS transfers, SUM(qty) AS units_moved FROM Transfer_Log GROUP BY prod_id;
```

**Output**

```text
SELECT prod_id, COUNT(*) AS transfers, SUM(qty) AS units_moved FROM Transfer_Log GROUP BY prod_id

+---------+-----------+-------------+
| prod_id | transfers | units_moved |
+---------+-----------+-------------+
| P1      |         4 |          20 |
| P2      |         1 |           2 |
+---------+-----------+-------------+
2 rows in set
```

### Adv 6 - Negative stock via direct update

```sql
UPDATE Wh_Stock SET qty = -1 WHERE wh_id = 'W1' AND prod_id = 'P1';
```

**Output**

```text
UPDATE Wh_Stock SET qty = -1 WHERE wh_id = 'W1' AND prod_id = 'P1'

ERROR 3819 (HY000) at line 1: Check constraint 'chk_whs_qty' is violated.
```

**Why this output is correct:** Error 3819 (chk_whs_qty): even a user holding UPDATE on Wh_Stock cannot make stock negative.

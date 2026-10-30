# Expected output - Experiment_03_Normalization_BCNF / 3B_Order_Details

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Primary key of the given table

```sql
SELECT COUNT(*) AS rows_, COUNT(DISTINCT OrderID, ProductID) AS distinct_pairs, COUNT(DISTINCT OrderID) AS distinct_orders, COUNT(DISTINCT ProductID) AS distinct_products FROM Order_Details;
```

**Output**

```text
SELECT COUNT(*) AS rows_, COUNT(DISTINCT OrderID, ProductID) AS distinct_pairs, COUNT(DISTINCT OrderID) AS distinct_orders, COUNT(DISTINCT ProductID) AS distinct_products FROM Order_Details

+-------+----------------+-----------------+-------------------+
| rows_ | distinct_pairs | distinct_orders | distinct_products |
+-------+----------------+-----------------+-------------------+
|     4 |              4 |               3 |                 3 |
+-------+----------------+-----------------+-------------------+
1 row in set
```

**Why this output is correct:** {OrderID, ProductID}+ contains all attributes and no proper subset does (see fd_analysis.py). Data check: the pair is unique, OrderID alone is not.

### Task 2 - Redundancy (repeated customer and product data)

```sql
SELECT CustID, CustName, CustCity, COUNT(*) AS copies FROM Order_Details GROUP BY CustID, CustName, CustCity;
SELECT ProductID, ProductName, UnitPrice, COUNT(*) AS copies FROM Order_Details GROUP BY ProductID, ProductName, UnitPrice;
```

**Output**

```text
SELECT CustID, CustName, CustCity, COUNT(*) AS copies FROM Order_Details GROUP BY CustID, CustName, CustCity

+--------+----------+----------+--------+
| CustID | CustName | CustCity | copies |
+--------+----------+----------+--------+
| C1     | Sagar    | Sangli   |      3 |
| C2     | Meera    | Pune     |      1 |
+--------+----------+----------+--------+
2 rows in set

SELECT ProductID, ProductName, UnitPrice, COUNT(*) AS copies FROM Order_Details GROUP BY ProductID, ProductName, UnitPrice

+-----------+-------------+-----------+--------+
| ProductID | ProductName | UnitPrice | copies |
+-----------+-------------+-----------+--------+
| P1        | Pen         |        10 |      2 |
| P2        | Notebook    |        60 |      1 |
| P3        | Stapler     |       150 |      1 |
+-----------+-------------+-----------+--------+
3 rows in set
```

**Why this output is correct:** Sagar/Sangli is stored 3 times, Pen/10 twice. Each extra copy is redundant and can become inconsistent.

### Task 3 - One insert, update and delete anomaly

```sql
INSERT INTO Order_Details (CustID, CustName, CustCity) VALUES ('C4', 'Neeta', 'Satara');
START TRANSACTION;
UPDATE Order_Details SET CustCity = 'Miraj' WHERE OrderID = 'O1' AND ProductID = 'P1';
SELECT CustID, CustCity, COUNT(*) AS rows_ FROM Order_Details WHERE CustID = 'C1' GROUP BY CustID, CustCity;
ROLLBACK;
START TRANSACTION;
DELETE FROM Order_Details WHERE OrderID = 'O2';
SELECT * FROM Order_Details WHERE CustID = 'C2';
ROLLBACK;
```

**Output**

```text
INSERT INTO Order_Details (CustID, CustName, CustCity) VALUES ('C4', 'Neeta', 'Satara')

ERROR 1364 (HY000) at line 1: Field 'OrderID' doesn't have a default value
START TRANSACTION

Query OK, 0 rows affected

UPDATE Order_Details SET CustCity = 'Miraj' WHERE OrderID = 'O1' AND ProductID = 'P1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT CustID, CustCity, COUNT(*) AS rows_ FROM Order_Details WHERE CustID = 'C1' GROUP BY CustID, CustCity

+--------+----------+-------+
| CustID | CustCity | rows_ |
+--------+----------+-------+
| C1     | Miraj    |     1 |
| C1     | Sangli   |     2 |
+--------+----------+-------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

DELETE FROM Order_Details WHERE OrderID = 'O2'

Query OK, 1 row affected

SELECT * FROM Order_Details WHERE CustID = 'C2'

Empty set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** INSERT: a new customer C4 or product P9 cannot be stored without an order (OrderID/ProductID are in the PK) -> error 1364/1048. UPDATE: change Sagar's city in one row only -> two different cities for C1. DELETE: deleting order O2 (Meera's only order) also deletes the only record of customer C2 Meera / Pune.

### Task 4 - Classify each FD as full, partial or transitive

```sql
SELECT 'OrderID -> OrderDate, CustID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'CustID -> CustName, CustCity', 'Transitive (via OrderID -> CustID)' UNION ALL
SELECT 'ProductID -> ProductName, UnitPrice', 'Partial' UNION ALL
SELECT '{OrderID, ProductID} -> Qty', 'Full';
```

**Output**

```text
SELECT 'OrderID -> OrderDate, CustID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'CustID -> CustName, CustCity', 'Transitive (via OrderID -> CustID)' UNION ALL
SELECT 'ProductID -> ProductName, UnitPrice', 'Partial' UNION ALL
SELECT '{OrderID, ProductID} -> Qty', 'Full'

+-------------------------------------+------------------------------------+
| fd                                  | kind                               |
+-------------------------------------+------------------------------------+
| OrderID -> OrderDate, CustID        | Partial                            |
| CustID -> CustName, CustCity        | Transitive (via OrderID -> CustID) |
| ProductID -> ProductName, UnitPrice | Partial                            |
| {OrderID, ProductID} -> Qty         | Full                               |
+-------------------------------------+------------------------------------+
4 rows in set
```

**Why this output is correct:** OrderID -> OrderDate, CustID : PARTIAL (OrderID is part of the key).  CustID -> CustName, CustCity : TRANSITIVE (OrderID -> CustID -> CustName). ProductID -> ProductName, UnitPrice : PARTIAL.  {OrderID, ProductID} -> Qty : FULL.

### Task 5 - Closure of {OrderID, ProductID}

```sql
SELECT 'closure({OrderID,ProductID}) = all 9 attributes' AS result;
```

**Output**

```text
SELECT 'closure({OrderID,ProductID}) = all 9 attributes' AS result

+-------------------------------------------------+
| result                                          |
+-------------------------------------------------+
| closure({OrderID,ProductID}) = all 9 attributes |
+-------------------------------------------------+
1 row in set
```

**Why this output is correct:** Start {OrderID, ProductID}; OrderID adds OrderDate, CustID; CustID adds CustName, CustCity; ProductID adds ProductName, UnitPrice; the FD for Qty adds Qty => all 9 attributes, so it is a superkey (and a candidate key because it is minimal). Computed by fd_analysis.py.

### Task 6 - Decompose to 2NF

```sql
CREATE TABLE Order_Header_2NF AS SELECT DISTINCT OrderID, OrderDate, CustID, CustName, CustCity FROM Order_Details;
CREATE TABLE Product_2NF      AS SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details;
CREATE TABLE Order_Item_2NF   AS SELECT OrderID, ProductID, Qty FROM Order_Details;
SELECT * FROM Order_Header_2NF; SELECT * FROM Product_2NF; SELECT * FROM Order_Item_2NF;
```

**Output**

```text
CREATE TABLE Order_Header_2NF AS SELECT DISTINCT OrderID, OrderDate, CustID, CustName, CustCity FROM Order_Details

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Product_2NF      AS SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Order_Item_2NF   AS SELECT OrderID, ProductID, Qty FROM Order_Details

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT * FROM Order_Header_2NF

+---------+------------+--------+----------+----------+
| OrderID | OrderDate  | CustID | CustName | CustCity |
+---------+------------+--------+----------+----------+
| O1      | 2026-10-01 | C1     | Sagar    | Sangli   |
| O2      | 2026-10-03 | C2     | Meera    | Pune     |
| O3      | 2026-10-04 | C1     | Sagar    | Sangli   |
+---------+------------+--------+----------+----------+
3 rows in set

SELECT * FROM Product_2NF

+-----------+-------------+-----------+
| ProductID | ProductName | UnitPrice |
+-----------+-------------+-----------+
| P1        | Pen         |        10 |
| P2        | Notebook    |        60 |
| P3        | Stapler     |       150 |
+-----------+-------------+-----------+
3 rows in set

SELECT * FROM Order_Item_2NF

+---------+-----------+-----+
| OrderID | ProductID | Qty |
+---------+-----------+-----+
| O1      | P1        |  10 |
| O1      | P2        |   5 |
| O2      | P1        |  20 |
| O3      | P3        |   1 |
+---------+-----------+-----+
4 rows in set
```

**Why this output is correct:** Remove partial dependencies: Order_Header(OrderID, OrderDate, CustID, CustName, CustCity), Product(ProductID, ProductName, UnitPrice), Order_Item(OrderID, ProductID, Qty).

### Task 7 - Decompose to 3NF and verify BCNF

```sql
CREATE TABLE Customer_3NF AS SELECT DISTINCT CustID, CustName, CustCity FROM Order_Header_2NF;
CREATE TABLE Orders_3NF   AS SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Header_2NF;
SELECT * FROM Customer_3NF; SELECT * FROM Orders_3NF;
DROP TABLE Order_Header_2NF, Product_2NF, Order_Item_2NF, Customer_3NF, Orders_3NF;
```

**Output**

```text
CREATE TABLE Customer_3NF AS SELECT DISTINCT CustID, CustName, CustCity FROM Order_Header_2NF

Query OK, 2 rows affected
Records: 2  Duplicates: 0  Warnings: 0

CREATE TABLE Orders_3NF   AS SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Header_2NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

SELECT * FROM Customer_3NF

+--------+----------+----------+
| CustID | CustName | CustCity |
+--------+----------+----------+
| C1     | Sagar    | Sangli   |
| C2     | Meera    | Pune     |
+--------+----------+----------+
2 rows in set

SELECT * FROM Orders_3NF

+---------+------------+--------+
| OrderID | OrderDate  | CustID |
+---------+------------+--------+
| O1      | 2026-10-01 | C1     |
| O2      | 2026-10-03 | C2     |
| O3      | 2026-10-04 | C1     |
+---------+------------+--------+
3 rows in set

DROP TABLE Order_Header_2NF, Product_2NF, Order_Item_2NF, Customer_3NF, Orders_3NF

Query OK, 0 rows affected
```

**Why this output is correct:** In Order_Header: OrderID -> CustID -> CustName, CustCity is transitive. Split into Orders(OrderID, OrderDate, CustID) and Customer(CustID, CustName, CustCity). Every determinant is now the key of its table => BCNF.

### Task 8 - Lossless join and dependency preservation

```sql
WITH cust AS (SELECT DISTINCT CustID, CustName, CustCity FROM Order_Details),
     ord  AS (SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Details),
     prod AS (SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details),
     item AS (SELECT OrderID, ProductID, Qty FROM Order_Details),
     rejoined AS (SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
                  FROM item i JOIN ord o USING (OrderID) JOIN cust c USING (CustID) JOIN prod p USING (ProductID))
SELECT (SELECT COUNT(*) FROM rejoined) AS rejoined_rows,
       (SELECT COUNT(*) FROM Order_Details d WHERE NOT EXISTS (SELECT 1 FROM rejoined r WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty AND r.CustName=d.CustName AND r.CustCity=d.CustCity AND r.ProductName=d.ProductName AND r.UnitPrice=d.UnitPrice AND r.OrderDate=d.OrderDate)) AS missing_rows,
       (SELECT COUNT(*) FROM rejoined r WHERE NOT EXISTS (SELECT 1 FROM Order_Details d WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty)) AS spurious_rows;
```

**Output**

```text
WITH cust AS (SELECT DISTINCT CustID, CustName, CustCity FROM Order_Details),
     ord  AS (SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Details),
     prod AS (SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details),
     item AS (SELECT OrderID, ProductID, Qty FROM Order_Details),
     rejoined AS (SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
                  FROM item i JOIN ord o USING (OrderID) JOIN cust c USING (CustID) JOIN prod p USING (ProductID))
SELECT (SELECT COUNT(*) FROM rejoined) AS rejoined_rows,
       (SELECT COUNT(*) FROM Order_Details d WHERE NOT EXISTS (SELECT 1 FROM rejoined r WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty AND r.CustName=d.CustName AND r.CustCity=d.CustCity AND r.ProductName=d.ProductName AND r.UnitPrice=d.UnitPrice AND r.OrderDate=d.OrderDate)) AS missing_rows,
       (SELECT COUNT(*) FROM rejoined r WHERE NOT EXISTS (SELECT 1 FROM Order_Details d WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty)) AS spurious_rows

+---------------+--------------+---------------+
| rejoined_rows | missing_rows | spurious_rows |
+---------------+--------------+---------------+
|             4 |            0 |             0 |
+---------------+--------------+---------------+
1 row in set
```

**Why this output is correct:** Lossless: Customer-Orders share CustID (key of Customer), Orders-Order_Item share OrderID (key of Orders), Order_Item-Product share ProductID (key of Product); here verified on the data: the re-joined projections give exactly the 4 original rows (0 missing, 0 spurious). Dependency preserving: each FD sits in one table (fd_analysis.py).

### Task 9 - Create the tables with foreign keys and insert the data

```sql
CREATE TABLE Customer (
    CustID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    CustName VARCHAR(40) NOT NULL,
    CustCity VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Product (
    ProductID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    ProductName VARCHAR(40) NOT NULL,
    UnitPrice   INT         NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Orders (
    OrderID   VARCHAR(5) NOT NULL PRIMARY KEY,
    OrderDate DATE       NOT NULL,
    CustID    VARCHAR(5) NOT NULL,
    CONSTRAINT fk_orders_cust FOREIGN KEY (CustID) REFERENCES Customer(CustID)
) ENGINE=InnoDB;
CREATE TABLE Order_Item (
    OrderID   VARCHAR(5) NOT NULL,
    ProductID VARCHAR(5) NOT NULL,
    Qty       INT        NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT fk_item_order   FOREIGN KEY (OrderID)   REFERENCES Orders(OrderID),
    CONSTRAINT fk_item_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
) ENGINE=InnoDB;
INSERT INTO Customer SELECT DISTINCT CustID, CustName, CustCity FROM Order_Details;
INSERT INTO Product  SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details;
INSERT INTO Orders   SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Details;
INSERT INTO Order_Item SELECT OrderID, ProductID, Qty FROM Order_Details;
SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Product) AS products, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items;
```

**Output**

```text
CREATE TABLE Customer (
    CustID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    CustName VARCHAR(40) NOT NULL,
    CustCity VARCHAR(30) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Product (
    ProductID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    ProductName VARCHAR(40) NOT NULL,
    UnitPrice   INT         NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Orders (
    OrderID   VARCHAR(5) NOT NULL PRIMARY KEY,
    OrderDate DATE       NOT NULL,
    CustID    VARCHAR(5) NOT NULL,
    CONSTRAINT fk_orders_cust FOREIGN KEY (CustID) REFERENCES Customer(CustID)
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Order_Item (
    OrderID   VARCHAR(5) NOT NULL,
    ProductID VARCHAR(5) NOT NULL,
    Qty       INT        NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT fk_item_order   FOREIGN KEY (OrderID)   REFERENCES Orders(OrderID),
    CONSTRAINT fk_item_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
) ENGINE=InnoDB

Query OK, 0 rows affected

INSERT INTO Customer SELECT DISTINCT CustID, CustName, CustCity FROM Order_Details

Query OK, 2 rows affected
Records: 2  Duplicates: 0  Warnings: 0

INSERT INTO Product  SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Orders   SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Details

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Order_Item SELECT OrderID, ProductID, Qty FROM Order_Details

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

SELECT (SELECT COUNT(*) FROM Customer) AS customers, (SELECT COUNT(*) FROM Product) AS products, (SELECT COUNT(*) FROM Orders) AS orders, (SELECT COUNT(*) FROM Order_Item) AS items

+-----------+----------+--------+-------+
| customers | products | orders | items |
+-----------+----------+--------+-------+
|         2 |        3 |      3 |     4 |
+-----------+----------+--------+-------+
1 row in set
```

### Task 10 - Total amount per order (normalised tables)

```sql
SELECT i.OrderID, SUM(i.Qty * p.UnitPrice) AS total_amount FROM Order_Item i JOIN Product p USING (ProductID) GROUP BY i.OrderID ORDER BY i.OrderID;
```

**Output**

```text
SELECT i.OrderID, SUM(i.Qty * p.UnitPrice) AS total_amount FROM Order_Item i JOIN Product p USING (ProductID) GROUP BY i.OrderID ORDER BY i.OrderID

+---------+--------------+
| OrderID | total_amount |
+---------+--------------+
| O1      |          400 |
| O2      |          200 |
| O3      |          150 |
+---------+--------------+
3 rows in set
```

**Why this output is correct:** Amount = SUM(Qty x UnitPrice): O1 = 10x10 + 5x60 = 400, O2 = 20x10 = 200, O3 = 1x150 = 150.

### Task 11 - Customers who bought Pen with the quantity

```sql
SELECT c.CustName, o.OrderID, i.Qty FROM Order_Item i JOIN Product p USING (ProductID) JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) WHERE p.ProductName = 'Pen';
```

**Output**

```text
SELECT c.CustName, o.OrderID, i.Qty FROM Order_Item i JOIN Product p USING (ProductID) JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) WHERE p.ProductName = 'Pen'

+----------+---------+-----+
| CustName | OrderID | Qty |
+----------+---------+-----+
| Sagar    | O1      |  10 |
| Meera    | O2      |  20 |
+----------+---------+-----+
2 rows in set
```

### Task 12 - Changing Sagar's city - one update instead of three

```sql
START TRANSACTION;
UPDATE Order_Details SET CustCity = 'Miraj' WHERE CustID = 'C1';
SELECT ROW_COUNT() AS rows_changed_in_old_design;
UPDATE Customer SET CustCity = 'Miraj' WHERE CustID = 'C1';
SELECT ROW_COUNT() AS rows_changed_in_new_design;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Order_Details SET CustCity = 'Miraj' WHERE CustID = 'C1'

Query OK, 3 rows affected
Rows matched: 3  Changed: 3  Warnings: 0

SELECT ROW_COUNT() AS rows_changed_in_old_design

+----------------------------+
| rows_changed_in_old_design |
+----------------------------+
|                          3 |
+----------------------------+
1 row in set

UPDATE Customer SET CustCity = 'Miraj' WHERE CustID = 'C1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT ROW_COUNT() AS rows_changed_in_new_design

+----------------------------+
| rows_changed_in_new_design |
+----------------------------+
|                          1 |
+----------------------------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** Old design: the city is repeated in 3 rows (ROW_COUNT = 3) and a partial update would corrupt data. New design: exactly 1 row.


## Advanced / examiner-style queries

### Adv 1 - Customer-wise total spending

```sql
SELECT c.CustName, SUM(i.Qty * p.UnitPrice) AS spent FROM Customer c JOIN Orders o USING (CustID) JOIN Order_Item i USING (OrderID) JOIN Product p USING (ProductID) GROUP BY c.CustID, c.CustName;
```

**Output**

```text
SELECT c.CustName, SUM(i.Qty * p.UnitPrice) AS spent FROM Customer c JOIN Orders o USING (CustID) JOIN Order_Item i USING (OrderID) JOIN Product p USING (ProductID) GROUP BY c.CustID, c.CustName

+----------+-------+
| CustName | spent |
+----------+-------+
| Sagar    |   550 |
| Meera    |   200 |
+----------+-------+
2 rows in set
```

### Adv 2 - Insert anomaly solved - add a customer who has not ordered yet

```sql
INSERT INTO Customer VALUES ('C4', 'Neeta', 'Satara');
SELECT * FROM Customer;
```

**Output**

```text
INSERT INTO Customer VALUES ('C4', 'Neeta', 'Satara')

Query OK, 1 row affected

SELECT * FROM Customer

+--------+----------+----------+
| CustID | CustName | CustCity |
+--------+----------+----------+
| C1     | Sagar    | Sangli   |
| C2     | Meera    | Pune     |
| C4     | Neeta    | Satara   |
+--------+----------+----------+
3 rows in set
```

### Adv 3 - Delete anomaly solved - delete order O2 but keep Meera

```sql
START TRANSACTION;
DELETE FROM Order_Item WHERE OrderID = 'O2';
DELETE FROM Orders WHERE OrderID = 'O2';
SELECT * FROM Customer WHERE CustID = 'C2';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

DELETE FROM Order_Item WHERE OrderID = 'O2'

Query OK, 1 row affected

DELETE FROM Orders WHERE OrderID = 'O2'

Query OK, 1 row affected

SELECT * FROM Customer WHERE CustID = 'C2'

+--------+----------+----------+
| CustID | CustName | CustCity |
+--------+----------+----------+
| C2     | Meera    | Pune     |
+--------+----------+----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 4 - Price change of Pen is now one row and applies everywhere

```sql
START TRANSACTION;
UPDATE Product SET UnitPrice = 12 WHERE ProductID = 'P1';
SELECT i.OrderID, i.Qty, p.UnitPrice, i.Qty * p.UnitPrice AS amount FROM Order_Item i JOIN Product p USING (ProductID) WHERE ProductID = 'P1';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Product SET UnitPrice = 12 WHERE ProductID = 'P1'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT i.OrderID, i.Qty, p.UnitPrice, i.Qty * p.UnitPrice AS amount FROM Order_Item i JOIN Product p USING (ProductID) WHERE ProductID = 'P1'

+---------+-----+-----------+--------+
| OrderID | Qty | UnitPrice | amount |
+---------+-----+-----------+--------+
| O1      |  10 |        12 |    120 |
| O2      |  20 |        12 |    240 |
+---------+-----+-----------+--------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 5 - Order for an unknown customer

```sql
INSERT INTO Orders VALUES ('O9', '2026-10-10', 'C99');
```

**Output**

```text
INSERT INTO Orders VALUES ('O9', '2026-10-10', 'C99')

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`norm_3b`.`orders`, CONSTRAINT `fk_orders_cust` FOREIGN KEY (`CustID`) REFERENCES `customer` (`CustID`))
```

**Why this output is correct:** Error 1452: the FK stops orphan orders.

### Adv 6 - Rebuild the original Order_Details with a view (reconstruction)

```sql
CREATE OR REPLACE VIEW Order_Details_View AS
SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
FROM Order_Item i JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) JOIN Product p USING (ProductID);
SELECT * FROM Order_Details_View ORDER BY OrderID, ProductID;
```

**Output**

```text
CREATE OR REPLACE VIEW Order_Details_View AS
SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
FROM Order_Item i JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) JOIN Product p USING (ProductID)

Query OK, 0 rows affected

SELECT * FROM Order_Details_View ORDER BY OrderID, ProductID

+---------+------------+--------+----------+----------+-----------+-------------+-----+-----------+
| OrderID | OrderDate  | CustID | CustName | CustCity | ProductID | ProductName | Qty | UnitPrice |
+---------+------------+--------+----------+----------+-----------+-------------+-----+-----------+
| O1      | 2026-10-01 | C1     | Sagar    | Sangli   | P1        | Pen         |  10 |        10 |
| O1      | 2026-10-01 | C1     | Sagar    | Sangli   | P2        | Notebook    |   5 |        60 |
| O2      | 2026-10-03 | C2     | Meera    | Pune     | P1        | Pen         |  20 |        10 |
| O3      | 2026-10-04 | C1     | Sagar    | Sangli   | P3        | Stapler     |   1 |       150 |
+---------+------------+--------+----------+----------+-----------+-------------+-----+-----------+
4 rows in set
```


## Functional-dependency analysis (Python, `fd_analysis.py`)

```text
=== 3B: Order_Details ===
Attributes : {CustCity, CustID, CustName, OrderDate, OrderID, ProductID, ProductName, Qty, UnitPrice}
FDs        : {OrderID} -> {CustID, OrderDate}; {CustID} -> {CustCity, CustName}; {ProductID} -> {ProductName, UnitPrice}; {OrderID, ProductID} -> {Qty}
Closure {OrderID, ProductID}+ = {CustCity, CustID, CustName, OrderDate, OrderID, ProductID, ProductName, Qty, UnitPrice}
Closure {OrderID}+ = {CustCity, CustID, CustName, OrderDate, OrderID}
Closure {ProductID}+ = {ProductID, ProductName, UnitPrice}
Closure {CustID}+ = {CustCity, CustID, CustName}
Candidate keys : {OrderID, ProductID}
Prime attributes : {OrderID, ProductID}
Partial dependencies (2NF violations) : {OrderID}->{CustCity, CustID, CustName, OrderDate}; {ProductID}->{ProductName, UnitPrice}
3NF violations : {CustID}->{CustCity, CustName}; {OrderID}->{CustCity, CustID, CustName, OrderDate}; {ProductID}->{ProductName, UnitPrice}
BCNF violations : {CustID}->{CustCity, CustName}; {OrderID}->{CustCity, CustID, CustName, OrderDate}; {ProductID}->{ProductName, UnitPrice}

--- Task 4: classification of every FD ---
  {OrderID} -> {CustID, OrderDate} : PARTIAL (determinant is a proper part of the key)
  {CustID} -> {CustCity, CustName} : TRANSITIVE (determinant is a non-key attribute)
  {ProductID} -> {ProductName, UnitPrice} : PARTIAL (determinant is a proper part of the key)
  {OrderID, ProductID} -> {Qty} : full (determinant is the key)

=== 3B: 2NF  (Order_Header | Product | Order_Item) ===
Attributes : {CustCity, CustID, CustName, OrderDate, OrderID, ProductID, ProductName, Qty, UnitPrice}
FDs        : {OrderID} -> {CustID, OrderDate}; {CustID} -> {CustCity, CustName}; {ProductID} -> {ProductName, UnitPrice}; {OrderID, ProductID} -> {Qty}
Decomposition : {CustCity, CustID, CustName, OrderDate, OrderID} | {ProductID, ProductName, UnitPrice} | {OrderID, ProductID, Qty}
Lossless join : True
Dependency preserving : True 
  relation {CustCity, CustID, CustName, OrderDate, OrderID}: keys ['{OrderID}'], BCNF violations ['{CustID}->{CustCity, CustName}']
  relation {ProductID, ProductName, UnitPrice}: keys ['{ProductID}'], BCNF violations none
  relation {OrderID, ProductID, Qty}: keys ['{OrderID, ProductID}'], BCNF violations none

=== 3B: 3NF = BCNF  (Customer | Orders | Product | Order_Item) ===
Attributes : {CustCity, CustID, CustName, OrderDate, OrderID, ProductID, ProductName, Qty, UnitPrice}
FDs        : {OrderID} -> {CustID, OrderDate}; {CustID} -> {CustCity, CustName}; {ProductID} -> {ProductName, UnitPrice}; {OrderID, ProductID} -> {Qty}
Decomposition : {CustCity, CustID, CustName} | {CustID, OrderDate, OrderID} | {ProductID, ProductName, UnitPrice} | {OrderID, ProductID, Qty}
Lossless join : True
Dependency preserving : True 
  relation {CustCity, CustID, CustName}: keys ['{CustID}'], BCNF violations none
  relation {CustID, OrderDate, OrderID}: keys ['{OrderID}'], BCNF violations none
  relation {ProductID, ProductName, UnitPrice}: keys ['{ProductID}'], BCNF violations none
  relation {OrderID, ProductID, Qty}: keys ['{OrderID, ProductID}'], BCNF violations none
```

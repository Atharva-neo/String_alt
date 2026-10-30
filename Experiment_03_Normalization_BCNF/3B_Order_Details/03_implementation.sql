-- Experiment 3B - Order_Details : 12 tasks
/* @CONCEPTS
* Full dependency: whole key -> attribute. Partial: part of the key -> attribute. Transitive: key -> non-key -> non-key.
* Decomposition is **lossless** when the shared attribute is a key of one of the parts; **dependency preserving** when every FD can be checked inside a single table.
* After normalisation each fact (a customer's city, a product's price) is stored once, so one UPDATE is enough.
*/

-- ### TASK 1: Primary key of the given table
-- {OrderID, ProductID}+ contains all attributes and no proper subset does (see fd_analysis.py). Data check: the pair is unique, OrderID alone is not.
SELECT COUNT(*) AS rows_, COUNT(DISTINCT OrderID, ProductID) AS distinct_pairs, COUNT(DISTINCT OrderID) AS distinct_orders, COUNT(DISTINCT ProductID) AS distinct_products FROM Order_Details;

-- ### TASK 2: Redundancy (repeated customer and product data)
-- Sagar/Sangli is stored 3 times, Pen/10 twice. Each extra copy is redundant and can become inconsistent.
SELECT CustID, CustName, CustCity, COUNT(*) AS copies FROM Order_Details GROUP BY CustID, CustName, CustCity;
SELECT ProductID, ProductName, UnitPrice, COUNT(*) AS copies FROM Order_Details GROUP BY ProductID, ProductName, UnitPrice;

-- ### TASK 3: One insert, update and delete anomaly
-- INSERT: a new customer C4 or product P9 cannot be stored without an order (OrderID/ProductID are in the PK) -> error 1364/1048.
-- UPDATE: change Sagar's city in one row only -> two different cities for C1.
-- DELETE: deleting order O2 (Meera's only order) also deletes the only record of customer C2 Meera / Pune.
INSERT INTO Order_Details (CustID, CustName, CustCity) VALUES ('C4', 'Neeta', 'Satara');
START TRANSACTION;
UPDATE Order_Details SET CustCity = 'Miraj' WHERE OrderID = 'O1' AND ProductID = 'P1';
SELECT CustID, CustCity, COUNT(*) AS rows_ FROM Order_Details WHERE CustID = 'C1' GROUP BY CustID, CustCity;
ROLLBACK;
START TRANSACTION;
DELETE FROM Order_Details WHERE OrderID = 'O2';
SELECT * FROM Order_Details WHERE CustID = 'C2';
ROLLBACK;

-- ### TASK 4: Classify each FD as full, partial or transitive
-- OrderID -> OrderDate, CustID : PARTIAL (OrderID is part of the key).  CustID -> CustName, CustCity : TRANSITIVE (OrderID -> CustID -> CustName).
-- ProductID -> ProductName, UnitPrice : PARTIAL.  {OrderID, ProductID} -> Qty : FULL.
SELECT 'OrderID -> OrderDate, CustID' AS fd, 'Partial' AS kind UNION ALL
SELECT 'CustID -> CustName, CustCity', 'Transitive (via OrderID -> CustID)' UNION ALL
SELECT 'ProductID -> ProductName, UnitPrice', 'Partial' UNION ALL
SELECT '{OrderID, ProductID} -> Qty', 'Full';

-- ### TASK 5: Closure of {OrderID, ProductID}
-- Start {OrderID, ProductID}; OrderID adds OrderDate, CustID; CustID adds CustName, CustCity; ProductID adds ProductName, UnitPrice; the FD for Qty adds Qty
-- => all 9 attributes, so it is a superkey (and a candidate key because it is minimal). Computed by fd_analysis.py.
SELECT 'closure({OrderID,ProductID}) = all 9 attributes' AS result;

-- ### TASK 6: Decompose to 2NF
-- Remove partial dependencies: Order_Header(OrderID, OrderDate, CustID, CustName, CustCity), Product(ProductID, ProductName, UnitPrice), Order_Item(OrderID, ProductID, Qty).
CREATE TABLE Order_Header_2NF AS SELECT DISTINCT OrderID, OrderDate, CustID, CustName, CustCity FROM Order_Details;
CREATE TABLE Product_2NF      AS SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details;
CREATE TABLE Order_Item_2NF   AS SELECT OrderID, ProductID, Qty FROM Order_Details;
SELECT * FROM Order_Header_2NF; SELECT * FROM Product_2NF; SELECT * FROM Order_Item_2NF;

-- ### TASK 7: Decompose to 3NF and verify BCNF
-- In Order_Header: OrderID -> CustID -> CustName, CustCity is transitive. Split into Orders(OrderID, OrderDate, CustID) and Customer(CustID, CustName, CustCity).
-- Every determinant is now the key of its table => BCNF.
CREATE TABLE Customer_3NF AS SELECT DISTINCT CustID, CustName, CustCity FROM Order_Header_2NF;
CREATE TABLE Orders_3NF   AS SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Header_2NF;
SELECT * FROM Customer_3NF; SELECT * FROM Orders_3NF;
DROP TABLE Order_Header_2NF, Product_2NF, Order_Item_2NF, Customer_3NF, Orders_3NF;

-- ### TASK 8: Lossless join and dependency preservation
-- Lossless: Customer-Orders share CustID (key of Customer), Orders-Order_Item share OrderID (key of Orders), Order_Item-Product share ProductID (key of Product);
-- here verified on the data: the re-joined projections give exactly the 4 original rows (0 missing, 0 spurious). Dependency preserving: each FD sits in one table (fd_analysis.py).
WITH cust AS (SELECT DISTINCT CustID, CustName, CustCity FROM Order_Details),
     ord  AS (SELECT DISTINCT OrderID, OrderDate, CustID FROM Order_Details),
     prod AS (SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Order_Details),
     item AS (SELECT OrderID, ProductID, Qty FROM Order_Details),
     rejoined AS (SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
                  FROM item i JOIN ord o USING (OrderID) JOIN cust c USING (CustID) JOIN prod p USING (ProductID))
SELECT (SELECT COUNT(*) FROM rejoined) AS rejoined_rows,
       (SELECT COUNT(*) FROM Order_Details d WHERE NOT EXISTS (SELECT 1 FROM rejoined r WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty AND r.CustName=d.CustName AND r.CustCity=d.CustCity AND r.ProductName=d.ProductName AND r.UnitPrice=d.UnitPrice AND r.OrderDate=d.OrderDate)) AS missing_rows,
       (SELECT COUNT(*) FROM rejoined r WHERE NOT EXISTS (SELECT 1 FROM Order_Details d WHERE r.OrderID=d.OrderID AND r.ProductID=d.ProductID AND r.Qty=d.Qty)) AS spurious_rows;

-- ### TASK 9: Create the tables with foreign keys and insert the data
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

-- ### TASK 10: Total amount per order (normalised tables)
-- Amount = SUM(Qty x UnitPrice): O1 = 10x10 + 5x60 = 400, O2 = 20x10 = 200, O3 = 1x150 = 150.
SELECT i.OrderID, SUM(i.Qty * p.UnitPrice) AS total_amount FROM Order_Item i JOIN Product p USING (ProductID) GROUP BY i.OrderID ORDER BY i.OrderID;

-- ### TASK 11: Customers who bought Pen with the quantity
SELECT c.CustName, o.OrderID, i.Qty FROM Order_Item i JOIN Product p USING (ProductID) JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) WHERE p.ProductName = 'Pen';

-- ### TASK 12: Changing Sagar's city - one update instead of three
-- Old design: the city is repeated in 3 rows (ROW_COUNT = 3) and a partial update would corrupt data. New design: exactly 1 row.
START TRANSACTION;
UPDATE Order_Details SET CustCity = 'Miraj' WHERE CustID = 'C1';
SELECT ROW_COUNT() AS rows_changed_in_old_design;
UPDATE Customer SET CustCity = 'Miraj' WHERE CustID = 'C1';
SELECT ROW_COUNT() AS rows_changed_in_new_design;
ROLLBACK;

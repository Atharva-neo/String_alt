-- Experiment 3B - additional examiner-style queries (run after 03)
USE norm_3b;

-- ### ADV 1: Customer-wise total spending
SELECT c.CustName, SUM(i.Qty * p.UnitPrice) AS spent FROM Customer c JOIN Orders o USING (CustID) JOIN Order_Item i USING (OrderID) JOIN Product p USING (ProductID) GROUP BY c.CustID, c.CustName;

-- ### ADV 2: Insert anomaly solved - add a customer who has not ordered yet
INSERT INTO Customer VALUES ('C4', 'Neeta', 'Satara');
SELECT * FROM Customer;

-- ### ADV 3: Delete anomaly solved - delete order O2 but keep Meera
START TRANSACTION;
DELETE FROM Order_Item WHERE OrderID = 'O2';
DELETE FROM Orders WHERE OrderID = 'O2';
SELECT * FROM Customer WHERE CustID = 'C2';
ROLLBACK;

-- ### ADV 4: Price change of Pen is now one row and applies everywhere
START TRANSACTION;
UPDATE Product SET UnitPrice = 12 WHERE ProductID = 'P1';
SELECT i.OrderID, i.Qty, p.UnitPrice, i.Qty * p.UnitPrice AS amount FROM Order_Item i JOIN Product p USING (ProductID) WHERE ProductID = 'P1';
ROLLBACK;

-- ### ADV 5: Order for an unknown customer
-- Error 1452: the FK stops orphan orders.
INSERT INTO Orders VALUES ('O9', '2026-10-10', 'C99');

-- ### ADV 6: Rebuild the original Order_Details with a view (reconstruction)
CREATE OR REPLACE VIEW Order_Details_View AS
SELECT o.OrderID, o.OrderDate, c.CustID, c.CustName, c.CustCity, p.ProductID, p.ProductName, i.Qty, p.UnitPrice
FROM Order_Item i JOIN Orders o USING (OrderID) JOIN Customer c USING (CustID) JOIN Product p USING (ProductID);
SELECT * FROM Order_Details_View ORDER BY OrderID, ProductID;

-- Experiment 1D - Online Shop : implementation of the 12 tasks
/* @CONCEPTS
* **Order_Item** is the junction table of Orders and Product (M:N) with composite PK `(order_id, prod_id)`, so a product appears once per order.
* **UPDATE with JOIN** (MySQL): `UPDATE a JOIN (SELECT ...) b ON ... SET a.col = ...` applies one value per matching product.
* Deleting through two levels (Customer -> Orders -> Order_Item) needs CASCADE on **both** FKs.
* **Roles** (MySQL 8): `CREATE ROLE`, `GRANT priv TO role`, `GRANT role TO user`, `SET DEFAULT ROLE`. Revoking from the role changes all members at once.
* Oracle: `CREATE ROLE sales_staff; GRANT SELECT ON Product TO sales_staff; GRANT sales_staff TO shop_user;`
*/

-- ### TASK 1: ER diagram for Customer, Product, Orders, Order_Item
-- Customer 1:N Orders, Orders 1:N Order_Item, Product 1:N Order_Item (Orders M:N Product). See 06_explanation.md.
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'shop_1d' ORDER BY table_name, constraint_type;

-- ### TASK 2: Tables with composite PK and CHECKs
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'shop_1d';

-- ### TASK 3: Insert data; Order_Item with qty 0 must fail
-- qty = 0 violates chk_item_qty (error 3819).
SELECT * FROM Order_Item;
INSERT INTO Order_Item VALUES (1003, 'P2', 0);

-- ### TASK 4: Product with a duplicate prod_id
-- 'P1' already exists -> error 1062 Duplicate entry for key 'product.PRIMARY'.
INSERT INTO Product VALUES ('P1', 'Another Laptop', 'Electronics', 40000, 5);

-- ### TASK 5: All orders of Sagar with product names
-- Customer -> Orders -> Order_Item -> Product join, filtered by customer name; qty*price gives the line amount.
SELECT o.order_id, o.order_date, p.name AS product, i.qty, p.price * i.qty AS line_amount
FROM Customer c JOIN Orders o ON o.cust_id = c.cust_id
JOIN Order_Item i ON i.order_id = o.order_id
JOIN Product p ON p.prod_id = i.prod_id
WHERE c.name = 'Sagar' ORDER BY o.order_id;

-- ### TASK 6: Reduce stock of each product by the quantity ordered
-- The derived table sums quantities per product; the UPDATE joins to it. P1 10->9, P2 100->98, P3 500->490, P4 25->24.
UPDATE Product p
JOIN (SELECT prod_id, SUM(qty) AS ordered FROM Order_Item GROUP BY prod_id) o ON o.prod_id = p.prod_id
SET p.stock = p.stock - o.ordered;
SELECT prod_id, name, stock FROM Product;

-- ### TASK 7: Products whose stock is below 20
-- Only the Laptop (9) is below 20 after Task 6.
SELECT prod_id, name, stock FROM Product WHERE stock < 20;

-- ### TASK 8: Add discount column with DEFAULT 0 and CHECK (discount BETWEEN 0 AND 50)
-- Existing rows get 0. Value 60 is rejected by the new CHECK.
ALTER TABLE Product ADD COLUMN discount INT NOT NULL DEFAULT 0, ADD CONSTRAINT chk_product_discount CHECK (discount BETWEEN 0 AND 50);
UPDATE Product SET discount = 60 WHERE prod_id = 'P2';
SELECT prod_id, name, discount FROM Product;

-- ### TASK 9: Increase Stationery prices by 5%
-- Only Notebook (60) changes: 60 * 1.05 = 63.
UPDATE Product SET price = price * 1.05 WHERE category = 'Stationery';
SELECT prod_id, name, category, price FROM Product;

-- ### TASK 10: Delete customer 1 with a plain FK (error), then with ON DELETE CASCADE
-- Plain FK: error 1451 because Orders 1001 and 1003 belong to Sagar. The cascade must be defined on Orders->Customer AND Order_Item->Orders
-- because Order_Item rows hang below Orders. After the delete, Sagar, orders 1001/1003 and their 3 items are gone.
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

-- ### TASK 11: Role sales_staff (SELECT on Product, INSERT on Orders) granted to a new user
-- The user inherits privileges through the role. SET DEFAULT ROLE activates it at login.
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

-- ### TASK 12: Revoke INSERT from the role; the user can no longer insert orders
-- Revoking from the role immediately affects every user holding it. New INSERT -> ERROR 1142.
DELETE FROM Orders WHERE order_id = 1004;
REVOKE INSERT ON shop_1d.Orders FROM 'sales_staff';
SHOW GRANTS FOR 'shop_user'@'localhost' USING 'sales_staff';
-- @as shop_user Shop@12345
-- | INSERT INTO Orders VALUES (1005, 2, '2026-10-21');
-- | SELECT COUNT(*) AS products_visible FROM Product;

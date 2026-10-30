-- Experiment 6A - Retail store roles : 12 tasks
/* @CONCEPTS
* **Stock maintenance by triggers**: AFTER INSERT on Purchase adds to `qty_in_stock`; BEFORE INSERT on Sale refuses a sale larger than the stock (SIGNAL); AFTER INSERT on Sale subtracts.
* **Triggers run with the privileges of their DEFINER**, so a clerk who may only INSERT into Sale still causes the stock update - no UPDATE right on Product is needed.
* **Reorder alert** = products with `qty_in_stock <= reorder_level`, joined to Supplier for the contact data.
* **RBAC in MySQL 8**: `CREATE ROLE`, `GRANT priv TO role`, `GRANT role TO user`, `SET DEFAULT ROLE` (a granted role is inactive until it is made default or `SET ROLE` is issued).
* **Column privilege** `UPDATE (price)` lets a manager change prices but nothing else. `SHOW GRANTS FOR user USING role` expands the role's privileges.
* Oracle: `CREATE ROLE clerk; GRANT INSERT ON Sale TO clerk; GRANT clerk TO clerk1;` (roles are enabled by default); triggers use `:NEW` and `RAISE_APPLICATION_ERROR`.
*/

-- ### TASK 1: ER diagram, tables with keys and constraints, data
-- The ER diagram is in 06_explanation.md. Product.category is a FK to Category; Purchase/Sale reference Product; CHECKs keep price > 0 and stock >= 0.
SELECT * FROM Product;
SELECT * FROM Stock;

-- ### TASK 2: AFTER INSERT trigger on Purchase adds qty to stock
DELIMITER $$
CREATE TRIGGER trg_purchase_add_stock AFTER INSERT ON Purchase FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock + NEW.qty WHERE prod_id = NEW.prod_id;
END$$
DELIMITER ;
SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a';

-- ### TASK 3: BEFORE INSERT trigger on Sale blocks the sale if stock is short
-- Reads the current stock; if NEW.qty is bigger it SIGNALs 'Insufficient stock' and the INSERT is rejected before anything is written.
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

-- ### TASK 4: AFTER INSERT trigger on Sale reduces stock
DELIMITER $$
CREATE TRIGGER trg_sale_reduce_stock AFTER INSERT ON Sale FOR EACH ROW
BEGIN
    UPDATE Product SET qty_in_stock = qty_in_stock - NEW.qty WHERE prod_id = NEW.prod_id;
END$$
DELIMITER ;
SELECT trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'inventory_6a' ORDER BY trigger_name;

-- ### TASK 5: Insert purchase (P3, S2, 50) and sale (P2, 10) - show the result and the error
-- Purchase: A4 Paper stock 6 + 50 = 56. Sale of 10 monitors: stock is only 8, so the BEFORE trigger raises 'Insufficient stock' and stock stays 8.
-- A valid sale (P1, 5) is added afterwards to show the AFTER trigger: Keyboard 40 -> 35.
INSERT INTO Purchase (prod_id, supplier_id, qty) VALUES ('P3', 'S2', 50);
INSERT INTO Sale (prod_id, qty) VALUES ('P2', 10);
INSERT INTO Sale (prod_id, qty, sold_by) VALUES ('P1', 5, 'root');
SELECT prod_id, pname, qty_in_stock FROM Product ORDER BY prod_id;
SELECT * FROM Purchase; SELECT * FROM Sale;

-- ### TASK 6: Products at or below reorder level with supplier name and phone
-- After task 5 the A4 paper is 56 (> 20); only the USB Drive (12 <= 15) needs re-ordering.
SELECT p.prod_id, p.pname, p.qty_in_stock, p.reorder_level, s.sname, s.phone
FROM Product p JOIN Supplier s ON s.supplier_id = p.supplier_id
WHERE p.qty_in_stock <= p.reorder_level ORDER BY p.prod_id;

-- ### TASK 7: Category-wise stock value (qty x price)
SELECT category, SUM(qty_in_stock * price) AS stock_value, SUM(qty_in_stock) AS units FROM Product GROUP BY category;

-- ### TASK 8: Roles admin, store_manager, clerk and their privileges
-- admin: everything on the database; store_manager: read Product and change only price; clerk: read Product and record sales.
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

-- ### TASK 9: Users mgr1 and clerk1 with their roles (SET DEFAULT ROLE)
CREATE USER 'mgr1'@'localhost'   IDENTIFIED BY 'Mgr@12345';
CREATE USER 'clerk1'@'localhost' IDENTIFIED BY 'Clerk@12345';
GRANT 'store_manager' TO 'mgr1'@'localhost';
GRANT 'clerk' TO 'clerk1'@'localhost';
SET DEFAULT ROLE 'store_manager' TO 'mgr1'@'localhost';
SET DEFAULT ROLE 'clerk' TO 'clerk1'@'localhost';
SELECT user, host, default_role_user FROM mysql.default_roles WHERE user IN ('mgr1', 'clerk1');

-- ### TASK 10: clerk1 tries UPDATE Product SET price = 800 (denied); mgr1 does it (allowed)
-- The clerk has no UPDATE privilege on Product at all: ERROR 1142. The manager holds UPDATE(price): allowed. As a safety measure the manager's statement
-- is limited to one product (the PDF statement without WHERE would reprice everything); root then restores the price.
-- @as clerk1 Clerk@12345
-- | UPDATE Product SET price = 800;
-- | SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1';
-- @as mgr1 Mgr@12345
-- | UPDATE Product SET price = 800 WHERE prod_id = 'P1';
-- | SELECT prod_id, pname, price FROM Product WHERE prod_id = 'P1';
-- | UPDATE Product SET qty_in_stock = 999 WHERE prod_id = 'P1';
UPDATE Product SET price = 700 WHERE prod_id = 'P1';

-- ### TASK 11: SHOW GRANTS for each user
SHOW GRANTS FOR 'mgr1'@'localhost' USING 'store_manager';
SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk';

-- ### TASK 12: REVOKE INSERT on Sale from clerk; clerk1 can no longer record a sale
-- Before the revoke clerk1 records a sale (stock of P4 drops 150 -> 147 although the clerk has no UPDATE right: the trigger runs as its definer).
-- The privilege is removed from the ROLE, so every clerk loses it at once. The next INSERT by clerk1 is denied (ERROR 1142) while SELECT on Product still works.
-- @as clerk1 Clerk@12345
-- | INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3);
-- | SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4';
REVOKE INSERT ON inventory_6a.Sale FROM 'clerk';
SHOW GRANTS FOR 'clerk1'@'localhost' USING 'clerk';
-- @as clerk1 Clerk@12345
-- | INSERT INTO Sale (prod_id, qty) VALUES ('P4', 3);
-- | SELECT prod_id, qty_in_stock FROM Product WHERE prod_id = 'P4';

-- Experiment 6C - Multi-warehouse : 12 tasks
/* @CONCEPTS
* **Composite primary key** `(wh_id, prod_id)` in Wh_Stock: one row per product per warehouse.
* **Stock transfer** = decrease in the source row + increase (or creation) in the destination row; it must be ONE transaction so stock is neither lost nor created. `INSERT ... ON DUPLICATE KEY UPDATE` creates the destination row when it does not exist yet.
* **Transfer voucher + audit**: the procedure inserts a row into `Stock_Transfer`; the AFTER INSERT trigger copies it into `Transfer_Log` with the user and time. A rolled-back transfer leaves neither row.
* **Views and privileges**: `SQL SECURITY DEFINER` (default) lets a user query a view without any right on the base tables. Likewise `EXECUTE` on a procedure lets the user run it with the definer's rights, so `wh_manager` needs no direct INSERT right on the transfer tables.
* Reorder rule across warehouses: total stock (`COALESCE(SUM(qty),0)`) <= reorder_level, products without any warehouse row count as 0.
*/

-- ### TASK 1: Create Warehouse and Wh_Stock (composite PK wh_id, prod_id) and insert the data
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

-- ### TASK 2: Stock of each product in each warehouse with the product name
SELECT w.wh_id, w.city, p.prod_id, p.pname, w.qty FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id ORDER BY w.wh_id, p.prod_id;

-- ### TASK 3: Total stock per product across all warehouses
-- LEFT JOIN keeps products that exist in no warehouse (P4, P5) with total 0.
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id GROUP BY p.prod_id, p.pname ORDER BY p.prod_id;

-- ### TASK 4: Procedure transfer_stock(from_wh, to_wh, prod, qty) as one transaction with rollback on shortage
-- (Stock_Transfer is the voucher table used in Task 6; it is created here because the procedure writes to it.)
-- FOR UPDATE locks the source row. Shortage / missing source row / invalid request => SIGNAL => EXIT HANDLER does ROLLBACK + RESIGNAL.
-- The destination row is created if the warehouse never stocked the product (ON DUPLICATE KEY UPDATE adds to the existing quantity).
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

-- ### TASK 5: Transfer 10 keyboards W1 -> W2, then try 10 monitors and show the rollback
-- Keyboards: W1 25 -> 15, W2 15 -> 25. Monitors: W1 holds only 5, so the procedure raises 'Shortage' and the handler rolls everything back.
CALL transfer_stock('W1', 'W2', 'P1', 10);
SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id;
CALL transfer_stock('W1', 'W2', 'P2', 10);
SELECT * FROM Wh_Stock ORDER BY wh_id, prod_id;
SELECT COUNT(*) AS vouchers FROM Stock_Transfer;

-- ### TASK 6: Trigger that logs every transfer in Transfer_Log
-- AFTER INSERT on the voucher table copies the transfer with the user and time. It is created now, so the earlier Task 5 transfer is back-filled once,
-- then new transfers are logged automatically (the test transfer is W2 -> W1 of 2 keyboards).
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

-- ### TASK 7: Warehouse-wise stock value (qty x price)
SELECT w.wh_id, wh.city, SUM(w.qty * p.price) AS stock_value, SUM(w.qty) AS units
FROM Wh_Stock w JOIN Product p ON p.prod_id = w.prod_id JOIN Warehouse wh ON wh.wh_id = w.wh_id GROUP BY w.wh_id, wh.city;

-- ### TASK 8: View reorder_list: total stock across warehouses <= reorder_level, with supplier name and phone
-- Totals (after the transfers): P1 40 (reorder 10) OK; P2 5 <= 5, P3 6 <= 20, P4 0 <= 50, P5 0 <= 15 => these four must be re-ordered.
CREATE VIEW reorder_list AS
SELECT p.prod_id, p.pname, COALESCE(SUM(w.qty), 0) AS total_stock, p.reorder_level, s.sname AS supplier, s.phone AS supplier_phone
FROM Product p LEFT JOIN Wh_Stock w ON w.prod_id = p.prod_id JOIN Supplier s ON s.supplier_id = p.supplier_id
GROUP BY p.prod_id, p.pname, p.reorder_level, s.sname, s.phone
HAVING COALESCE(SUM(w.qty), 0) <= p.reorder_level;
SELECT * FROM reorder_list ORDER BY prod_id;

-- ### TASK 9: User purchase_officer: GRANT SELECT on the view only
DROP USER IF EXISTS 'purchase_officer'@'localhost';
CREATE USER 'purchase_officer'@'localhost' IDENTIFIED BY 'Officer@12345';
GRANT SELECT ON warehouse_6c.reorder_list TO 'purchase_officer'@'localhost';
SHOW GRANTS FOR 'purchase_officer'@'localhost';

-- ### TASK 10: SELECT on Product fails for purchase_officer while the view works
-- The view runs with the definer's rights, the officer has no right on the base tables: ERROR 1142 on Product / Supplier / Wh_Stock.
-- @as purchase_officer Officer@12345
-- | SELECT prod_id, pname, total_stock, supplier, supplier_phone FROM reorder_list ORDER BY prod_id;
-- | SELECT * FROM Product;
-- | SELECT * FROM Wh_Stock;

-- ### TASK 11: User wh_manager with UPDATE on Wh_Stock and EXECUTE on transfer_stock
-- EXECUTE lets wh_manager run the procedure (which writes the voucher and log with the definer's rights). UPDATE on Wh_Stock is a direct right; INSERT/SELECT are not granted.
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

-- ### TASK 12: REVOKE EXECUTE and show the procedure call fails
-- After the revoke ERROR 1370 (42000): execute command denied to user 'wh_manager'@'localhost' for routine 'warehouse_6c.transfer_stock'.
REVOKE EXECUTE ON PROCEDURE warehouse_6c.transfer_stock FROM 'wh_manager'@'localhost';
SHOW GRANTS FOR 'wh_manager'@'localhost';
-- @as wh_manager WhMgr@12345
-- | CALL transfer_stock('W1', 'W2', 'P1', 5);

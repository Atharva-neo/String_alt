-- Experiment 6D - Login module : common inventory tables (App_User / Login_Log are created in Task 1)
-- @DB login_6d
/* @ER
erDiagram
    APP_USER ||--o{ LOGIN_LOG : "attempts (by username)"
    APP_USER {
        int user_id PK
        varchar username UK
        char password_hash "SHA2(password,256) = 64 hex chars"
        varchar role "admin / clerk"
        int failed_attempts
        tinyint is_locked
    }
    LOGIN_LOG {
        int log_id PK
        varchar username
        datetime login_time
        varchar status "Success / Failed / Locked"
    }
*/
DROP DATABASE IF EXISTS login_6d;
CREATE DATABASE login_6d;
USE login_6d;

CREATE TABLE Category (cat_name VARCHAR(30) NOT NULL PRIMARY KEY) ENGINE=InnoDB;
CREATE TABLE Supplier (
    supplier_id VARCHAR(5)  NOT NULL PRIMARY KEY,
    sname       VARCHAR(40) NOT NULL,
    city        VARCHAR(30),
    phone       VARCHAR(15) NOT NULL,
    CONSTRAINT uq_supplier_phone UNIQUE (phone)
) ENGINE=InnoDB;
CREATE TABLE Product (
    prod_id       VARCHAR(5)    NOT NULL PRIMARY KEY,
    pname         VARCHAR(40)   NOT NULL,
    category      VARCHAR(30)   NOT NULL,
    price         DECIMAL(10,2) NOT NULL,
    qty_in_stock  INT           NOT NULL DEFAULT 0,
    reorder_level INT           NOT NULL DEFAULT 0,
    supplier_id   VARCHAR(5)    NOT NULL,
    CONSTRAINT fk_product_category FOREIGN KEY (category)    REFERENCES Category(cat_name),
    CONSTRAINT fk_product_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT chk_product_price CHECK (price > 0),
    CONSTRAINT chk_product_stock CHECK (qty_in_stock >= 0)
) ENGINE=InnoDB;
CREATE TABLE Purchase (
    pur_id      INT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    prod_id     VARCHAR(5) NOT NULL,
    supplier_id VARCHAR(5) NOT NULL,
    qty         INT        NOT NULL,
    pur_date    DATE       NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_purchase_product  FOREIGN KEY (prod_id)     REFERENCES Product(prod_id),
    CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT chk_purchase_qty CHECK (qty > 0)
) ENGINE=InnoDB;
CREATE TABLE Sale (
    sale_id   INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    prod_id   VARCHAR(5)  NOT NULL,
    qty       INT         NOT NULL,
    sale_date DATE        NOT NULL DEFAULT (CURRENT_DATE),
    sold_by   VARCHAR(50) NOT NULL DEFAULT (SUBSTRING_INDEX(CURRENT_USER(), '@', 1)),
    CONSTRAINT fk_sale_product FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_sale_qty CHECK (qty > 0)
) ENGINE=InnoDB;

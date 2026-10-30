-- Experiment 6A - Retail store roles : Task 1 (ER diagram + tables with keys and constraints)
-- @DB inventory_6a
/* @ER
erDiagram
    CATEGORY ||--o{ PRODUCT : classifies
    SUPPLIER ||--o{ PRODUCT : "is main supplier of"
    SUPPLIER ||--o{ PURCHASE : supplies
    PRODUCT  ||--o{ PURCHASE : "bought as"
    PRODUCT  ||--o{ SALE : "sold as"
    CATEGORY {
        varchar cat_name PK
    }
    SUPPLIER {
        varchar supplier_id PK
        varchar sname
        varchar city
        varchar phone UK
    }
    PRODUCT {
        varchar prod_id PK
        varchar pname
        varchar category FK
        decimal price "CHECK > 0"
        int qty_in_stock "CHECK >= 0 (this is the STOCK level)"
        int reorder_level
        varchar supplier_id FK
    }
    PURCHASE {
        int pur_id PK
        varchar prod_id FK
        varchar supplier_id FK
        int qty
        date pur_date
    }
    SALE {
        int sale_id PK
        varchar prod_id FK
        int qty
        date sale_date
        varchar sold_by
    }
*/
DROP DATABASE IF EXISTS inventory_6a;
CREATE DATABASE inventory_6a;
USE inventory_6a;

CREATE TABLE Category (
    cat_name VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

CREATE TABLE Supplier (
    supplier_id VARCHAR(5)  NOT NULL PRIMARY KEY,
    sname       VARCHAR(40) NOT NULL,
    city        VARCHAR(30),
    phone       VARCHAR(15) NOT NULL,
    CONSTRAINT uq_supplier_phone UNIQUE (phone)
) ENGINE=InnoDB;

-- The PDF's Product table already carries qty_in_stock and reorder_level, so it IS the stock record.
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

-- "Stock" as a read model over Product (no duplicated quantity => no update anomaly)
CREATE VIEW Stock AS
SELECT prod_id, pname, qty_in_stock, reorder_level,
       IF(qty_in_stock <= reorder_level, 'REORDER', 'OK') AS status
FROM Product;

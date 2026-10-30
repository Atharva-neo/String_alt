-- Experiment 6C - Multi-warehouse : common inventory tables (Warehouse / Wh_Stock / transfer tables are created in the tasks)
-- @DB warehouse_6c
/* @ER
erDiagram
    WAREHOUSE ||--o{ WH_STOCK : holds
    PRODUCT   ||--o{ WH_STOCK : "is stored as"
    WAREHOUSE ||--o{ STOCK_TRANSFER : "sends (from_wh)"
    WAREHOUSE ||--o{ STOCK_TRANSFER : "receives (to_wh)"
    PRODUCT   ||--o{ STOCK_TRANSFER : moves
    STOCK_TRANSFER ||--|| TRANSFER_LOG : "trigger copies"
    WAREHOUSE {
        varchar wh_id PK
        varchar city
    }
    WH_STOCK {
        varchar wh_id PK, FK
        varchar prod_id PK, FK
        int qty "CHECK >= 0"
    }
    STOCK_TRANSFER {
        int transfer_id PK
        varchar from_wh FK
        varchar to_wh FK
        varchar prod_id FK
        int qty
    }
    TRANSFER_LOG {
        int log_id PK
        varchar from_wh
        varchar to_wh
        varchar prod_id
        int qty
        datetime logged_at
        varchar logged_by
    }
*/
DROP DATABASE IF EXISTS warehouse_6c;
CREATE DATABASE warehouse_6c;
USE warehouse_6c;

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

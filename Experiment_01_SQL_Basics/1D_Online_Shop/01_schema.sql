-- Experiment 1D - Online Shop | Task 1 (ER) and Task 2 (tables, composite PK, CHECKs)
-- @DB shop_1d
/* @ER
erDiagram
    CUSTOMER ||--o{ ORDERS : "places (1 : N)"
    ORDERS   ||--|{ ORDER_ITEM : "contains (1 : N)"
    PRODUCT  ||--o{ ORDER_ITEM : "appears in (1 : N)"
    CUSTOMER {
        int cust_id PK
        varchar name
        varchar city
    }
    PRODUCT {
        varchar prod_id PK
        varchar name
        varchar category
        decimal price
        int stock "CHECK >= 0"
    }
    ORDERS {
        int order_id PK
        int cust_id FK
        date order_date
    }
    ORDER_ITEM {
        int order_id PK, FK
        varchar prod_id PK, FK
        int qty "CHECK > 0"
    }
*/

DROP DATABASE IF EXISTS shop_1d;
CREATE DATABASE shop_1d;
USE shop_1d;

CREATE TABLE Customer (
    cust_id INT         NOT NULL PRIMARY KEY,
    name    VARCHAR(40) NOT NULL,
    city    VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE Product (
    prod_id  VARCHAR(5)   NOT NULL PRIMARY KEY,
    name     VARCHAR(40)  NOT NULL,
    category VARCHAR(30),
    price    DECIMAL(10,2) NOT NULL,
    stock    INT          NOT NULL,
    CONSTRAINT chk_product_stock CHECK (stock >= 0)
) ENGINE=InnoDB;

CREATE TABLE Orders (
    order_id   INT  NOT NULL PRIMARY KEY,
    cust_id    INT  NOT NULL,
    order_date DATE NOT NULL,
    CONSTRAINT fk_orders_cust FOREIGN KEY (cust_id) REFERENCES Customer(cust_id)
) ENGINE=InnoDB;

CREATE TABLE Order_Item (
    order_id INT        NOT NULL,
    prod_id  VARCHAR(5) NOT NULL,
    qty      INT        NOT NULL,
    PRIMARY KEY (order_id, prod_id),
    CONSTRAINT fk_item_order   FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (prod_id)  REFERENCES Product(prod_id),
    CONSTRAINT chk_item_qty CHECK (qty > 0)
) ENGINE=InnoDB;

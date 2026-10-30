-- Experiment 2B - Sales : schema
-- @DB sales_2b
/* @ER
erDiagram
    CUSTOMER ||--o{ ORDERS : places
    PRODUCT  ||--o{ ORDERS : "ordered in"
    CUSTOMER {
        int cust_id PK
        varchar cname
        varchar city
    }
    PRODUCT {
        varchar prod_id PK
        varchar pname
        int price
    }
    ORDERS {
        int order_id PK
        int cust_id FK
        varchar prod_id FK
        int qty
        date order_date
        varchar status "Delivered / Pending"
    }
*/
DROP DATABASE IF EXISTS sales_2b;
CREATE DATABASE sales_2b;
USE sales_2b;

CREATE TABLE Customer (
    cust_id INT NOT NULL PRIMARY KEY,
    cname   VARCHAR(40) NOT NULL,
    city    VARCHAR(30)
) ENGINE=InnoDB;
CREATE TABLE Product (
    prod_id VARCHAR(5) NOT NULL PRIMARY KEY,
    pname   VARCHAR(40) NOT NULL,
    price   INT NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Orders (
    order_id   INT NOT NULL PRIMARY KEY,
    cust_id    INT NOT NULL,
    prod_id    VARCHAR(5) NOT NULL,
    qty        INT NOT NULL,
    order_date DATE NOT NULL,
    status     VARCHAR(10) NOT NULL,
    CONSTRAINT fk_o_cust FOREIGN KEY (cust_id) REFERENCES Customer(cust_id),
    CONSTRAINT fk_o_prod FOREIGN KEY (prod_id) REFERENCES Product(prod_id),
    CONSTRAINT chk_o_status CHECK (status IN ('Delivered','Pending'))
) ENGINE=InnoDB;

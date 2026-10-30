-- Experiment 3B - Order_Details : the given (1NF, but not 2NF/3NF) relation
-- @DB norm_3b
/* @ER
flowchart LR
    R["Order_Details<br/>PK (OrderID, ProductID)<br/>1NF only"] -->|"Task 6: remove partial FDs"| N2["2NF: Order_Header | Product | Order_Item"]
    N2 -->|"Task 7: remove transitive FD CustID"| N3["3NF = BCNF: Customer | Orders | Product | Order_Item"]
*/
DROP DATABASE IF EXISTS norm_3b;
CREATE DATABASE norm_3b;
USE norm_3b;

CREATE TABLE Order_Details (
    OrderID     VARCHAR(5)  NOT NULL,
    OrderDate   DATE        NOT NULL,
    CustID      VARCHAR(5)  NOT NULL,
    CustName    VARCHAR(40) NOT NULL,
    CustCity    VARCHAR(30) NOT NULL,
    ProductID   VARCHAR(5)  NOT NULL,
    ProductName VARCHAR(40) NOT NULL,
    Qty         INT         NOT NULL,
    UnitPrice   INT         NOT NULL,
    PRIMARY KEY (OrderID, ProductID)
) ENGINE=InnoDB;

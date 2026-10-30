-- Experiment 1D - sample data from the PDF
USE shop_1d;
INSERT INTO Customer VALUES (1,'Sagar','Sangli'), (2,'Meera','Pune'), (3,'Vikas','Satara');
INSERT INTO Product VALUES
('P1','Laptop','Electronics',55000,10),
('P2','Mouse','Electronics',500,100),
('P3','Notebook','Stationery',60,500),
('P4','Desk Lamp','Home',1200,25);
INSERT INTO Orders VALUES (1001,1,'2026-10-02'), (1002,2,'2026-10-05'), (1003,1,'2026-10-09');
INSERT INTO Order_Item VALUES (1001,'P1',1), (1001,'P2',2), (1002,'P3',10), (1003,'P4',1);

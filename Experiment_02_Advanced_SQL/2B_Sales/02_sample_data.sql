-- Experiment 2B - sample data from the PDF
USE sales_2b;
INSERT INTO Customer VALUES (1,'Ganesh Traders','Sangli'), (2,'Shree Mart','Pune'), (3,'Om Stores','Satara'), (4,'City Bazaar','Mumbai');
INSERT INTO Product VALUES ('P1','Rice 25 kg',1500), ('P2','Sugar 10 kg',450), ('P3','Oil 15 L',2100), ('P4','Tea 1 kg',520);
INSERT INTO Orders VALUES
(1,1,'P1',20,'2026-08-04','Delivered'),
(2,2,'P3',15,'2026-08-19','Delivered'),
(3,1,'P2',30,'2026-09-02','Pending'),
(4,3,'P1',10,'2026-09-15','Delivered'),
(5,2,'P1',25,'2026-10-01','Pending'),
(6,1,'P3',12,'2026-10-10','Delivered');

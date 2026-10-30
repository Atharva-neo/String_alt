-- Experiment 6A - common data for 6A-6D from the PDF (Purchase and Sale start empty)
USE inventory_6a;
INSERT INTO Category VALUES ('Electronics'), ('Stationery');
INSERT INTO Supplier VALUES
('S1','Om Distributors','Sangli','9850011111'),
('S2','Shree Agencies','Kolhapur','9850022222'),
('S3','Global Supplies','Pune','9850033333');
INSERT INTO Product (prod_id, pname, category, price, qty_in_stock, reorder_level, supplier_id) VALUES
('P1','Keyboard','Electronics',700,40,10,'S1'),
('P2','Monitor','Electronics',9000,8,5,'S3'),
('P3','A4 Paper','Stationery',250,6,20,'S2'),
('P4','Marker','Stationery',30,150,50,'S2'),
('P5','USB Drive','Electronics',450,12,15,'S1');

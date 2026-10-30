-- Experiment 2D - sample data from the PDF
USE flight_2d;
INSERT INTO Flight VALUES
('AI101','Air India','Pune','Delhi',180),
('6E202','IndiGo','Mumbai','Goa',150),
('UK303','Vistara','Pune','Bengaluru',160),
('6E404','IndiGo','Mumbai','Delhi',180);
INSERT INTO Passenger VALUES (1,'Rajesh',45), (2,'Sonal',29), (3,'Arjun',34), (4,'Mitali',22);
INSERT INTO Booking VALUES
(1,1,'AI101','2026-11-01',6500),
(2,1,'6E202','2026-11-05',3200),
(3,1,'UK303','2026-11-10',4800),
(4,2,'AI101','2026-11-01',6500),
(5,3,'6E202','2026-11-05',3400);

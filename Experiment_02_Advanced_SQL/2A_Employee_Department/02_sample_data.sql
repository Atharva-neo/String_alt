-- Experiment 2A - sample data from the PDF
USE emp_2a;
INSERT INTO Department VALUES (10,'Accounts','Sangli'), (20,'Research','Pune'), (30,'Sales','Mumbai'), (40,'Operations','Kolhapur');
-- the president (manager NULL) must be inserted first because of the self-referencing FK
INSERT INTO Employee VALUES
(1,'Suresh','President',NULL,150000,10,'2015-01-10'),
(2,'Anita','Manager',1,90000,20,'2017-03-15'),
(3,'Rohit','Analyst',2,60000,20,'2019-07-01'),
(4,'Kavya','Analyst',2,65000,20,'2020-02-20'),
(5,'Manoj','Manager',1,85000,30,'2016-11-11'),
(6,'Tejas','Salesman',5,35000,30,'2021-06-05'),
(7,'Pallavi','Salesman',5,38000,30,'2022-01-17'),
(8,'Nikhil','Clerk',1,25000,NULL,'2023-08-01');

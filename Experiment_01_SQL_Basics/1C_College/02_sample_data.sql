-- Experiment 1C - sample data from the PDF
USE college_1c;
INSERT INTO Department VALUES ('D1','AIML','Dr. Patil'), ('D2','CSE','Dr. Kale'), ('D3','Mechanical','Dr. Joshi');
INSERT INTO Student VALUES
(101,'Aditya Pawar','D1',2,8.4),
(102,'Neha Gaikwad','D1',2,9.1),
(103,'Omkar Salunkhe','D2',3,7.2),
(104,'Priya Mane','D3',1,6.8);
INSERT INTO Course VALUES
('C101','DBMS',4,'D1'),
('C102','Machine Learning',4,'D1'),
('C201','Operating Systems',3,'D2');
INSERT INTO Enrolment VALUES (101,'C101'), (101,'C102'), (102,'C101'), (103,'C201');

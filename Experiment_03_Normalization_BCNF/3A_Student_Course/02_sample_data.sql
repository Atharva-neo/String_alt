-- Experiment 3A - sample data from the PDF (unnormalised rows exactly as printed)
USE norm_3a;
INSERT INTO Student_Course_UNF VALUES
(101,'Aditya','C1, C2','DBMS, ML','Dr. Patil, Dr. Kale','9800011111, 9800022222','A, B'),
(102,'Neha','C1','DBMS','Dr. Patil','9800011111','A+'),
(103,'Omkar','C2, C3','ML, DAA','Dr. Kale, Dr. Joshi','9800022222, 9800033333','B, A');

-- Task 2: the same facts in 1NF (one value per cell). Position i of every list belongs together.
INSERT INTO Student_Course_1NF VALUES
(101,'Aditya','C1','DBMS','Dr. Patil','9800011111','A'),
(101,'Aditya','C2','ML','Dr. Kale','9800022222','B'),
(102,'Neha','C1','DBMS','Dr. Patil','9800011111','A+'),
(103,'Omkar','C2','ML','Dr. Kale','9800022222','B'),
(103,'Omkar','C3','DAA','Dr. Joshi','9800033333','A');

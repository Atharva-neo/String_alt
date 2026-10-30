-- Experiment 3C - sample data from the PDF
USE norm_3c;
INSERT INTO Employee_Project_UNF VALUES
('E1','Ravi','D1','R&D','PR1','Chatbot',20,'Python, SQL'),
('E1','Ravi','D1','R&D','PR2','Vision',15,'Python, SQL'),
('E2','Sneha','D2','IT','PR1','Chatbot',30,'Java'),
('E3','Amol','D1','R&D','PR3','Analytics',25,'SQL, Tableau');

-- Task 1: each skill in its own row (cross product of the project rows and the employee's skill list)
INSERT INTO EP_1NF VALUES
('E1','Ravi','D1','R&D','PR1','Chatbot',20,'Python'),
('E1','Ravi','D1','R&D','PR1','Chatbot',20,'SQL'),
('E1','Ravi','D1','R&D','PR2','Vision',15,'Python'),
('E1','Ravi','D1','R&D','PR2','Vision',15,'SQL'),
('E2','Sneha','D2','IT','PR1','Chatbot',30,'Java'),
('E3','Amol','D1','R&D','PR3','Analytics',25,'SQL'),
('E3','Amol','D1','R&D','PR3','Analytics',25,'Tableau');

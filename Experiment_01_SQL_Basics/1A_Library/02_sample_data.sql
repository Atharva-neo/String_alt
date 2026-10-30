-- Experiment 1A - sample data exactly as given in the PDF (Task 3, valid part)
USE library_1a;

INSERT INTO Book (book_id, title, author, price, copies) VALUES
('B101', 'Database System Concepts', 'Korth',    850, 5),
('B102', 'Fundamentals of DBMS',      'Navathe',  720, 3),
('B103', 'Let Us C',                  'Kanetkar', 350, 8),
('B104', 'Python Crash Course',       'Matthes',  600, 4);

INSERT INTO Member (member_id, name, dept, phone) VALUES
('M01', 'Riya Patil',    'AIML', '9822011111'),
('M02', 'Amit Kulkarni', 'CSE',  '9822022222'),
('M03', 'Sneha Jadhav',  'ENTC', '9822033333');

INSERT INTO Issue (issue_id, book_id, member_id, issue_date, return_date) VALUES
(1, 'B101', 'M01', '2026-10-01', '2026-10-10'),
(2, 'B103', 'M02', '2026-10-05', NULL),
(3, 'B104', 'M01', '2026-10-12', NULL);

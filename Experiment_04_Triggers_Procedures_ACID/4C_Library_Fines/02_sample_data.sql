-- Experiment 4C - sample data from the PDF
USE library_4c;
INSERT INTO Book VALUES ('B1','DBMS',2), ('B2','ML',1), ('B3','DAA',0);
INSERT INTO Issue (issue_id, book_id, member, issue_date, due_date, return_date, fine) VALUES
(1,'B1','Riya','2026-10-01','2026-10-15',NULL,0),
(2,'B2','Amit','2026-10-05','2026-10-19',NULL,0);

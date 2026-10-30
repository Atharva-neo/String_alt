-- Experiment 3A - additional examiner-style queries (run after 03)
USE norm_3a;

-- ### ADV 1: Faculty-wise student count
SELECT f.Faculty, COUNT(e.RollNo) AS students FROM Faculty f LEFT JOIN Course c ON c.Faculty = f.Faculty LEFT JOIN Enrolment e ON e.CourseID = c.CourseID GROUP BY f.Faculty;

-- ### ADV 2: The update anomaly is gone - change Dr. Kale's phone once
-- One UPDATE on Faculty changes the phone for every course and student, and the re-join shows a consistent value.
START TRANSACTION;
UPDATE Faculty SET FacultyPhone = '9811122222' WHERE Faculty = 'Dr. Kale';
SELECT DISTINCT Faculty, FacultyPhone FROM rejoined WHERE Faculty = 'Dr. Kale';
ROLLBACK;

-- ### ADV 3: The insert anomaly is gone - a new course with no students
INSERT INTO Faculty VALUES ('Dr. Mane', '9800044444');
INSERT INTO Course VALUES ('C4', 'AI', 'Dr. Mane');
SELECT * FROM Course;

-- ### ADV 4: The delete anomaly is gone - remove Omkar's C3 enrolment and keep the course
START TRANSACTION;
DELETE FROM Enrolment WHERE RollNo = 103 AND CourseID = 'C3';
SELECT * FROM Course WHERE CourseID = 'C3';
ROLLBACK;

-- ### ADV 5: Referential integrity - enrol in a non-existent course
-- Error 1452.
INSERT INTO Enrolment VALUES (101, 'C9', 'A');

-- ### ADV 6: Students with their average grade points (A+=10, A=9, B=8)
SELECT s.Name, AVG(CASE e.Grade WHEN 'A+' THEN 10 WHEN 'A' THEN 9 WHEN 'B' THEN 8 ELSE 0 END) AS avg_points FROM Student s JOIN Enrolment e USING (RollNo) GROUP BY s.RollNo, s.Name;

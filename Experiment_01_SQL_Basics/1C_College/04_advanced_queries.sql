-- Experiment 1C - additional examiner-style queries
USE college_1c;

-- ### ADV 1: Courses with number of enrolled students (including courses with none)
SELECT c.course_id, c.course_name, COUNT(e.roll_no) AS enrolled FROM Course c LEFT JOIN Enrolment e USING (course_id) GROUP BY c.course_id, c.course_name;

-- ### ADV 2: Students enrolled in no course
-- NOT EXISTS anti-join: priya (104) has no enrolment.
SELECT s.roll_no, s.name FROM Student s WHERE NOT EXISTS (SELECT 1 FROM Enrolment e WHERE e.roll_no = s.roll_no);

-- ### ADV 3: Total credits per student
SELECT s.name, SUM(c.credits) AS total_credits FROM Student s JOIN Enrolment e USING (roll_no) JOIN Course c USING (course_id) GROUP BY s.roll_no, s.name;

-- ### ADV 4: Duplicate enrolment (composite PK violation)
-- (101, C101) already exists -> error 1062.
INSERT INTO Enrolment VALUES (101, 'C101');

-- ### ADV 5: Student of an unknown department
-- Error 1452 because D9 does not exist.
INSERT INTO Student VALUES (110, 'Ghost', 'D9', 1, 7.0);

-- ### ADV 6: Highest cgpa student in each department
SELECT d.dept_name, s.name, s.cgpa FROM Student s JOIN Department d USING (dept_id)
WHERE s.cgpa = (SELECT MAX(cgpa) FROM Student x WHERE x.dept_id = s.dept_id);

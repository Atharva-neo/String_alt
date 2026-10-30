-- Experiment 1C - College : implementation of the 12 tasks
/* @CONCEPTS
* **Composite primary key** `(roll_no, course_id)` makes the pair unique and implements the M:N relationship.
* **ON DELETE CASCADE** deletes child rows automatically when the parent row is deleted; the default (RESTRICT) blocks the delete.
* MySQL cannot "modify" an FK: drop it (`DROP FOREIGN KEY name`) and add it again with the new action.
* `RENAME COLUMN` is MySQL 8.0 syntax (Oracle: `ALTER TABLE t RENAME COLUMN a TO b`).
* A user with only SELECT may read; any write gives error 1142.
*/

-- ### TASK 1: ER diagram (entities, attributes, cardinality, M:N Enrolment)
-- See 06_explanation.md. Student M:N Course is resolved by Enrolment(roll_no, course_id).
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'college_1c' ORDER BY table_name, constraint_type;

-- ### TASK 2: Tables with all constraints
-- CHECK (cgpa BETWEEN 0 AND 10) and CHECK (credits > 0) are stored with the table definition.
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'college_1c';

-- ### TASK 3: Insert data; student with cgpa 11 must fail
-- 11 is outside 0..10 so chk_student_cgpa is violated (error 3819).
SELECT * FROM Student;
INSERT INTO Student VALUES (105, 'Test Student', 'D1', 1, 11);

-- ### TASK 4: Add UNIQUE column email to Student, then drop it
-- Adding a UNIQUE column creates an index named after the column; DROP COLUMN removes the column and its index.
ALTER TABLE Student ADD COLUMN email VARCHAR(60) UNIQUE;
SHOW INDEX FROM Student WHERE Key_name = 'email';
ALTER TABLE Student DROP COLUMN email;
DESCRIBE Student;

-- ### TASK 5: Increase year of all D1 students by 1
-- 101 and 102 move from year 2 to year 3.
UPDATE Student SET year = year + 1 WHERE dept_id = 'D1';
SELECT roll_no, name, dept_id, year FROM Student;

-- ### TASK 6: Students enrolled in DBMS
-- Three-table join Student -> Enrolment -> Course filtered on the course name: Aditya and Neha.
SELECT s.roll_no, s.name FROM Student s
JOIN Enrolment e ON e.roll_no = s.roll_no
JOIN Course c ON c.course_id = e.course_id
WHERE c.course_name = 'DBMS';

-- ### TASK 7: Number of students in each department
-- LEFT JOIN keeps departments with zero students (none here, since every department has one) and COUNT(student column) ignores NULLs.
SELECT d.dept_name, COUNT(s.roll_no) AS students FROM Department d LEFT JOIN Student s ON s.dept_id = d.dept_id GROUP BY d.dept_id, d.dept_name;

-- ### TASK 8: Students with cgpa above 8 in AIML
-- Aditya (8.4) and Neha (9.1) satisfy dept = AIML and cgpa > 8.
SELECT s.roll_no, s.name, s.cgpa FROM Student s JOIN Department d ON d.dept_id = s.dept_id WHERE d.dept_name = 'AIML' AND s.cgpa > 8;

-- ### TASK 9: Delete course C201 - error first, then recreate FK with ON DELETE CASCADE and delete again
-- C201 is referenced by Enrolment (103, C201) -> error 1451. After the FK is recreated with CASCADE the enrolment row is removed with the course.
DELETE FROM Course WHERE course_id = 'C201';
ALTER TABLE Enrolment DROP FOREIGN KEY fk_enr_course;
ALTER TABLE Enrolment ADD CONSTRAINT fk_enr_course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE;
DELETE FROM Course WHERE course_id = 'C201';
SELECT * FROM Course;
SELECT * FROM Enrolment;

-- ### TASK 10: Rename column hod to head_of_dept
ALTER TABLE Department RENAME COLUMN hod TO head_of_dept;
SELECT * FROM Department;

-- ### TASK 11: User faculty1 with SELECT on Student; log in as faculty1 and try an UPDATE
-- SELECT works; UPDATE gives ERROR 1142 (UPDATE command denied).
DROP USER IF EXISTS 'faculty1'@'localhost';
CREATE USER 'faculty1'@'localhost' IDENTIFIED BY 'Fac@12345';
GRANT SELECT ON college_1c.Student TO 'faculty1'@'localhost';
SHOW GRANTS FOR 'faculty1'@'localhost';
-- @as faculty1 Fac@12345
-- | SELECT roll_no, name, cgpa FROM Student;
-- | UPDATE Student SET cgpa = 9.9 WHERE roll_no = 101;

-- ### TASK 12: REVOKE SELECT from faculty1 and DROP the user
REVOKE SELECT ON college_1c.Student FROM 'faculty1'@'localhost';
SHOW GRANTS FOR 'faculty1'@'localhost';
DROP USER 'faculty1'@'localhost';
SELECT user, host FROM mysql.user WHERE user = 'faculty1';

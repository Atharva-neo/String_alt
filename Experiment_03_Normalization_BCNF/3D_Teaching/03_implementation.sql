-- Experiment 3D - Teaching (3NF but not BCNF) : 12 tasks
/* @CONCEPTS
* **Prime attribute** = member of some candidate key. 3NF allows `X -> A` when A is prime; **BCNF does not** - X must be a superkey.
* Here {Student, Subject} and {Student, Teacher} are both keys, so all three attributes are prime => 2NF and 3NF hold trivially. Teacher -> Subject has a non-key determinant => BCNF fails.
* BCNF decomposition is always lossless, but it may **lose a functional dependency**: {Student, Subject} -> Teacher can no longer be enforced inside one table.
*/

-- ### TASK 1: All candidate keys
-- {Student,Subject}+ = all; {Student,Teacher}+ = {Student,Teacher,Subject} (Teacher -> Subject) = all; {Student}+, {Subject,Teacher}+ are not.
-- Candidate keys: {Student, Subject} and {Student, Teacher}. Data check: both pairs are unique over the 5 rows.
SELECT COUNT(*) AS rows_, COUNT(DISTINCT Student, Subject) AS pairs_student_subject, COUNT(DISTINCT Student, Teacher) AS pairs_student_teacher FROM Teaching;

-- ### TASK 2: Prime and non-prime attributes
-- Prime: Student, Subject, Teacher (each belongs to a candidate key). Non-prime: none.
SELECT 'Student' AS attribute, 'prime (in both keys)' AS status UNION ALL SELECT 'Subject', 'prime (in {Student,Subject})' UNION ALL SELECT 'Teacher', 'prime (in {Student,Teacher})';

-- ### TASK 3: 2NF and 3NF with justification
-- 2NF: needs a non-prime attribute depending on part of a key - there are no non-prime attributes, so 2NF holds. 3NF: every attribute is prime, so
-- the 3NF condition "dependent attribute is prime" is satisfied for Teacher -> Subject (Subject is prime). Hence the relation is in 3NF.
-- Check that the FD Teacher -> Subject holds on the data (empty = holds):
SELECT Teacher FROM Teaching GROUP BY Teacher HAVING COUNT(DISTINCT Subject) > 1;

-- ### TASK 4: Prove the relation violates BCNF
-- Teacher -> Subject is non-trivial and Teacher+ = {Teacher, Subject} is not all attributes, so Teacher is not a superkey. Consequence (redundancy):
-- the fact 'Prof. Kale teaches DBMS' is stored once for every student of Kale.
SELECT Teacher, Subject, COUNT(*) AS times_the_fact_is_stored FROM Teaching GROUP BY Teacher, Subject;

-- ### TASK 5: Update anomaly when Prof. Kale switches subject
-- Kale switches from DBMS to DAA. All rows of Kale must change (2 rows); updating only one leaves Kale teaching two subjects, breaking Teacher -> Subject.
START TRANSACTION;
UPDATE Teaching SET Subject = 'DAA' WHERE Student = 'Asha' AND Teacher = 'Prof. Kale';
SELECT Teacher, COUNT(DISTINCT Subject) AS subjects_taught FROM Teaching WHERE Teacher = 'Prof. Kale' GROUP BY Teacher;
SELECT * FROM Teaching WHERE Teacher = 'Prof. Kale';
ROLLBACK;

-- ### TASK 6: Decompose into BCNF
-- Take the violating FD Teacher -> Subject: R1(Teacher, Subject) with key Teacher and R2(Student, Teacher) = R minus the dependent attribute.
CREATE TABLE Teacher_Subject_tmp AS SELECT DISTINCT Teacher, Subject FROM Teaching;
CREATE TABLE Student_Teacher_tmp AS SELECT DISTINCT Student, Teacher FROM Teaching;
SELECT * FROM Teacher_Subject_tmp ORDER BY Teacher; SELECT * FROM Student_Teacher_tmp ORDER BY Student, Teacher;

-- ### TASK 7: Is the decomposition lossless?
-- Yes: R1 ∩ R2 = {Teacher}, and Teacher is a key of R1 (Teacher -> Subject). Proof on data: the natural join returns exactly the 5 original rows.
SELECT COUNT(*) AS joined_rows,
       SUM(NOT EXISTS (SELECT 1 FROM Teaching t WHERE t.Student = st.Student AND t.Teacher = st.Teacher AND t.Subject = ts.Subject)) AS spurious_rows
FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher;
SELECT COUNT(*) AS original_rows_missing FROM Teaching t WHERE NOT EXISTS
  (SELECT 1 FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher WHERE st.Student = t.Student AND ts.Subject = t.Subject AND st.Teacher = t.Teacher);
DROP TABLE Teacher_Subject_tmp, Student_Teacher_tmp;

-- ### TASK 8: Is it dependency preserving? Which FD is lost?
-- The FD {Student, Subject} -> Teacher spans both tables (Student only in R2, Subject only in R1) so no table can enforce it.
-- Demonstration (after Task 9 the tables exist): Asha can be given a second DBMS teacher, which the old table forbade (PK Student, Subject).
-- See the "lost dependency" demo in ADV 1. Python proof: fd_analysis.py => 'Dependency preserving : False, lost: {Student, Subject}->{Teacher}'.
SELECT '{Student, Subject} -> Teacher is NOT preserved by the BCNF decomposition' AS conclusion;

-- ### TASK 9: Create the BCNF tables in SQL
CREATE TABLE Teacher_Subject (
    Teacher VARCHAR(30) NOT NULL PRIMARY KEY,
    Subject VARCHAR(30) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Student_Teacher (
    Student VARCHAR(30) NOT NULL,
    Teacher VARCHAR(30) NOT NULL,
    PRIMARY KEY (Student, Teacher),
    CONSTRAINT fk_st_teacher FOREIGN KEY (Teacher) REFERENCES Teacher_Subject(Teacher)
) ENGINE=InnoDB;
SHOW TABLES;

-- ### TASK 10: Insert the data into them
INSERT INTO Teacher_Subject SELECT DISTINCT Teacher, Subject FROM Teaching;
INSERT INTO Student_Teacher SELECT DISTINCT Student, Teacher FROM Teaching;
SELECT * FROM Teacher_Subject ORDER BY Teacher;
SELECT * FROM Student_Teacher ORDER BY Student, Teacher;

-- ### TASK 11: JOIN that lists each student, subject and teacher
SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) ORDER BY st.Student, ts.Subject;

-- ### TASK 12: Teachers with the number of students they teach
-- Kale 2 (Asha, Bhushan), Joshi 2 (Asha, Chetan), Mane 1 (Chetan).
SELECT ts.Teacher, ts.Subject, COUNT(st.Student) AS students FROM Teacher_Subject ts LEFT JOIN Student_Teacher st USING (Teacher) GROUP BY ts.Teacher, ts.Subject ORDER BY students DESC, ts.Teacher;

-- Experiment 3D - additional examiner-style queries (run after 03)
USE norm_3d;

-- ### ADV 1: The lost dependency {Student, Subject} -> Teacher in action
-- The decomposed schema happily accepts a second DBMS teacher (Prof. Mane) for Asha, which the original PK (Student, Subject) would have rejected.
-- The violation is only visible after a join (two teachers for one student+subject). This is the price of BCNF.
START TRANSACTION;
INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Mane');
SELECT st.Student, ts.Subject, COUNT(*) AS teachers FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) GROUP BY st.Student, ts.Subject HAVING COUNT(*) > 1;
ROLLBACK;

-- ### ADV 2: The same insert on the original relation is rejected
-- Error 1062 on (Student, Subject): the old design enforced the FD.
INSERT INTO Teaching VALUES ('Asha', 'DBMS', 'Prof. Mane');

-- ### ADV 3: Kale switches subject - ONE row update in the BCNF design
START TRANSACTION;
UPDATE Teacher_Subject SET Subject = 'DAA' WHERE Teacher = 'Prof. Kale';
SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) WHERE st.Teacher = 'Prof. Kale';
ROLLBACK;

-- ### ADV 4: A teacher without students can now be stored
INSERT INTO Teacher_Subject VALUES ('Prof. Rao', 'DAA');
SELECT * FROM Teacher_Subject;

-- ### ADV 5: Students taking more than one subject
SELECT st.Student, COUNT(*) AS subjects FROM Student_Teacher st GROUP BY st.Student HAVING COUNT(*) > 1;

-- ### ADV 6: Student of an unknown teacher
-- Error 1452.
INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Nobody');

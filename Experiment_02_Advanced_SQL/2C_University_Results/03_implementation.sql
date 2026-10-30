-- Experiment 2C - University results : 12 tasks
/* @CONCEPTS
* `> ALL (subquery)` compares with the maximum, `> ANY (subquery)` with the minimum of the subquery result.
* Topper-per-group: join to a MAX() derived table, or use `RANK() OVER (PARTITION BY ...)`.
* `SUM(marks < 40)` counts rows because a true comparison evaluates to 1 in MySQL (Oracle: `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`).
* A multi-table view is updatable if one UPDATE touches columns of **one** base table only; `WITH CHECK OPTION` stops rows from leaving the view.
*/

-- ### TASK 1: Student name, subject name and marks
SELECT s.name, sub.sub_name, m.marks FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY s.roll_no, sub.sub_id;

-- ### TASK 2: Each student's total and average marks
-- Esha has only one subject, so total = average = 67. Average is over subjects actually taken.
SELECT s.name, SUM(m.marks) AS total, ROUND(AVG(m.marks),2) AS average FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name ORDER BY total DESC;

-- ### TASK 3: Students who scored more than ALL AIML students in DBMS
-- AIML DBMS marks are 78 and 35; "> ALL" means > 78, so only Chetan (91) qualifies.
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ALL (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'AIML' AND m2.sub_id = 'S1');

-- ### TASK 4: Students who scored more than ANY CSE student in DBMS
-- CSE DBMS marks are 91 and 55; "> ANY" means > 55 (the minimum): Asha 78, Esha 67 and Chetan 91 (more than Divya's 55).
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ANY (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'CSE' AND m2.sub_id = 'S1');

-- ### TASK 5: Subject-wise average, highest and lowest marks
SELECT sub.sub_name, ROUND(AVG(m.marks),2) AS avg_marks, MAX(m.marks) AS highest, MIN(m.marks) AS lowest
FROM Marks m JOIN Subject sub USING (sub_id) GROUP BY sub.sub_id, sub.sub_name;

-- ### TASK 6: Topper's name for each subject
-- Derived table gives MAX(marks) per subject; joining back returns the student(s) holding it (ties would both show).
SELECT sub.sub_name, s.name AS topper, m.marks
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id)
JOIN (SELECT sub_id, MAX(marks) AS mx FROM Marks GROUP BY sub_id) t ON t.sub_id = m.sub_id AND t.mx = m.marks;

-- ### TASK 7: Department-wise average marks having average > 60
-- AIML (78+85+35+62)/4 = 65, CSE (91+74+55+38)/4 = 64.5, ENTC 67. All three exceed 60.
SELECT s.dept, ROUND(AVG(m.marks),2) AS avg_marks FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.dept HAVING AVG(m.marks) > 60;

-- ### TASK 8: Number of students who failed (marks < 40) in each subject
-- LEFT JOIN-free version: SUM of a boolean. DBMS: Bhushan(35); ML: none; DAA: Divya(38).
SELECT sub.sub_name, SUM(m.marks < 40) AS failed FROM Subject sub LEFT JOIN Marks m USING (sub_id) GROUP BY sub.sub_id, sub.sub_name;

-- ### TASK 9: Students who appeared for DBMS but not for ML (NOT IN)
SELECT s.roll_no, s.name FROM Student s
WHERE s.roll_no IN (SELECT roll_no FROM Marks WHERE sub_id = 'S1') AND s.roll_no NOT IN (SELECT roll_no FROM Marks WHERE sub_id = 'S2');

-- ### TASK 10: Students who appeared in more than one subject
SELECT s.roll_no, s.name, COUNT(*) AS subjects FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(*) > 1;

-- ### TASK 11: Rank students by DBMS marks (ORDER BY and RANK())
-- RANK() leaves gaps after ties; no ties here so ranks are 1..5.
SELECT s.name, m.marks, RANK() OVER (ORDER BY m.marks DESC) AS dbms_rank FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1' ORDER BY dbms_rank;

-- ### TASK 12: View below_40 and UPDATE marks through it
-- The join view is updatable for marks (single base table Marks). Raising Bhushan's DBMS marks to 45 succeeds, and the row then vanishes from the view
-- because it no longer satisfies marks < 40 (no CHECK OPTION). Changing columns of two tables at once fails (error 1393).
-- With WITH CHECK OPTION the same UPDATE is rejected (error 1369). Everything runs inside a transaction that is rolled back.
CREATE VIEW below_40 AS
SELECT s.roll_no, s.name, sub.sub_name, m.marks FROM Marks m JOIN Student s ON s.roll_no = m.roll_no JOIN Subject sub ON sub.sub_id = m.sub_id WHERE m.marks < 40;
SELECT * FROM below_40;
START TRANSACTION;
UPDATE below_40 SET marks = 45 WHERE roll_no = 2;
SELECT * FROM below_40;
SELECT roll_no, sub_id, marks FROM Marks WHERE roll_no = 2 AND sub_id = 'S1';
UPDATE below_40 SET name = 'Bhushan K', marks = 39 WHERE roll_no = 2;
ROLLBACK;
CREATE VIEW below_40_chk AS SELECT roll_no, sub_id, marks FROM Marks WHERE marks < 40 WITH CHECK OPTION;
UPDATE below_40_chk SET marks = 45 WHERE roll_no = 2 AND sub_id = 'S1';
SELECT roll_no, sub_id, marks FROM Marks WHERE roll_no = 2 AND sub_id = 'S1';

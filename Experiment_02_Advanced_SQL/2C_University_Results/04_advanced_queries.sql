-- Experiment 2C - additional examiner-style queries
USE univ_2c;

-- ### ADV 1: Second highest DBMS mark
SELECT marks FROM Marks WHERE sub_id = 'S1' ORDER BY marks DESC LIMIT 1 OFFSET 1;

-- ### ADV 2: Result class per student (>=75 Distinction, >=40 on every subject Pass)
-- MIN(marks) < 40 means at least one failed subject.
SELECT s.name, ROUND(AVG(m.marks),1) AS avg_marks,
  CASE WHEN MIN(m.marks) < 40 THEN 'FAIL' WHEN AVG(m.marks) >= 75 THEN 'DISTINCTION' ELSE 'PASS' END AS result
FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name;

-- ### ADV 3: Students appearing in every subject (division via counts)
SELECT s.name FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(DISTINCT m.sub_id) = (SELECT COUNT(*) FROM Subject);

-- ### ADV 4: Subject-wise rank of every student (PARTITION BY)
SELECT sub.sub_name, s.name, m.marks, RANK() OVER (PARTITION BY m.sub_id ORDER BY m.marks DESC) AS rank_in_subject
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY sub.sub_id, rank_in_subject;

-- ### ADV 5: Marks above the subject maximum (CHECK would be needed) - show how to guard
-- The schema only checks marks >= 0, so 150 is accepted; this demonstrates a missing-constraint discussion point, rolled back.
START TRANSACTION;
INSERT INTO Marks VALUES (5, 'S2', 150);
SELECT * FROM Marks WHERE roll_no = 5;
ROLLBACK;

-- ### ADV 6: Negative marks
-- chk_marks rejects it with error 3819.
INSERT INTO Marks VALUES (5, 'S3', -5);

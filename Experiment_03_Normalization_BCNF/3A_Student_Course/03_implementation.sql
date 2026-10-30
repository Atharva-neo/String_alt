-- Experiment 3A - Student_Course : 12 tasks (analysis tasks are proven with SQL "FD-check" queries + fd_analysis.py)
/* @CONCEPTS
* **1NF**: every cell atomic, a key exists. **2NF**: 1NF + no partial dependency (non-key attribute depending on part of a composite key).
* **3NF**: 2NF + no transitive dependency (non-key -> non-key). **BCNF**: every determinant is a candidate key.
* **FD check in SQL**: `X -> Y` holds on the data iff `SELECT X FROM t GROUP BY X HAVING COUNT(DISTINCT Y) > 1` returns no rows.
* **Lossless join**: re-joining the decomposed tables gives back exactly the original rows (no spurious, no missing rows).
* Attribute closure and candidate keys are computed by `fd_analysis.py` (see the last section of 05_expected_output.md).
*/

-- ### TASK 1: Why is the given table not in 1NF?
-- Cells such as CourseID = 'C1, C2' hold several values (a repeating group), so the attributes are not atomic and RollNo alone cannot be used
-- to look up one course. The query finds every cell that contains a list.
SELECT * FROM Student_Course_UNF;
SELECT RollNo, CourseID, CourseName, Faculty, Grade FROM Student_Course_UNF WHERE CourseID LIKE '%,%' OR CourseName LIKE '%,%' OR Grade LIKE '%,%';

-- ### TASK 2: Convert to 1NF (one value per cell) - resulting rows
-- Each list element becomes its own row; the key becomes the composite (RollNo, CourseID). 5 rows replace 3.
SELECT * FROM Student_Course_1NF ORDER BY RollNo, CourseID;

-- ### TASK 3: One insert, one update and one delete anomaly in the 1NF table
-- INSERT anomaly: a new course C4 with a faculty cannot be stored until a student takes it (RollNo is part of the PK) -> error 1048.
-- UPDATE anomaly: Dr. Kale's phone is stored twice; changing only one row leaves two different phones (inconsistency).
-- DELETE anomaly: Omkar is the only student of C3; deleting his row also erases the fact that C3 = DAA taught by Dr. Joshi.
INSERT INTO Student_Course_1NF (RollNo, Name, CourseID, CourseName, Faculty, FacultyPhone, Grade) VALUES (NULL, NULL, 'C4', 'AI', 'Dr. Mane', '9800044444', 'A');
START TRANSACTION;
UPDATE Student_Course_1NF SET FacultyPhone = '9999999999' WHERE RollNo = 101 AND CourseID = 'C2';
SELECT Faculty, FacultyPhone, COUNT(*) AS rows_ FROM Student_Course_1NF WHERE Faculty = 'Dr. Kale' GROUP BY Faculty, FacultyPhone;
ROLLBACK;
START TRANSACTION;
DELETE FROM Student_Course_1NF WHERE RollNo = 103 AND CourseID = 'C3';
SELECT * FROM Student_Course_1NF WHERE CourseID = 'C3';
ROLLBACK;

-- ### TASK 4: Closure of {RollNo} and {RollNo, CourseID}
-- Using FDs RollNo->Name, CourseID->CourseName,Faculty, Faculty->FacultyPhone, {RollNo,CourseID}->Grade:
-- {RollNo}+ = {RollNo, Name};  {RollNo, CourseID}+ = all seven attributes (see fd_analysis.py output).
-- Proof on the data: each FD below holds iff its query returns an empty set.
SELECT 'RollNo->Name' AS violated_fd, RollNo FROM Student_Course_1NF GROUP BY RollNo HAVING COUNT(DISTINCT Name) > 1
UNION ALL SELECT 'CourseID->CourseName', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT CourseName) > 1
UNION ALL SELECT 'CourseID->Faculty', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT Faculty) > 1
UNION ALL SELECT 'Faculty->FacultyPhone', Faculty FROM Student_Course_1NF GROUP BY Faculty HAVING COUNT(DISTINCT FacultyPhone) > 1;

-- ### TASK 5: Candidate key using attribute closure
-- {RollNo}+ and {CourseID}+ are not the full set, {RollNo,CourseID}+ is, and no proper subset works => candidate key = {RollNo, CourseID}.
-- Data check: the pair is unique, a single column is not.
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT RollNo, CourseID) AS distinct_pairs, COUNT(DISTINCT RollNo) AS distinct_rollno, COUNT(DISTINCT CourseID) AS distinct_courseid FROM Student_Course_1NF;

-- ### TASK 6: Partial dependencies and decomposition to 2NF
-- Partial: RollNo->Name and CourseID->CourseName,Faculty (and FacultyPhone through Faculty); each depends on only part of the key.
-- 2NF tables: Student(RollNo, Name), Course_Faculty(CourseID, CourseName, Faculty, FacultyPhone), Enrolment(RollNo, CourseID, Grade).
CREATE TABLE Student_2NF        AS SELECT DISTINCT RollNo, Name FROM Student_Course_1NF;
CREATE TABLE Course_Faculty_2NF AS SELECT DISTINCT CourseID, CourseName, Faculty, FacultyPhone FROM Student_Course_1NF;
CREATE TABLE Enrolment_2NF      AS SELECT RollNo, CourseID, Grade FROM Student_Course_1NF;
SELECT * FROM Student_2NF; SELECT * FROM Course_Faculty_2NF; SELECT * FROM Enrolment_2NF;

-- ### TASK 7: Transitive dependency and decomposition to 3NF
-- CourseID -> Faculty -> FacultyPhone is transitive (Faculty is a non-key attribute determining another non-key attribute).
-- Split Course_Faculty into Course(CourseID, CourseName, Faculty) and Faculty(Faculty, FacultyPhone).
CREATE TABLE Faculty_3NF AS SELECT DISTINCT Faculty, FacultyPhone FROM Course_Faculty_2NF;
CREATE TABLE Course_3NF  AS SELECT DISTINCT CourseID, CourseName, Faculty FROM Course_Faculty_2NF;
SELECT * FROM Faculty_3NF; SELECT * FROM Course_3NF;
DROP TABLE Student_2NF, Course_Faculty_2NF, Enrolment_2NF, Faculty_3NF, Course_3NF;

-- ### TASK 8: Check every table for BCNF and justify
-- Student (determinant RollNo = key), Faculty (Faculty = key), Course (CourseID = key), Enrolment ({RollNo,CourseID} = key).
-- Every FD's left side is a candidate key of its own table, so all four tables are in BCNF. Python check: fd_analysis.py ("BCNF violations none").
SELECT 'see fd_analysis.py: every final relation has BCNF violations = none' AS conclusion;

-- ### TASK 9: Final tables with primary and foreign keys
CREATE TABLE Student (
    RollNo INT NOT NULL PRIMARY KEY,
    Name   VARCHAR(40) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Faculty (
    Faculty      VARCHAR(40) NOT NULL PRIMARY KEY,
    FacultyPhone VARCHAR(15) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Course (
    CourseID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    CourseName VARCHAR(40) NOT NULL,
    Faculty    VARCHAR(40) NOT NULL,
    CONSTRAINT fk_course_faculty FOREIGN KEY (Faculty) REFERENCES Faculty(Faculty)
) ENGINE=InnoDB;
CREATE TABLE Enrolment (
    RollNo   INT        NOT NULL,
    CourseID VARCHAR(5) NOT NULL,
    Grade    VARCHAR(3) NOT NULL,
    PRIMARY KEY (RollNo, CourseID),
    CONSTRAINT fk_enr_student FOREIGN KEY (RollNo)   REFERENCES Student(RollNo),
    CONSTRAINT fk_enr_course  FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
) ENGINE=InnoDB;
SHOW TABLES;

-- ### TASK 10: Insert the data into the normalised tables
-- Parents first (Student, Faculty), then Course, then Enrolment, so every FK has its parent row.
INSERT INTO Student  VALUES (101,'Aditya'), (102,'Neha'), (103,'Omkar');
INSERT INTO Faculty  VALUES ('Dr. Patil','9800011111'), ('Dr. Kale','9800022222'), ('Dr. Joshi','9800033333');
INSERT INTO Course   VALUES ('C1','DBMS','Dr. Patil'), ('C2','ML','Dr. Kale'), ('C3','DAA','Dr. Joshi');
INSERT INTO Enrolment VALUES (101,'C1','A'), (101,'C2','B'), (102,'C1','A+'), (103,'C2','B'), (103,'C3','A');
SELECT (SELECT COUNT(*) FROM Student) AS students, (SELECT COUNT(*) FROM Faculty) AS faculty, (SELECT COUNT(*) FROM Course) AS courses, (SELECT COUNT(*) FROM Enrolment) AS enrolments;

-- ### TASK 11: JOIN that reproduces the 1NF table (lossless join)
-- The four-way join returns exactly the 5 original rows. Both anti-join checks return 0 rows, i.e. nothing is lost and nothing spurious appears.
CREATE VIEW rejoined AS
SELECT s.RollNo, s.Name, c.CourseID, c.CourseName, f.Faculty, f.FacultyPhone, e.Grade
FROM Enrolment e JOIN Student s ON s.RollNo = e.RollNo JOIN Course c ON c.CourseID = e.CourseID JOIN Faculty f ON f.Faculty = c.Faculty;
SELECT * FROM rejoined ORDER BY RollNo, CourseID;
SELECT COUNT(*) AS missing_rows FROM Student_Course_1NF o WHERE NOT EXISTS
  (SELECT 1 FROM rejoined r WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade);
SELECT COUNT(*) AS spurious_rows FROM rejoined r WHERE NOT EXISTS
  (SELECT 1 FROM Student_Course_1NF o WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade);

-- ### TASK 12: Students taught by Dr. Kale with their grades (normalised tables)
-- Dr. Kale teaches C2 (ML): Aditya got B and Omkar got B.
SELECT s.Name, c.CourseName, e.Grade FROM Enrolment e JOIN Student s USING (RollNo) JOIN Course c USING (CourseID) WHERE c.Faculty = 'Dr. Kale';

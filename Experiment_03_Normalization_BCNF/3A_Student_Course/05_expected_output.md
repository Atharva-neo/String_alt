# Expected output - Experiment_03_Normalization_BCNF / 3A_Student_Course

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Why is the given table not in 1NF?

```sql
SELECT * FROM Student_Course_UNF;
SELECT RollNo, CourseID, CourseName, Faculty, Grade FROM Student_Course_UNF WHERE CourseID LIKE '%,%' OR CourseName LIKE '%,%' OR Grade LIKE '%,%';
```

**Output**

```text
SELECT * FROM Student_Course_UNF

+--------+--------+----------+------------+---------------------+------------------------+-------+
| RollNo | Name   | CourseID | CourseName | Faculty             | FacultyPhone           | Grade |
+--------+--------+----------+------------+---------------------+------------------------+-------+
|    101 | Aditya | C1, C2   | DBMS, ML   | Dr. Patil, Dr. Kale | 9800011111, 9800022222 | A, B  |
|    102 | Neha   | C1       | DBMS       | Dr. Patil           | 9800011111             | A+    |
|    103 | Omkar  | C2, C3   | ML, DAA    | Dr. Kale, Dr. Joshi | 9800022222, 9800033333 | B, A  |
+--------+--------+----------+------------+---------------------+------------------------+-------+
3 rows in set

SELECT RollNo, CourseID, CourseName, Faculty, Grade FROM Student_Course_UNF WHERE CourseID LIKE '%,%' OR CourseName LIKE '%,%' OR Grade LIKE '%,%'

+--------+----------+------------+---------------------+-------+
| RollNo | CourseID | CourseName | Faculty             | Grade |
+--------+----------+------------+---------------------+-------+
|    101 | C1, C2   | DBMS, ML   | Dr. Patil, Dr. Kale | A, B  |
|    103 | C2, C3   | ML, DAA    | Dr. Kale, Dr. Joshi | B, A  |
+--------+----------+------------+---------------------+-------+
2 rows in set
```

**Why this output is correct:** Cells such as CourseID = 'C1, C2' hold several values (a repeating group), so the attributes are not atomic and RollNo alone cannot be used to look up one course. The query finds every cell that contains a list.

### Task 2 - Convert to 1NF (one value per cell) - resulting rows

```sql
SELECT * FROM Student_Course_1NF ORDER BY RollNo, CourseID;
```

**Output**

```text
SELECT * FROM Student_Course_1NF ORDER BY RollNo, CourseID

+--------+--------+----------+------------+-----------+--------------+-------+
| RollNo | Name   | CourseID | CourseName | Faculty   | FacultyPhone | Grade |
+--------+--------+----------+------------+-----------+--------------+-------+
|    101 | Aditya | C1       | DBMS       | Dr. Patil | 9800011111   | A     |
|    101 | Aditya | C2       | ML         | Dr. Kale  | 9800022222   | B     |
|    102 | Neha   | C1       | DBMS       | Dr. Patil | 9800011111   | A+    |
|    103 | Omkar  | C2       | ML         | Dr. Kale  | 9800022222   | B     |
|    103 | Omkar  | C3       | DAA        | Dr. Joshi | 9800033333   | A     |
+--------+--------+----------+------------+-----------+--------------+-------+
5 rows in set
```

**Why this output is correct:** Each list element becomes its own row; the key becomes the composite (RollNo, CourseID). 5 rows replace 3.

### Task 3 - One insert, one update and one delete anomaly in the 1NF table

```sql
INSERT INTO Student_Course_1NF (RollNo, Name, CourseID, CourseName, Faculty, FacultyPhone, Grade) VALUES (NULL, NULL, 'C4', 'AI', 'Dr. Mane', '9800044444', 'A');
START TRANSACTION;
UPDATE Student_Course_1NF SET FacultyPhone = '9999999999' WHERE RollNo = 101 AND CourseID = 'C2';
SELECT Faculty, FacultyPhone, COUNT(*) AS rows_ FROM Student_Course_1NF WHERE Faculty = 'Dr. Kale' GROUP BY Faculty, FacultyPhone;
ROLLBACK;
START TRANSACTION;
DELETE FROM Student_Course_1NF WHERE RollNo = 103 AND CourseID = 'C3';
SELECT * FROM Student_Course_1NF WHERE CourseID = 'C3';
ROLLBACK;
```

**Output**

```text
INSERT INTO Student_Course_1NF (RollNo, Name, CourseID, CourseName, Faculty, FacultyPhone, Grade) VALUES (NULL, NULL, 'C4', 'AI', 'Dr. Mane', '9800044444', 'A')

ERROR 1048 (23000) at line 1: Column 'RollNo' cannot be null
START TRANSACTION

Query OK, 0 rows affected

UPDATE Student_Course_1NF SET FacultyPhone = '9999999999' WHERE RollNo = 101 AND CourseID = 'C2'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT Faculty, FacultyPhone, COUNT(*) AS rows_ FROM Student_Course_1NF WHERE Faculty = 'Dr. Kale' GROUP BY Faculty, FacultyPhone

+----------+--------------+-------+
| Faculty  | FacultyPhone | rows_ |
+----------+--------------+-------+
| Dr. Kale | 9999999999   |     1 |
| Dr. Kale | 9800022222   |     1 |
+----------+--------------+-------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected

START TRANSACTION

Query OK, 0 rows affected

DELETE FROM Student_Course_1NF WHERE RollNo = 103 AND CourseID = 'C3'

Query OK, 1 row affected

SELECT * FROM Student_Course_1NF WHERE CourseID = 'C3'

Empty set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** INSERT anomaly: a new course C4 with a faculty cannot be stored until a student takes it (RollNo is part of the PK) -> error 1048. UPDATE anomaly: Dr. Kale's phone is stored twice; changing only one row leaves two different phones (inconsistency). DELETE anomaly: Omkar is the only student of C3; deleting his row also erases the fact that C3 = DAA taught by Dr. Joshi.

### Task 4 - Closure of {RollNo} and {RollNo, CourseID}

```sql
SELECT 'RollNo->Name' AS violated_fd, RollNo FROM Student_Course_1NF GROUP BY RollNo HAVING COUNT(DISTINCT Name) > 1
UNION ALL SELECT 'CourseID->CourseName', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT CourseName) > 1
UNION ALL SELECT 'CourseID->Faculty', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT Faculty) > 1
UNION ALL SELECT 'Faculty->FacultyPhone', Faculty FROM Student_Course_1NF GROUP BY Faculty HAVING COUNT(DISTINCT FacultyPhone) > 1;
```

**Output**

```text
SELECT 'RollNo->Name' AS violated_fd, RollNo FROM Student_Course_1NF GROUP BY RollNo HAVING COUNT(DISTINCT Name) > 1
UNION ALL SELECT 'CourseID->CourseName', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT CourseName) > 1
UNION ALL SELECT 'CourseID->Faculty', CourseID FROM Student_Course_1NF GROUP BY CourseID HAVING COUNT(DISTINCT Faculty) > 1
UNION ALL SELECT 'Faculty->FacultyPhone', Faculty FROM Student_Course_1NF GROUP BY Faculty HAVING COUNT(DISTINCT FacultyPhone) > 1

Empty set
```

**Why this output is correct:** Using FDs RollNo->Name, CourseID->CourseName,Faculty, Faculty->FacultyPhone, {RollNo,CourseID}->Grade: {RollNo}+ = {RollNo, Name};  {RollNo, CourseID}+ = all seven attributes (see fd_analysis.py output). Proof on the data: each FD below holds iff its query returns an empty set.

### Task 5 - Candidate key using attribute closure

```sql
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT RollNo, CourseID) AS distinct_pairs, COUNT(DISTINCT RollNo) AS distinct_rollno, COUNT(DISTINCT CourseID) AS distinct_courseid FROM Student_Course_1NF;
```

**Output**

```text
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT RollNo, CourseID) AS distinct_pairs, COUNT(DISTINCT RollNo) AS distinct_rollno, COUNT(DISTINCT CourseID) AS distinct_courseid FROM Student_Course_1NF

+------------+----------------+-----------------+-------------------+
| total_rows | distinct_pairs | distinct_rollno | distinct_courseid |
+------------+----------------+-----------------+-------------------+
|          5 |              5 |               3 |                 3 |
+------------+----------------+-----------------+-------------------+
1 row in set
```

**Why this output is correct:** {RollNo}+ and {CourseID}+ are not the full set, {RollNo,CourseID}+ is, and no proper subset works => candidate key = {RollNo, CourseID}. Data check: the pair is unique, a single column is not.

### Task 6 - Partial dependencies and decomposition to 2NF

```sql
CREATE TABLE Student_2NF        AS SELECT DISTINCT RollNo, Name FROM Student_Course_1NF;
CREATE TABLE Course_Faculty_2NF AS SELECT DISTINCT CourseID, CourseName, Faculty, FacultyPhone FROM Student_Course_1NF;
CREATE TABLE Enrolment_2NF      AS SELECT RollNo, CourseID, Grade FROM Student_Course_1NF;
SELECT * FROM Student_2NF; SELECT * FROM Course_Faculty_2NF; SELECT * FROM Enrolment_2NF;
```

**Output**

```text
CREATE TABLE Student_2NF        AS SELECT DISTINCT RollNo, Name FROM Student_Course_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Course_Faculty_2NF AS SELECT DISTINCT CourseID, CourseName, Faculty, FacultyPhone FROM Student_Course_1NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Enrolment_2NF      AS SELECT RollNo, CourseID, Grade FROM Student_Course_1NF

Query OK, 5 rows affected
Records: 5  Duplicates: 0  Warnings: 0

SELECT * FROM Student_2NF

+--------+--------+
| RollNo | Name   |
+--------+--------+
|    101 | Aditya |
|    102 | Neha   |
|    103 | Omkar  |
+--------+--------+
3 rows in set

SELECT * FROM Course_Faculty_2NF

+----------+------------+-----------+--------------+
| CourseID | CourseName | Faculty   | FacultyPhone |
+----------+------------+-----------+--------------+
| C1       | DBMS       | Dr. Patil | 9800011111   |
| C2       | ML         | Dr. Kale  | 9800022222   |
| C3       | DAA        | Dr. Joshi | 9800033333   |
+----------+------------+-----------+--------------+
3 rows in set

SELECT * FROM Enrolment_2NF

+--------+----------+-------+
| RollNo | CourseID | Grade |
+--------+----------+-------+
|    101 | C1       | A     |
|    101 | C2       | B     |
|    102 | C1       | A+    |
|    103 | C2       | B     |
|    103 | C3       | A     |
+--------+----------+-------+
5 rows in set
```

**Why this output is correct:** Partial: RollNo->Name and CourseID->CourseName,Faculty (and FacultyPhone through Faculty); each depends on only part of the key. 2NF tables: Student(RollNo, Name), Course_Faculty(CourseID, CourseName, Faculty, FacultyPhone), Enrolment(RollNo, CourseID, Grade).

### Task 7 - Transitive dependency and decomposition to 3NF

```sql
CREATE TABLE Faculty_3NF AS SELECT DISTINCT Faculty, FacultyPhone FROM Course_Faculty_2NF;
CREATE TABLE Course_3NF  AS SELECT DISTINCT CourseID, CourseName, Faculty FROM Course_Faculty_2NF;
SELECT * FROM Faculty_3NF; SELECT * FROM Course_3NF;
DROP TABLE Student_2NF, Course_Faculty_2NF, Enrolment_2NF, Faculty_3NF, Course_3NF;
```

**Output**

```text
CREATE TABLE Faculty_3NF AS SELECT DISTINCT Faculty, FacultyPhone FROM Course_Faculty_2NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Course_3NF  AS SELECT DISTINCT CourseID, CourseName, Faculty FROM Course_Faculty_2NF

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

SELECT * FROM Faculty_3NF

+-----------+--------------+
| Faculty   | FacultyPhone |
+-----------+--------------+
| Dr. Patil | 9800011111   |
| Dr. Kale  | 9800022222   |
| Dr. Joshi | 9800033333   |
+-----------+--------------+
3 rows in set

SELECT * FROM Course_3NF

+----------+------------+-----------+
| CourseID | CourseName | Faculty   |
+----------+------------+-----------+
| C1       | DBMS       | Dr. Patil |
| C2       | ML         | Dr. Kale  |
| C3       | DAA        | Dr. Joshi |
+----------+------------+-----------+
3 rows in set

DROP TABLE Student_2NF, Course_Faculty_2NF, Enrolment_2NF, Faculty_3NF, Course_3NF

Query OK, 0 rows affected
```

**Why this output is correct:** CourseID -> Faculty -> FacultyPhone is transitive (Faculty is a non-key attribute determining another non-key attribute). Split Course_Faculty into Course(CourseID, CourseName, Faculty) and Faculty(Faculty, FacultyPhone).

### Task 8 - Check every table for BCNF and justify

```sql
SELECT 'see fd_analysis.py: every final relation has BCNF violations = none' AS conclusion;
```

**Output**

```text
SELECT 'see fd_analysis.py: every final relation has BCNF violations = none' AS conclusion

+---------------------------------------------------------------------+
| conclusion                                                          |
+---------------------------------------------------------------------+
| see fd_analysis.py: every final relation has BCNF violations = none |
+---------------------------------------------------------------------+
1 row in set
```

**Why this output is correct:** Student (determinant RollNo = key), Faculty (Faculty = key), Course (CourseID = key), Enrolment ({RollNo,CourseID} = key). Every FD's left side is a candidate key of its own table, so all four tables are in BCNF. Python check: fd_analysis.py ("BCNF violations none").

### Task 9 - Final tables with primary and foreign keys

```sql
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
```

**Output**

```text
CREATE TABLE Student (
    RollNo INT NOT NULL PRIMARY KEY,
    Name   VARCHAR(40) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Faculty (
    Faculty      VARCHAR(40) NOT NULL PRIMARY KEY,
    FacultyPhone VARCHAR(15) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Course (
    CourseID   VARCHAR(5)  NOT NULL PRIMARY KEY,
    CourseName VARCHAR(40) NOT NULL,
    Faculty    VARCHAR(40) NOT NULL,
    CONSTRAINT fk_course_faculty FOREIGN KEY (Faculty) REFERENCES Faculty(Faculty)
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Enrolment (
    RollNo   INT        NOT NULL,
    CourseID VARCHAR(5) NOT NULL,
    Grade    VARCHAR(3) NOT NULL,
    PRIMARY KEY (RollNo, CourseID),
    CONSTRAINT fk_enr_student FOREIGN KEY (RollNo)   REFERENCES Student(RollNo),
    CONSTRAINT fk_enr_course  FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
) ENGINE=InnoDB

Query OK, 0 rows affected

SHOW TABLES

+--------------------+
| Tables_in_norm_3a  |
+--------------------+
| course             |
| enrolment          |
| faculty            |
| student            |
| student_course_1nf |
| student_course_unf |
+--------------------+
6 rows in set
```

### Task 10 - Insert the data into the normalised tables

```sql
INSERT INTO Student  VALUES (101,'Aditya'), (102,'Neha'), (103,'Omkar');
INSERT INTO Faculty  VALUES ('Dr. Patil','9800011111'), ('Dr. Kale','9800022222'), ('Dr. Joshi','9800033333');
INSERT INTO Course   VALUES ('C1','DBMS','Dr. Patil'), ('C2','ML','Dr. Kale'), ('C3','DAA','Dr. Joshi');
INSERT INTO Enrolment VALUES (101,'C1','A'), (101,'C2','B'), (102,'C1','A+'), (103,'C2','B'), (103,'C3','A');
SELECT (SELECT COUNT(*) FROM Student) AS students, (SELECT COUNT(*) FROM Faculty) AS faculty, (SELECT COUNT(*) FROM Course) AS courses, (SELECT COUNT(*) FROM Enrolment) AS enrolments;
```

**Output**

```text
INSERT INTO Student  VALUES (101,'Aditya'), (102,'Neha'), (103,'Omkar')

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Faculty  VALUES ('Dr. Patil','9800011111'), ('Dr. Kale','9800022222'), ('Dr. Joshi','9800033333')

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Course   VALUES ('C1','DBMS','Dr. Patil'), ('C2','ML','Dr. Kale'), ('C3','DAA','Dr. Joshi')

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Enrolment VALUES (101,'C1','A'), (101,'C2','B'), (102,'C1','A+'), (103,'C2','B'), (103,'C3','A')

Query OK, 5 rows affected
Records: 5  Duplicates: 0  Warnings: 0

SELECT (SELECT COUNT(*) FROM Student) AS students, (SELECT COUNT(*) FROM Faculty) AS faculty, (SELECT COUNT(*) FROM Course) AS courses, (SELECT COUNT(*) FROM Enrolment) AS enrolments

+----------+---------+---------+------------+
| students | faculty | courses | enrolments |
+----------+---------+---------+------------+
|        3 |       3 |       3 |          5 |
+----------+---------+---------+------------+
1 row in set
```

**Why this output is correct:** Parents first (Student, Faculty), then Course, then Enrolment, so every FK has its parent row.

### Task 11 - JOIN that reproduces the 1NF table (lossless join)

```sql
CREATE VIEW rejoined AS
SELECT s.RollNo, s.Name, c.CourseID, c.CourseName, f.Faculty, f.FacultyPhone, e.Grade
FROM Enrolment e JOIN Student s ON s.RollNo = e.RollNo JOIN Course c ON c.CourseID = e.CourseID JOIN Faculty f ON f.Faculty = c.Faculty;
SELECT * FROM rejoined ORDER BY RollNo, CourseID;
SELECT COUNT(*) AS missing_rows FROM Student_Course_1NF o WHERE NOT EXISTS
  (SELECT 1 FROM rejoined r WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade);
SELECT COUNT(*) AS spurious_rows FROM rejoined r WHERE NOT EXISTS
  (SELECT 1 FROM Student_Course_1NF o WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade);
```

**Output**

```text
CREATE VIEW rejoined AS
SELECT s.RollNo, s.Name, c.CourseID, c.CourseName, f.Faculty, f.FacultyPhone, e.Grade
FROM Enrolment e JOIN Student s ON s.RollNo = e.RollNo JOIN Course c ON c.CourseID = e.CourseID JOIN Faculty f ON f.Faculty = c.Faculty

Query OK, 0 rows affected

SELECT * FROM rejoined ORDER BY RollNo, CourseID

+--------+--------+----------+------------+-----------+--------------+-------+
| RollNo | Name   | CourseID | CourseName | Faculty   | FacultyPhone | Grade |
+--------+--------+----------+------------+-----------+--------------+-------+
|    101 | Aditya | C1       | DBMS       | Dr. Patil | 9800011111   | A     |
|    101 | Aditya | C2       | ML         | Dr. Kale  | 9800022222   | B     |
|    102 | Neha   | C1       | DBMS       | Dr. Patil | 9800011111   | A+    |
|    103 | Omkar  | C2       | ML         | Dr. Kale  | 9800022222   | B     |
|    103 | Omkar  | C3       | DAA        | Dr. Joshi | 9800033333   | A     |
+--------+--------+----------+------------+-----------+--------------+-------+
5 rows in set

SELECT COUNT(*) AS missing_rows FROM Student_Course_1NF o WHERE NOT EXISTS
  (SELECT 1 FROM rejoined r WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade)

+--------------+
| missing_rows |
+--------------+
|            0 |
+--------------+
1 row in set

SELECT COUNT(*) AS spurious_rows FROM rejoined r WHERE NOT EXISTS
  (SELECT 1 FROM Student_Course_1NF o WHERE r.RollNo=o.RollNo AND r.CourseID=o.CourseID AND r.Name=o.Name AND r.CourseName=o.CourseName AND r.Faculty=o.Faculty AND r.FacultyPhone=o.FacultyPhone AND r.Grade=o.Grade)

+---------------+
| spurious_rows |
+---------------+
|             0 |
+---------------+
1 row in set
```

**Why this output is correct:** The four-way join returns exactly the 5 original rows. Both anti-join checks return 0 rows, i.e. nothing is lost and nothing spurious appears.

### Task 12 - Students taught by Dr. Kale with their grades (normalised tables)

```sql
SELECT s.Name, c.CourseName, e.Grade FROM Enrolment e JOIN Student s USING (RollNo) JOIN Course c USING (CourseID) WHERE c.Faculty = 'Dr. Kale';
```

**Output**

```text
SELECT s.Name, c.CourseName, e.Grade FROM Enrolment e JOIN Student s USING (RollNo) JOIN Course c USING (CourseID) WHERE c.Faculty = 'Dr. Kale'

+--------+------------+-------+
| Name   | CourseName | Grade |
+--------+------------+-------+
| Aditya | ML         | B     |
| Omkar  | ML         | B     |
+--------+------------+-------+
2 rows in set
```

**Why this output is correct:** Dr. Kale teaches C2 (ML): Aditya got B and Omkar got B.


## Advanced / examiner-style queries

### Adv 1 - Faculty-wise student count

```sql
SELECT f.Faculty, COUNT(e.RollNo) AS students FROM Faculty f LEFT JOIN Course c ON c.Faculty = f.Faculty LEFT JOIN Enrolment e ON e.CourseID = c.CourseID GROUP BY f.Faculty;
```

**Output**

```text
SELECT f.Faculty, COUNT(e.RollNo) AS students FROM Faculty f LEFT JOIN Course c ON c.Faculty = f.Faculty LEFT JOIN Enrolment e ON e.CourseID = c.CourseID GROUP BY f.Faculty

+-----------+----------+
| Faculty   | students |
+-----------+----------+
| Dr. Joshi |        1 |
| Dr. Kale  |        2 |
| Dr. Patil |        2 |
+-----------+----------+
3 rows in set
```

### Adv 2 - The update anomaly is gone - change Dr. Kale's phone once

```sql
START TRANSACTION;
UPDATE Faculty SET FacultyPhone = '9811122222' WHERE Faculty = 'Dr. Kale';
SELECT DISTINCT Faculty, FacultyPhone FROM rejoined WHERE Faculty = 'Dr. Kale';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Faculty SET FacultyPhone = '9811122222' WHERE Faculty = 'Dr. Kale'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT DISTINCT Faculty, FacultyPhone FROM rejoined WHERE Faculty = 'Dr. Kale'

+----------+--------------+
| Faculty  | FacultyPhone |
+----------+--------------+
| Dr. Kale | 9811122222   |
+----------+--------------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** One UPDATE on Faculty changes the phone for every course and student, and the re-join shows a consistent value.

### Adv 3 - The insert anomaly is gone - a new course with no students

```sql
INSERT INTO Faculty VALUES ('Dr. Mane', '9800044444');
INSERT INTO Course VALUES ('C4', 'AI', 'Dr. Mane');
SELECT * FROM Course;
```

**Output**

```text
INSERT INTO Faculty VALUES ('Dr. Mane', '9800044444')

Query OK, 1 row affected

INSERT INTO Course VALUES ('C4', 'AI', 'Dr. Mane')

Query OK, 1 row affected

SELECT * FROM Course

+----------+------------+-----------+
| CourseID | CourseName | Faculty   |
+----------+------------+-----------+
| C1       | DBMS       | Dr. Patil |
| C2       | ML         | Dr. Kale  |
| C3       | DAA        | Dr. Joshi |
| C4       | AI         | Dr. Mane  |
+----------+------------+-----------+
4 rows in set
```

### Adv 4 - The delete anomaly is gone - remove Omkar's C3 enrolment and keep the course

```sql
START TRANSACTION;
DELETE FROM Enrolment WHERE RollNo = 103 AND CourseID = 'C3';
SELECT * FROM Course WHERE CourseID = 'C3';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

DELETE FROM Enrolment WHERE RollNo = 103 AND CourseID = 'C3'

Query OK, 1 row affected

SELECT * FROM Course WHERE CourseID = 'C3'

+----------+------------+-----------+
| CourseID | CourseName | Faculty   |
+----------+------------+-----------+
| C3       | DAA        | Dr. Joshi |
+----------+------------+-----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 5 - Referential integrity - enrol in a non-existent course

```sql
INSERT INTO Enrolment VALUES (101, 'C9', 'A');
```

**Output**

```text
INSERT INTO Enrolment VALUES (101, 'C9', 'A')

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`norm_3a`.`enrolment`, CONSTRAINT `fk_enr_course` FOREIGN KEY (`CourseID`) REFERENCES `course` (`CourseID`))
```

**Why this output is correct:** Error 1452.

### Adv 6 - Students with their average grade points (A+=10, A=9, B=8)

```sql
SELECT s.Name, AVG(CASE e.Grade WHEN 'A+' THEN 10 WHEN 'A' THEN 9 WHEN 'B' THEN 8 ELSE 0 END) AS avg_points FROM Student s JOIN Enrolment e USING (RollNo) GROUP BY s.RollNo, s.Name;
```

**Output**

```text
SELECT s.Name, AVG(CASE e.Grade WHEN 'A+' THEN 10 WHEN 'A' THEN 9 WHEN 'B' THEN 8 ELSE 0 END) AS avg_points FROM Student s JOIN Enrolment e USING (RollNo) GROUP BY s.RollNo, s.Name

+--------+------------+
| Name   | avg_points |
+--------+------------+
| Aditya |     8.5000 |
| Neha   |    10.0000 |
| Omkar  |     8.5000 |
+--------+------------+
3 rows in set
```


## Functional-dependency analysis (Python, `fd_analysis.py`)

```text
=== 3A: 1NF relation Student_Course(RollNo, Name, CourseID, CourseName, Faculty, FacultyPhone, Grade) ===
Attributes : {CourseID, CourseName, Faculty, FacultyPhone, Grade, Name, RollNo}
FDs        : {RollNo} -> {Name}; {CourseID} -> {CourseName, Faculty}; {Faculty} -> {FacultyPhone}; {CourseID, RollNo} -> {Grade}
Closure {RollNo}+ = {Name, RollNo}
Closure {CourseID, RollNo}+ = {CourseID, CourseName, Faculty, FacultyPhone, Grade, Name, RollNo}
Candidate keys : {CourseID, RollNo}
Prime attributes : {CourseID, RollNo}
Partial dependencies (2NF violations) : {CourseID}->{CourseName, Faculty, FacultyPhone}; {RollNo}->{Name}
3NF violations : {CourseID}->{CourseName, Faculty, FacultyPhone}; {Faculty}->{FacultyPhone}; {RollNo}->{Name}
BCNF violations : {CourseID}->{CourseName, Faculty, FacultyPhone}; {Faculty}->{FacultyPhone}; {RollNo}->{Name}

=== 3A: after 2NF  (Student | Course_Faculty | Enrolment) ===
Attributes : {CourseID, CourseName, Faculty, FacultyPhone, Grade, Name, RollNo}
FDs        : {RollNo} -> {Name}; {CourseID} -> {CourseName, Faculty}; {Faculty} -> {FacultyPhone}; {CourseID, RollNo} -> {Grade}
Decomposition : {Name, RollNo} | {CourseID, CourseName, Faculty, FacultyPhone} | {CourseID, Grade, RollNo}
Lossless join : True
Dependency preserving : True 
  relation {Name, RollNo}: keys ['{RollNo}'], BCNF violations none
  relation {CourseID, CourseName, Faculty, FacultyPhone}: keys ['{CourseID}'], BCNF violations ['{Faculty}->{FacultyPhone}']
  relation {CourseID, Grade, RollNo}: keys ['{CourseID, RollNo}'], BCNF violations none

=== 3A: final 3NF = BCNF  (Student | Faculty | Course | Enrolment) ===
Attributes : {CourseID, CourseName, Faculty, FacultyPhone, Grade, Name, RollNo}
FDs        : {RollNo} -> {Name}; {CourseID} -> {CourseName, Faculty}; {Faculty} -> {FacultyPhone}; {CourseID, RollNo} -> {Grade}
Decomposition : {Name, RollNo} | {Faculty, FacultyPhone} | {CourseID, CourseName, Faculty} | {CourseID, Grade, RollNo}
Lossless join : True
Dependency preserving : True 
  relation {Name, RollNo}: keys ['{RollNo}'], BCNF violations none
  relation {Faculty, FacultyPhone}: keys ['{Faculty}'], BCNF violations none
  relation {CourseID, CourseName, Faculty}: keys ['{CourseID}'], BCNF violations none
  relation {CourseID, Grade, RollNo}: keys ['{CourseID, RollNo}'], BCNF violations none
```

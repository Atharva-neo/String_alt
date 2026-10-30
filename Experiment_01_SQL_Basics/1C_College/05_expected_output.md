# Expected output - Experiment_01_SQL_Basics / 1C_College

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - ER diagram (entities, attributes, cardinality, M:N Enrolment)

```sql
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'college_1c' ORDER BY table_name, constraint_type;
```

**Output**

```text
SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints
WHERE table_schema = 'college_1c' ORDER BY table_name, constraint_type

+------------+--------------------+-----------------+
| TABLE_NAME | CONSTRAINT_NAME    | CONSTRAINT_TYPE |
+------------+--------------------+-----------------+
| course     | chk_course_credits | CHECK           |
| course     | fk_course_dept     | FOREIGN KEY     |
| course     | PRIMARY            | PRIMARY KEY     |
| department | PRIMARY            | PRIMARY KEY     |
| department | dept_name          | UNIQUE          |
| enrolment  | fk_enr_course      | FOREIGN KEY     |
| enrolment  | fk_enr_student     | FOREIGN KEY     |
| enrolment  | PRIMARY            | PRIMARY KEY     |
| student    | chk_student_cgpa   | CHECK           |
| student    | fk_student_dept    | FOREIGN KEY     |
| student    | PRIMARY            | PRIMARY KEY     |
+------------+--------------------+-----------------+
11 rows in set
```

**Why this output is correct:** See 06_explanation.md. Student M:N Course is resolved by Enrolment(roll_no, course_id).

### Task 2 - Tables with all constraints

```sql
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'college_1c';
```

**Output**

```text
SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema = 'college_1c'

+--------------------+---------------------------+
| CONSTRAINT_NAME    | CHECK_CLAUSE              |
+--------------------+---------------------------+
| chk_course_credits | (`credits` > 0)           |
| chk_student_cgpa   | (`cgpa` between 0 and 10) |
+--------------------+---------------------------+
2 rows in set
```

**Why this output is correct:** CHECK (cgpa BETWEEN 0 AND 10) and CHECK (credits > 0) are stored with the table definition.

### Task 3 - Insert data; student with cgpa 11 must fail

```sql
SELECT * FROM Student;
INSERT INTO Student VALUES (105, 'Test Student', 'D1', 1, 11);
```

**Output**

```text
SELECT * FROM Student

+---------+----------------+---------+------+------+
| roll_no | name           | dept_id | year | cgpa |
+---------+----------------+---------+------+------+
|     101 | Aditya Pawar   | D1      |    2 |  8.4 |
|     102 | Neha Gaikwad   | D1      |    2 |  9.1 |
|     103 | Omkar Salunkhe | D2      |    3 |  7.2 |
|     104 | Priya Mane     | D3      |    1 |  6.8 |
+---------+----------------+---------+------+------+
4 rows in set

INSERT INTO Student VALUES (105, 'Test Student', 'D1', 1, 11)

ERROR 3819 (HY000) at line 2: Check constraint 'chk_student_cgpa' is violated.
```

**Why this output is correct:** 11 is outside 0..10 so chk_student_cgpa is violated (error 3819).

### Task 4 - Add UNIQUE column email to Student, then drop it

```sql
ALTER TABLE Student ADD COLUMN email VARCHAR(60) UNIQUE;
SHOW INDEX FROM Student WHERE Key_name = 'email';
ALTER TABLE Student DROP COLUMN email;
DESCRIBE Student;
```

**Output**

```text
ALTER TABLE Student ADD COLUMN email VARCHAR(60) UNIQUE

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

SHOW INDEX FROM Student WHERE Key_name = 'email'

+---------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table   | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+---------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| student |          0 | email    |            1 | email       | A         |           1 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+---------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
1 row in set

ALTER TABLE Student DROP COLUMN email

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

DESCRIBE Student

+---------+--------------+------+-----+---------+-------+
| Field   | Type         | Null | Key | Default | Extra |
+---------+--------------+------+-----+---------+-------+
| roll_no | int          | NO   | PRI | NULL    |       |
| name    | varchar(50)  | NO   |     | NULL    |       |
| dept_id | varchar(5)   | NO   | MUL | NULL    |       |
| year    | int          | NO   |     | 1       |       |
| cgpa    | decimal(3,1) | NO   |     | NULL    |       |
+---------+--------------+------+-----+---------+-------+
5 rows in set
```

**Why this output is correct:** Adding a UNIQUE column creates an index named after the column; DROP COLUMN removes the column and its index.

### Task 5 - Increase year of all D1 students by 1

```sql
UPDATE Student SET year = year + 1 WHERE dept_id = 'D1';
SELECT roll_no, name, dept_id, year FROM Student;
```

**Output**

```text
UPDATE Student SET year = year + 1 WHERE dept_id = 'D1'

Query OK, 2 rows affected
Rows matched: 2  Changed: 2  Warnings: 0

SELECT roll_no, name, dept_id, year FROM Student

+---------+----------------+---------+------+
| roll_no | name           | dept_id | year |
+---------+----------------+---------+------+
|     101 | Aditya Pawar   | D1      |    3 |
|     102 | Neha Gaikwad   | D1      |    3 |
|     103 | Omkar Salunkhe | D2      |    3 |
|     104 | Priya Mane     | D3      |    1 |
+---------+----------------+---------+------+
4 rows in set
```

**Why this output is correct:** 101 and 102 move from year 2 to year 3.

### Task 6 - Students enrolled in DBMS

```sql
SELECT s.roll_no, s.name FROM Student s
JOIN Enrolment e ON e.roll_no = s.roll_no
JOIN Course c ON c.course_id = e.course_id
WHERE c.course_name = 'DBMS';
```

**Output**

```text
SELECT s.roll_no, s.name FROM Student s
JOIN Enrolment e ON e.roll_no = s.roll_no
JOIN Course c ON c.course_id = e.course_id
WHERE c.course_name = 'DBMS'

+---------+--------------+
| roll_no | name         |
+---------+--------------+
|     101 | Aditya Pawar |
|     102 | Neha Gaikwad |
+---------+--------------+
2 rows in set
```

**Why this output is correct:** Three-table join Student -> Enrolment -> Course filtered on the course name: Aditya and Neha.

### Task 7 - Number of students in each department

```sql
SELECT d.dept_name, COUNT(s.roll_no) AS students FROM Department d LEFT JOIN Student s ON s.dept_id = d.dept_id GROUP BY d.dept_id, d.dept_name;
```

**Output**

```text
SELECT d.dept_name, COUNT(s.roll_no) AS students FROM Department d LEFT JOIN Student s ON s.dept_id = d.dept_id GROUP BY d.dept_id, d.dept_name

+------------+----------+
| dept_name  | students |
+------------+----------+
| AIML       |        2 |
| CSE        |        1 |
| Mechanical |        1 |
+------------+----------+
3 rows in set
```

**Why this output is correct:** LEFT JOIN keeps departments with zero students (none here, since every department has one) and COUNT(student column) ignores NULLs.

### Task 8 - Students with cgpa above 8 in AIML

```sql
SELECT s.roll_no, s.name, s.cgpa FROM Student s JOIN Department d ON d.dept_id = s.dept_id WHERE d.dept_name = 'AIML' AND s.cgpa > 8;
```

**Output**

```text
SELECT s.roll_no, s.name, s.cgpa FROM Student s JOIN Department d ON d.dept_id = s.dept_id WHERE d.dept_name = 'AIML' AND s.cgpa > 8

+---------+--------------+------+
| roll_no | name         | cgpa |
+---------+--------------+------+
|     101 | Aditya Pawar |  8.4 |
|     102 | Neha Gaikwad |  9.1 |
+---------+--------------+------+
2 rows in set
```

**Why this output is correct:** Aditya (8.4) and Neha (9.1) satisfy dept = AIML and cgpa > 8.

### Task 9 - Delete course C201 - error first, then recreate FK with ON DELETE CASCADE and delete again

```sql
DELETE FROM Course WHERE course_id = 'C201';
ALTER TABLE Enrolment DROP FOREIGN KEY fk_enr_course;
ALTER TABLE Enrolment ADD CONSTRAINT fk_enr_course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE;
DELETE FROM Course WHERE course_id = 'C201';
SELECT * FROM Course;
SELECT * FROM Enrolment;
```

**Output**

```text
DELETE FROM Course WHERE course_id = 'C201'

ERROR 1451 (23000) at line 1: Cannot delete or update a parent row: a foreign key constraint fails (`college_1c`.`enrolment`, CONSTRAINT `fk_enr_course` FOREIGN KEY (`course_id`) REFERENCES `course` (`course_id`))
ALTER TABLE Enrolment DROP FOREIGN KEY fk_enr_course

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

ALTER TABLE Enrolment ADD CONSTRAINT fk_enr_course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE

Query OK, 4 rows affected
Records: 4  Duplicates: 0  Warnings: 0

DELETE FROM Course WHERE course_id = 'C201'

Query OK, 1 row affected

SELECT * FROM Course

+-----------+------------------+---------+---------+
| course_id | course_name      | credits | dept_id |
+-----------+------------------+---------+---------+
| C101      | DBMS             |       4 | D1      |
| C102      | Machine Learning |       4 | D1      |
+-----------+------------------+---------+---------+
2 rows in set

SELECT * FROM Enrolment

+---------+-----------+
| roll_no | course_id |
+---------+-----------+
|     101 | C101      |
|     102 | C101      |
|     101 | C102      |
+---------+-----------+
3 rows in set
```

**Why this output is correct:** C201 is referenced by Enrolment (103, C201) -> error 1451. After the FK is recreated with CASCADE the enrolment row is removed with the course.

### Task 10 - Rename column hod to head_of_dept

```sql
ALTER TABLE Department RENAME COLUMN hod TO head_of_dept;
SELECT * FROM Department;
```

**Output**

```text
ALTER TABLE Department RENAME COLUMN hod TO head_of_dept

Query OK, 0 rows affected
Records: 0  Duplicates: 0  Warnings: 0

SELECT * FROM Department

+---------+------------+--------------+
| dept_id | dept_name  | head_of_dept |
+---------+------------+--------------+
| D1      | AIML       | Dr. Patil    |
| D2      | CSE        | Dr. Kale     |
| D3      | Mechanical | Dr. Joshi    |
+---------+------------+--------------+
3 rows in set
```

### Task 11 - User faculty1 with SELECT on Student; log in as faculty1 and try an UPDATE

```sql
DROP USER IF EXISTS 'faculty1'@'localhost';
CREATE USER 'faculty1'@'localhost' IDENTIFIED BY 'Fac@12345';
GRANT SELECT ON college_1c.Student TO 'faculty1'@'localhost';
SHOW GRANTS FOR 'faculty1'@'localhost';
-- @as faculty1 Fac@12345
-- | SELECT roll_no, name, cgpa FROM Student;
-- | UPDATE Student SET cgpa = 9.9 WHERE roll_no = 101;
```

**Output**

```text
DROP USER IF EXISTS 'faculty1'@'localhost'

Query OK, 0 rows affected, 1 warning

CREATE USER 'faculty1'@'localhost' IDENTIFIED BY 'Fac@12345'

Query OK, 0 rows affected

GRANT SELECT ON college_1c.Student TO 'faculty1'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'faculty1'@'localhost'

+------------------------------------------------------------------+
| Grants for faculty1@localhost                                    |
+------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `faculty1`@`localhost`                     |
| GRANT SELECT ON `college_1c`.`student` TO `faculty1`@`localhost` |
+------------------------------------------------------------------+
2 rows in set

[session: user 'faculty1']
SELECT roll_no, name, cgpa FROM Student

+---------+----------------+------+
| roll_no | name           | cgpa |
+---------+----------------+------+
|     101 | Aditya Pawar   |  8.4 |
|     102 | Neha Gaikwad   |  9.1 |
|     103 | Omkar Salunkhe |  7.2 |
|     104 | Priya Mane     |  6.8 |
+---------+----------------+------+
4 rows in set

UPDATE Student SET cgpa = 9.9 WHERE roll_no = 101

ERROR 1142 (42000) at line 2: UPDATE command denied to user 'faculty1'@'localhost' for table 'student'
```

**Why this output is correct:** SELECT works; UPDATE gives ERROR 1142 (UPDATE command denied).

### Task 12 - REVOKE SELECT from faculty1 and DROP the user

```sql
REVOKE SELECT ON college_1c.Student FROM 'faculty1'@'localhost';
SHOW GRANTS FOR 'faculty1'@'localhost';
DROP USER 'faculty1'@'localhost';
SELECT user, host FROM mysql.user WHERE user = 'faculty1';
```

**Output**

```text
REVOKE SELECT ON college_1c.Student FROM 'faculty1'@'localhost'

Query OK, 0 rows affected

SHOW GRANTS FOR 'faculty1'@'localhost'

+----------------------------------------------+
| Grants for faculty1@localhost                |
+----------------------------------------------+
| GRANT USAGE ON *.* TO `faculty1`@`localhost` |
+----------------------------------------------+
1 row in set

DROP USER 'faculty1'@'localhost'

Query OK, 0 rows affected

SELECT user, host FROM mysql.user WHERE user = 'faculty1'

Empty set
```


## Advanced / examiner-style queries

### Adv 1 - Courses with number of enrolled students (including courses with none)

```sql
SELECT c.course_id, c.course_name, COUNT(e.roll_no) AS enrolled FROM Course c LEFT JOIN Enrolment e USING (course_id) GROUP BY c.course_id, c.course_name;
```

**Output**

```text
SELECT c.course_id, c.course_name, COUNT(e.roll_no) AS enrolled FROM Course c LEFT JOIN Enrolment e USING (course_id) GROUP BY c.course_id, c.course_name

+-----------+------------------+----------+
| course_id | course_name      | enrolled |
+-----------+------------------+----------+
| C101      | DBMS             |        2 |
| C102      | Machine Learning |        1 |
+-----------+------------------+----------+
2 rows in set
```

### Adv 2 - Students enrolled in no course

```sql
SELECT s.roll_no, s.name FROM Student s WHERE NOT EXISTS (SELECT 1 FROM Enrolment e WHERE e.roll_no = s.roll_no);
```

**Output**

```text
SELECT s.roll_no, s.name FROM Student s WHERE NOT EXISTS (SELECT 1 FROM Enrolment e WHERE e.roll_no = s.roll_no)

+---------+----------------+
| roll_no | name           |
+---------+----------------+
|     103 | Omkar Salunkhe |
|     104 | Priya Mane     |
+---------+----------------+
2 rows in set
```

**Why this output is correct:** NOT EXISTS anti-join: priya (104) has no enrolment.

### Adv 3 - Total credits per student

```sql
SELECT s.name, SUM(c.credits) AS total_credits FROM Student s JOIN Enrolment e USING (roll_no) JOIN Course c USING (course_id) GROUP BY s.roll_no, s.name;
```

**Output**

```text
SELECT s.name, SUM(c.credits) AS total_credits FROM Student s JOIN Enrolment e USING (roll_no) JOIN Course c USING (course_id) GROUP BY s.roll_no, s.name

+--------------+---------------+
| name         | total_credits |
+--------------+---------------+
| Aditya Pawar |             8 |
| Neha Gaikwad |             4 |
+--------------+---------------+
2 rows in set
```

### Adv 4 - Duplicate enrolment (composite PK violation)

```sql
INSERT INTO Enrolment VALUES (101, 'C101');
```

**Output**

```text
INSERT INTO Enrolment VALUES (101, 'C101')

ERROR 1062 (23000) at line 1: Duplicate entry '101-C101' for key 'enrolment.PRIMARY'
```

**Why this output is correct:** (101, C101) already exists -> error 1062.

### Adv 5 - Student of an unknown department

```sql
INSERT INTO Student VALUES (110, 'Ghost', 'D9', 1, 7.0);
```

**Output**

```text
INSERT INTO Student VALUES (110, 'Ghost', 'D9', 1, 7.0)

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`college_1c`.`student`, CONSTRAINT `fk_student_dept` FOREIGN KEY (`dept_id`) REFERENCES `department` (`dept_id`))
```

**Why this output is correct:** Error 1452 because D9 does not exist.

### Adv 6 - Highest cgpa student in each department

```sql
SELECT d.dept_name, s.name, s.cgpa FROM Student s JOIN Department d USING (dept_id)
WHERE s.cgpa = (SELECT MAX(cgpa) FROM Student x WHERE x.dept_id = s.dept_id);
```

**Output**

```text
SELECT d.dept_name, s.name, s.cgpa FROM Student s JOIN Department d USING (dept_id)
WHERE s.cgpa = (SELECT MAX(cgpa) FROM Student x WHERE x.dept_id = s.dept_id)

+------------+----------------+------+
| dept_name  | name           | cgpa |
+------------+----------------+------+
| AIML       | Neha Gaikwad   |  9.1 |
| CSE        | Omkar Salunkhe |  7.2 |
| Mechanical | Priya Mane     |  6.8 |
+------------+----------------+------+
3 rows in set
```

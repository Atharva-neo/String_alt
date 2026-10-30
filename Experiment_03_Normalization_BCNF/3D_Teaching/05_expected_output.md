# Expected output - Experiment_03_Normalization_BCNF / 3D_Teaching

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - All candidate keys

```sql
SELECT COUNT(*) AS rows_, COUNT(DISTINCT Student, Subject) AS pairs_student_subject, COUNT(DISTINCT Student, Teacher) AS pairs_student_teacher FROM Teaching;
```

**Output**

```text
SELECT COUNT(*) AS rows_, COUNT(DISTINCT Student, Subject) AS pairs_student_subject, COUNT(DISTINCT Student, Teacher) AS pairs_student_teacher FROM Teaching

+-------+-----------------------+-----------------------+
| rows_ | pairs_student_subject | pairs_student_teacher |
+-------+-----------------------+-----------------------+
|     5 |                     5 |                     5 |
+-------+-----------------------+-----------------------+
1 row in set
```

**Why this output is correct:** {Student,Subject}+ = all; {Student,Teacher}+ = {Student,Teacher,Subject} (Teacher -> Subject) = all; {Student}+, {Subject,Teacher}+ are not. Candidate keys: {Student, Subject} and {Student, Teacher}. Data check: both pairs are unique over the 5 rows.

### Task 2 - Prime and non-prime attributes

```sql
SELECT 'Student' AS attribute, 'prime (in both keys)' AS status UNION ALL SELECT 'Subject', 'prime (in {Student,Subject})' UNION ALL SELECT 'Teacher', 'prime (in {Student,Teacher})';
```

**Output**

```text
SELECT 'Student' AS attribute, 'prime (in both keys)' AS status UNION ALL SELECT 'Subject', 'prime (in {Student,Subject})' UNION ALL SELECT 'Teacher', 'prime (in {Student,Teacher})'

+-----------+------------------------------+
| attribute | status                       |
+-----------+------------------------------+
| Student   | prime (in both keys)         |
| Subject   | prime (in {Student,Subject}) |
| Teacher   | prime (in {Student,Teacher}) |
+-----------+------------------------------+
3 rows in set
```

**Why this output is correct:** Prime: Student, Subject, Teacher (each belongs to a candidate key). Non-prime: none.

### Task 3 - 2NF and 3NF with justification

```sql
SELECT Teacher FROM Teaching GROUP BY Teacher HAVING COUNT(DISTINCT Subject) > 1;
```

**Output**

```text
SELECT Teacher FROM Teaching GROUP BY Teacher HAVING COUNT(DISTINCT Subject) > 1

Empty set
```

**Why this output is correct:** 2NF: needs a non-prime attribute depending on part of a key - there are no non-prime attributes, so 2NF holds. 3NF: every attribute is prime, so the 3NF condition "dependent attribute is prime" is satisfied for Teacher -> Subject (Subject is prime). Hence the relation is in 3NF. Check that the FD Teacher -> Subject holds on the data (empty = holds):

### Task 4 - Prove the relation violates BCNF

```sql
SELECT Teacher, Subject, COUNT(*) AS times_the_fact_is_stored FROM Teaching GROUP BY Teacher, Subject;
```

**Output**

```text
SELECT Teacher, Subject, COUNT(*) AS times_the_fact_is_stored FROM Teaching GROUP BY Teacher, Subject

+-------------+---------+--------------------------+
| Teacher     | Subject | times_the_fact_is_stored |
+-------------+---------+--------------------------+
| Prof. Joshi | ML      |                        2 |
| Prof. Kale  | DBMS    |                        2 |
| Prof. Mane  | DBMS    |                        1 |
+-------------+---------+--------------------------+
3 rows in set
```

**Why this output is correct:** Teacher -> Subject is non-trivial and Teacher+ = {Teacher, Subject} is not all attributes, so Teacher is not a superkey. Consequence (redundancy): the fact 'Prof. Kale teaches DBMS' is stored once for every student of Kale.

### Task 5 - Update anomaly when Prof. Kale switches subject

```sql
START TRANSACTION;
UPDATE Teaching SET Subject = 'DAA' WHERE Student = 'Asha' AND Teacher = 'Prof. Kale';
SELECT Teacher, COUNT(DISTINCT Subject) AS subjects_taught FROM Teaching WHERE Teacher = 'Prof. Kale' GROUP BY Teacher;
SELECT * FROM Teaching WHERE Teacher = 'Prof. Kale';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Teaching SET Subject = 'DAA' WHERE Student = 'Asha' AND Teacher = 'Prof. Kale'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT Teacher, COUNT(DISTINCT Subject) AS subjects_taught FROM Teaching WHERE Teacher = 'Prof. Kale' GROUP BY Teacher

+------------+-----------------+
| Teacher    | subjects_taught |
+------------+-----------------+
| Prof. Kale |               2 |
+------------+-----------------+
1 row in set

SELECT * FROM Teaching WHERE Teacher = 'Prof. Kale'

+---------+---------+------------+
| Student | Subject | Teacher    |
+---------+---------+------------+
| Asha    | DAA     | Prof. Kale |
| Bhushan | DBMS    | Prof. Kale |
+---------+---------+------------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** Kale switches from DBMS to DAA. All rows of Kale must change (2 rows); updating only one leaves Kale teaching two subjects, breaking Teacher -> Subject.

### Task 6 - Decompose into BCNF

```sql
CREATE TABLE Teacher_Subject_tmp AS SELECT DISTINCT Teacher, Subject FROM Teaching;
CREATE TABLE Student_Teacher_tmp AS SELECT DISTINCT Student, Teacher FROM Teaching;
SELECT * FROM Teacher_Subject_tmp ORDER BY Teacher; SELECT * FROM Student_Teacher_tmp ORDER BY Student, Teacher;
```

**Output**

```text
CREATE TABLE Teacher_Subject_tmp AS SELECT DISTINCT Teacher, Subject FROM Teaching

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

CREATE TABLE Student_Teacher_tmp AS SELECT DISTINCT Student, Teacher FROM Teaching

Query OK, 5 rows affected
Records: 5  Duplicates: 0  Warnings: 0

SELECT * FROM Teacher_Subject_tmp ORDER BY Teacher

+-------------+---------+
| Teacher     | Subject |
+-------------+---------+
| Prof. Joshi | ML      |
| Prof. Kale  | DBMS    |
| Prof. Mane  | DBMS    |
+-------------+---------+
3 rows in set

SELECT * FROM Student_Teacher_tmp ORDER BY Student, Teacher

+---------+-------------+
| Student | Teacher     |
+---------+-------------+
| Asha    | Prof. Joshi |
| Asha    | Prof. Kale  |
| Bhushan | Prof. Kale  |
| Chetan  | Prof. Joshi |
| Chetan  | Prof. Mane  |
+---------+-------------+
5 rows in set
```

**Why this output is correct:** Take the violating FD Teacher -> Subject: R1(Teacher, Subject) with key Teacher and R2(Student, Teacher) = R minus the dependent attribute.

### Task 7 - Is the decomposition lossless?

```sql
SELECT COUNT(*) AS joined_rows,
       SUM(NOT EXISTS (SELECT 1 FROM Teaching t WHERE t.Student = st.Student AND t.Teacher = st.Teacher AND t.Subject = ts.Subject)) AS spurious_rows
FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher;
SELECT COUNT(*) AS original_rows_missing FROM Teaching t WHERE NOT EXISTS
  (SELECT 1 FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher WHERE st.Student = t.Student AND ts.Subject = t.Subject AND st.Teacher = t.Teacher);
DROP TABLE Teacher_Subject_tmp, Student_Teacher_tmp;
```

**Output**

```text
SELECT COUNT(*) AS joined_rows,
       SUM(NOT EXISTS (SELECT 1 FROM Teaching t WHERE t.Student = st.Student AND t.Teacher = st.Teacher AND t.Subject = ts.Subject)) AS spurious_rows
FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher

+-------------+---------------+
| joined_rows | spurious_rows |
+-------------+---------------+
|           5 |             0 |
+-------------+---------------+
1 row in set

SELECT COUNT(*) AS original_rows_missing FROM Teaching t WHERE NOT EXISTS
  (SELECT 1 FROM Student_Teacher_tmp st JOIN Teacher_Subject_tmp ts ON ts.Teacher = st.Teacher WHERE st.Student = t.Student AND ts.Subject = t.Subject AND st.Teacher = t.Teacher)

+-----------------------+
| original_rows_missing |
+-----------------------+
|                     0 |
+-----------------------+
1 row in set

DROP TABLE Teacher_Subject_tmp, Student_Teacher_tmp

Query OK, 0 rows affected
```

**Why this output is correct:** Yes: R1 ∩ R2 = {Teacher}, and Teacher is a key of R1 (Teacher -> Subject). Proof on data: the natural join returns exactly the 5 original rows.

### Task 8 - Is it dependency preserving? Which FD is lost?

```sql
SELECT '{Student, Subject} -> Teacher is NOT preserved by the BCNF decomposition' AS conclusion;
```

**Output**

```text
SELECT '{Student, Subject} -> Teacher is NOT preserved by the BCNF decomposition' AS conclusion

+--------------------------------------------------------------------------+
| conclusion                                                               |
+--------------------------------------------------------------------------+
| {Student, Subject} -> Teacher is NOT preserved by the BCNF decomposition |
+--------------------------------------------------------------------------+
1 row in set
```

**Why this output is correct:** The FD {Student, Subject} -> Teacher spans both tables (Student only in R2, Subject only in R1) so no table can enforce it. Demonstration (after Task 9 the tables exist): Asha can be given a second DBMS teacher, which the old table forbade (PK Student, Subject). See the "lost dependency" demo in ADV 1. Python proof: fd_analysis.py => 'Dependency preserving : False, lost: {Student, Subject}->{Teacher}'.

### Task 9 - Create the BCNF tables in SQL

```sql
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
```

**Output**

```text
CREATE TABLE Teacher_Subject (
    Teacher VARCHAR(30) NOT NULL PRIMARY KEY,
    Subject VARCHAR(30) NOT NULL
) ENGINE=InnoDB

Query OK, 0 rows affected

CREATE TABLE Student_Teacher (
    Student VARCHAR(30) NOT NULL,
    Teacher VARCHAR(30) NOT NULL,
    PRIMARY KEY (Student, Teacher),
    CONSTRAINT fk_st_teacher FOREIGN KEY (Teacher) REFERENCES Teacher_Subject(Teacher)
) ENGINE=InnoDB

Query OK, 0 rows affected

SHOW TABLES

+-------------------+
| Tables_in_norm_3d |
+-------------------+
| student_teacher   |
| teacher_subject   |
| teaching          |
+-------------------+
3 rows in set
```

### Task 10 - Insert the data into them

```sql
INSERT INTO Teacher_Subject SELECT DISTINCT Teacher, Subject FROM Teaching;
INSERT INTO Student_Teacher SELECT DISTINCT Student, Teacher FROM Teaching;
SELECT * FROM Teacher_Subject ORDER BY Teacher;
SELECT * FROM Student_Teacher ORDER BY Student, Teacher;
```

**Output**

```text
INSERT INTO Teacher_Subject SELECT DISTINCT Teacher, Subject FROM Teaching

Query OK, 3 rows affected
Records: 3  Duplicates: 0  Warnings: 0

INSERT INTO Student_Teacher SELECT DISTINCT Student, Teacher FROM Teaching

Query OK, 5 rows affected
Records: 5  Duplicates: 0  Warnings: 0

SELECT * FROM Teacher_Subject ORDER BY Teacher

+-------------+---------+
| Teacher     | Subject |
+-------------+---------+
| Prof. Joshi | ML      |
| Prof. Kale  | DBMS    |
| Prof. Mane  | DBMS    |
+-------------+---------+
3 rows in set

SELECT * FROM Student_Teacher ORDER BY Student, Teacher

+---------+-------------+
| Student | Teacher     |
+---------+-------------+
| Asha    | Prof. Joshi |
| Asha    | Prof. Kale  |
| Bhushan | Prof. Kale  |
| Chetan  | Prof. Joshi |
| Chetan  | Prof. Mane  |
+---------+-------------+
5 rows in set
```

### Task 11 - JOIN that lists each student, subject and teacher

```sql
SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) ORDER BY st.Student, ts.Subject;
```

**Output**

```text
SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) ORDER BY st.Student, ts.Subject

+---------+---------+-------------+
| Student | Subject | Teacher     |
+---------+---------+-------------+
| Asha    | DBMS    | Prof. Kale  |
| Asha    | ML      | Prof. Joshi |
| Bhushan | DBMS    | Prof. Kale  |
| Chetan  | DBMS    | Prof. Mane  |
| Chetan  | ML      | Prof. Joshi |
+---------+---------+-------------+
5 rows in set
```

### Task 12 - Teachers with the number of students they teach

```sql
SELECT ts.Teacher, ts.Subject, COUNT(st.Student) AS students FROM Teacher_Subject ts LEFT JOIN Student_Teacher st USING (Teacher) GROUP BY ts.Teacher, ts.Subject ORDER BY students DESC, ts.Teacher;
```

**Output**

```text
SELECT ts.Teacher, ts.Subject, COUNT(st.Student) AS students FROM Teacher_Subject ts LEFT JOIN Student_Teacher st USING (Teacher) GROUP BY ts.Teacher, ts.Subject ORDER BY students DESC, ts.Teacher

+-------------+---------+----------+
| Teacher     | Subject | students |
+-------------+---------+----------+
| Prof. Joshi | ML      |        2 |
| Prof. Kale  | DBMS    |        2 |
| Prof. Mane  | DBMS    |        1 |
+-------------+---------+----------+
3 rows in set
```

**Why this output is correct:** Kale 2 (Asha, Bhushan), Joshi 2 (Asha, Chetan), Mane 1 (Chetan).


## Advanced / examiner-style queries

### Adv 1 - The lost dependency {Student, Subject} -> Teacher in action

```sql
START TRANSACTION;
INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Mane');
SELECT st.Student, ts.Subject, COUNT(*) AS teachers FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) GROUP BY st.Student, ts.Subject HAVING COUNT(*) > 1;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Mane')

Query OK, 1 row affected

SELECT st.Student, ts.Subject, COUNT(*) AS teachers FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) GROUP BY st.Student, ts.Subject HAVING COUNT(*) > 1

+---------+---------+----------+
| Student | Subject | teachers |
+---------+---------+----------+
| Asha    | DBMS    |        2 |
+---------+---------+----------+
1 row in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** The decomposed schema happily accepts a second DBMS teacher (Prof. Mane) for Asha, which the original PK (Student, Subject) would have rejected. The violation is only visible after a join (two teachers for one student+subject). This is the price of BCNF.

### Adv 2 - The same insert on the original relation is rejected

```sql
INSERT INTO Teaching VALUES ('Asha', 'DBMS', 'Prof. Mane');
```

**Output**

```text
INSERT INTO Teaching VALUES ('Asha', 'DBMS', 'Prof. Mane')

ERROR 1062 (23000) at line 1: Duplicate entry 'Asha-DBMS' for key 'teaching.PRIMARY'
```

**Why this output is correct:** Error 1062 on (Student, Subject): the old design enforced the FD.

### Adv 3 - Kale switches subject - ONE row update in the BCNF design

```sql
START TRANSACTION;
UPDATE Teacher_Subject SET Subject = 'DAA' WHERE Teacher = 'Prof. Kale';
SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) WHERE st.Teacher = 'Prof. Kale';
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

UPDATE Teacher_Subject SET Subject = 'DAA' WHERE Teacher = 'Prof. Kale'

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT st.Student, ts.Subject, st.Teacher FROM Student_Teacher st JOIN Teacher_Subject ts USING (Teacher) WHERE st.Teacher = 'Prof. Kale'

+---------+---------+------------+
| Student | Subject | Teacher    |
+---------+---------+------------+
| Asha    | DAA     | Prof. Kale |
| Bhushan | DAA     | Prof. Kale |
+---------+---------+------------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected
```

### Adv 4 - A teacher without students can now be stored

```sql
INSERT INTO Teacher_Subject VALUES ('Prof. Rao', 'DAA');
SELECT * FROM Teacher_Subject;
```

**Output**

```text
INSERT INTO Teacher_Subject VALUES ('Prof. Rao', 'DAA')

Query OK, 1 row affected

SELECT * FROM Teacher_Subject

+-------------+---------+
| Teacher     | Subject |
+-------------+---------+
| Prof. Joshi | ML      |
| Prof. Kale  | DBMS    |
| Prof. Mane  | DBMS    |
| Prof. Rao   | DAA     |
+-------------+---------+
4 rows in set
```

### Adv 5 - Students taking more than one subject

```sql
SELECT st.Student, COUNT(*) AS subjects FROM Student_Teacher st GROUP BY st.Student HAVING COUNT(*) > 1;
```

**Output**

```text
SELECT st.Student, COUNT(*) AS subjects FROM Student_Teacher st GROUP BY st.Student HAVING COUNT(*) > 1

+---------+----------+
| Student | subjects |
+---------+----------+
| Asha    |        2 |
| Chetan  |        2 |
+---------+----------+
2 rows in set
```

### Adv 6 - Student of an unknown teacher

```sql
INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Nobody');
```

**Output**

```text
INSERT INTO Student_Teacher VALUES ('Asha', 'Prof. Nobody')

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`norm_3d`.`student_teacher`, CONSTRAINT `fk_st_teacher` FOREIGN KEY (`Teacher`) REFERENCES `teacher_subject` (`Teacher`))
```

**Why this output is correct:** Error 1452.


## Functional-dependency analysis (Python, `fd_analysis.py`)

```text
=== 3D: Teaching(Student, Subject, Teacher) ===
Attributes : {Student, Subject, Teacher}
FDs        : {Student, Subject} -> {Teacher}; {Teacher} -> {Subject}
Closure {Teacher}+ = {Subject, Teacher}
Closure {Student, Subject}+ = {Student, Subject, Teacher}
Closure {Student, Teacher}+ = {Student, Subject, Teacher}
Closure {Student}+ = {Student}
Candidate keys : {Student, Subject}, {Student, Teacher}
Prime attributes : {Student, Subject, Teacher}
Partial dependencies (2NF violations) : none
3NF violations : none
BCNF violations : {Teacher}->{Subject}

=== 3D: BCNF decomposition  Teacher_Subject(Teacher, Subject) | Student_Teacher(Student, Teacher) ===
Attributes : {Student, Subject, Teacher}
FDs        : {Student, Subject} -> {Teacher}; {Teacher} -> {Subject}
Decomposition : {Subject, Teacher} | {Student, Teacher}
Lossless join : True
Dependency preserving : False lost: {Student, Subject}->{Teacher}
  relation {Subject, Teacher}: keys ['{Teacher}'], BCNF violations none
  relation {Student, Teacher}: keys ['{Student, Teacher}'], BCNF violations none
```

# Expected output - Experiment_02_Advanced_SQL / 2C_University_Results

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Student name, subject name and marks

```sql
SELECT s.name, sub.sub_name, m.marks FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY s.roll_no, sub.sub_id;
```

**Output**

```text
SELECT s.name, sub.sub_name, m.marks FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY s.roll_no, sub.sub_id

+---------+----------+-------+
| name    | sub_name | marks |
+---------+----------+-------+
| Asha    | DBMS     |    78 |
| Asha    | ML       |    85 |
| Bhushan | DBMS     |    35 |
| Bhushan | ML       |    62 |
| Chetan  | DBMS     |    91 |
| Chetan  | DAA      |    74 |
| Divya   | DBMS     |    55 |
| Divya   | DAA      |    38 |
| Esha    | DBMS     |    67 |
+---------+----------+-------+
9 rows in set
```

### Task 2 - Each student's total and average marks

```sql
SELECT s.name, SUM(m.marks) AS total, ROUND(AVG(m.marks),2) AS average FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name ORDER BY total DESC;
```

**Output**

```text
SELECT s.name, SUM(m.marks) AS total, ROUND(AVG(m.marks),2) AS average FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name ORDER BY total DESC

+---------+-------+---------+
| name    | total | average |
+---------+-------+---------+
| Chetan  |   165 |   82.50 |
| Asha    |   163 |   81.50 |
| Bhushan |    97 |   48.50 |
| Divya   |    93 |   46.50 |
| Esha    |    67 |   67.00 |
+---------+-------+---------+
5 rows in set
```

**Why this output is correct:** Esha has only one subject, so total = average = 67. Average is over subjects actually taken.

### Task 3 - Students who scored more than ALL AIML students in DBMS

```sql
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ALL (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'AIML' AND m2.sub_id = 'S1');
```

**Output**

```text
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ALL (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'AIML' AND m2.sub_id = 'S1')

+--------+-------+
| name   | marks |
+--------+-------+
| Chetan |    91 |
+--------+-------+
1 row in set
```

**Why this output is correct:** AIML DBMS marks are 78 and 35; "> ALL" means > 78, so only Chetan (91) qualifies.

### Task 4 - Students who scored more than ANY CSE student in DBMS

```sql
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ANY (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'CSE' AND m2.sub_id = 'S1');
```

**Output**

```text
SELECT s.name, m.marks FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1'
AND m.marks > ANY (SELECT m2.marks FROM Marks m2 JOIN Student s2 USING (roll_no) WHERE s2.dept = 'CSE' AND m2.sub_id = 'S1')

+--------+-------+
| name   | marks |
+--------+-------+
| Asha   |    78 |
| Chetan |    91 |
| Esha   |    67 |
+--------+-------+
3 rows in set
```

**Why this output is correct:** CSE DBMS marks are 91 and 55; "> ANY" means > 55 (the minimum): Asha 78, Esha 67 and Chetan 91 (more than Divya's 55).

### Task 5 - Subject-wise average, highest and lowest marks

```sql
SELECT sub.sub_name, ROUND(AVG(m.marks),2) AS avg_marks, MAX(m.marks) AS highest, MIN(m.marks) AS lowest
FROM Marks m JOIN Subject sub USING (sub_id) GROUP BY sub.sub_id, sub.sub_name;
```

**Output**

```text
SELECT sub.sub_name, ROUND(AVG(m.marks),2) AS avg_marks, MAX(m.marks) AS highest, MIN(m.marks) AS lowest
FROM Marks m JOIN Subject sub USING (sub_id) GROUP BY sub.sub_id, sub.sub_name

+----------+-----------+---------+--------+
| sub_name | avg_marks | highest | lowest |
+----------+-----------+---------+--------+
| DBMS     |     65.20 |      91 |     35 |
| ML       |     73.50 |      85 |     62 |
| DAA      |     56.00 |      74 |     38 |
+----------+-----------+---------+--------+
3 rows in set
```

### Task 6 - Topper's name for each subject

```sql
SELECT sub.sub_name, s.name AS topper, m.marks
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id)
JOIN (SELECT sub_id, MAX(marks) AS mx FROM Marks GROUP BY sub_id) t ON t.sub_id = m.sub_id AND t.mx = m.marks;
```

**Output**

```text
SELECT sub.sub_name, s.name AS topper, m.marks
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id)
JOIN (SELECT sub_id, MAX(marks) AS mx FROM Marks GROUP BY sub_id) t ON t.sub_id = m.sub_id AND t.mx = m.marks

+----------+--------+-------+
| sub_name | topper | marks |
+----------+--------+-------+
| ML       | Asha   |    85 |
| DBMS     | Chetan |    91 |
| DAA      | Chetan |    74 |
+----------+--------+-------+
3 rows in set
```

**Why this output is correct:** Derived table gives MAX(marks) per subject; joining back returns the student(s) holding it (ties would both show).

### Task 7 - Department-wise average marks having average > 60

```sql
SELECT s.dept, ROUND(AVG(m.marks),2) AS avg_marks FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.dept HAVING AVG(m.marks) > 60;
```

**Output**

```text
SELECT s.dept, ROUND(AVG(m.marks),2) AS avg_marks FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.dept HAVING AVG(m.marks) > 60

+------+-----------+
| dept | avg_marks |
+------+-----------+
| AIML |     65.00 |
| CSE  |     64.50 |
| ENTC |     67.00 |
+------+-----------+
3 rows in set
```

**Why this output is correct:** AIML (78+85+35+62)/4 = 65, CSE (91+74+55+38)/4 = 64.5, ENTC 67. All three exceed 60.

### Task 8 - Number of students who failed (marks < 40) in each subject

```sql
SELECT sub.sub_name, SUM(m.marks < 40) AS failed FROM Subject sub LEFT JOIN Marks m USING (sub_id) GROUP BY sub.sub_id, sub.sub_name;
```

**Output**

```text
SELECT sub.sub_name, SUM(m.marks < 40) AS failed FROM Subject sub LEFT JOIN Marks m USING (sub_id) GROUP BY sub.sub_id, sub.sub_name

+----------+--------+
| sub_name | failed |
+----------+--------+
| DBMS     |      1 |
| ML       |      0 |
| DAA      |      1 |
+----------+--------+
3 rows in set
```

**Why this output is correct:** LEFT JOIN-free version: SUM of a boolean. DBMS: Bhushan(35); ML: none; DAA: Divya(38).

### Task 9 - Students who appeared for DBMS but not for ML (NOT IN)

```sql
SELECT s.roll_no, s.name FROM Student s
WHERE s.roll_no IN (SELECT roll_no FROM Marks WHERE sub_id = 'S1') AND s.roll_no NOT IN (SELECT roll_no FROM Marks WHERE sub_id = 'S2');
```

**Output**

```text
SELECT s.roll_no, s.name FROM Student s
WHERE s.roll_no IN (SELECT roll_no FROM Marks WHERE sub_id = 'S1') AND s.roll_no NOT IN (SELECT roll_no FROM Marks WHERE sub_id = 'S2')

+---------+--------+
| roll_no | name   |
+---------+--------+
|       3 | Chetan |
|       4 | Divya  |
|       5 | Esha   |
+---------+--------+
3 rows in set
```

### Task 10 - Students who appeared in more than one subject

```sql
SELECT s.roll_no, s.name, COUNT(*) AS subjects FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(*) > 1;
```

**Output**

```text
SELECT s.roll_no, s.name, COUNT(*) AS subjects FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(*) > 1

+---------+---------+----------+
| roll_no | name    | subjects |
+---------+---------+----------+
|       1 | Asha    |        2 |
|       2 | Bhushan |        2 |
|       3 | Chetan  |        2 |
|       4 | Divya   |        2 |
+---------+---------+----------+
4 rows in set
```

### Task 11 - Rank students by DBMS marks (ORDER BY and RANK())

```sql
SELECT s.name, m.marks, RANK() OVER (ORDER BY m.marks DESC) AS dbms_rank FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1' ORDER BY dbms_rank;
```

**Output**

```text
SELECT s.name, m.marks, RANK() OVER (ORDER BY m.marks DESC) AS dbms_rank FROM Marks m JOIN Student s USING (roll_no) WHERE m.sub_id = 'S1' ORDER BY dbms_rank

+---------+-------+-----------+
| name    | marks | dbms_rank |
+---------+-------+-----------+
| Chetan  |    91 |         1 |
| Asha    |    78 |         2 |
| Esha    |    67 |         3 |
| Divya   |    55 |         4 |
| Bhushan |    35 |         5 |
+---------+-------+-----------+
5 rows in set
```

**Why this output is correct:** RANK() leaves gaps after ties; no ties here so ranks are 1..5.

### Task 12 - View below_40 and UPDATE marks through it

```sql
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
```

**Output**

```text
CREATE VIEW below_40 AS
SELECT s.roll_no, s.name, sub.sub_name, m.marks FROM Marks m JOIN Student s ON s.roll_no = m.roll_no JOIN Subject sub ON sub.sub_id = m.sub_id WHERE m.marks < 40

Query OK, 0 rows affected

SELECT * FROM below_40

+---------+---------+----------+-------+
| roll_no | name    | sub_name | marks |
+---------+---------+----------+-------+
|       2 | Bhushan | DBMS     |    35 |
|       4 | Divya   | DAA      |    38 |
+---------+---------+----------+-------+
2 rows in set

START TRANSACTION

Query OK, 0 rows affected

UPDATE below_40 SET marks = 45 WHERE roll_no = 2

Query OK, 1 row affected
Rows matched: 1  Changed: 1  Warnings: 0

SELECT * FROM below_40

+---------+-------+----------+-------+
| roll_no | name  | sub_name | marks |
+---------+-------+----------+-------+
|       4 | Divya | DAA      |    38 |
+---------+-------+----------+-------+
1 row in set

SELECT roll_no, sub_id, marks FROM Marks WHERE roll_no = 2 AND sub_id = 'S1'

+---------+--------+-------+
| roll_no | sub_id | marks |
+---------+--------+-------+
|       2 | S1     |    45 |
+---------+--------+-------+
1 row in set

UPDATE below_40 SET name = 'Bhushan K', marks = 39 WHERE roll_no = 2

ERROR 1393 (HY000) at line 8: Can not modify more than one base table through a join view 'univ_2c.below_40'
ROLLBACK

Query OK, 0 rows affected

CREATE VIEW below_40_chk AS SELECT roll_no, sub_id, marks FROM Marks WHERE marks < 40 WITH CHECK OPTION

Query OK, 0 rows affected

UPDATE below_40_chk SET marks = 45 WHERE roll_no = 2 AND sub_id = 'S1'

ERROR 1369 (HY000) at line 11: CHECK OPTION failed 'univ_2c.below_40_chk'
SELECT roll_no, sub_id, marks FROM Marks WHERE roll_no = 2 AND sub_id = 'S1'

+---------+--------+-------+
| roll_no | sub_id | marks |
+---------+--------+-------+
|       2 | S1     |    35 |
+---------+--------+-------+
1 row in set
```

**Why this output is correct:** The join view is updatable for marks (single base table Marks). Raising Bhushan's DBMS marks to 45 succeeds, and the row then vanishes from the view because it no longer satisfies marks < 40 (no CHECK OPTION). Changing columns of two tables at once fails (error 1393). With WITH CHECK OPTION the same UPDATE is rejected (error 1369). Everything runs inside a transaction that is rolled back.


## Advanced / examiner-style queries

### Adv 1 - Second highest DBMS mark

```sql
SELECT marks FROM Marks WHERE sub_id = 'S1' ORDER BY marks DESC LIMIT 1 OFFSET 1;
```

**Output**

```text
SELECT marks FROM Marks WHERE sub_id = 'S1' ORDER BY marks DESC LIMIT 1 OFFSET 1

+-------+
| marks |
+-------+
|    78 |
+-------+
1 row in set
```

### Adv 2 - Result class per student (>=75 Distinction, >=40 on every subject Pass)

```sql
SELECT s.name, ROUND(AVG(m.marks),1) AS avg_marks,
  CASE WHEN MIN(m.marks) < 40 THEN 'FAIL' WHEN AVG(m.marks) >= 75 THEN 'DISTINCTION' ELSE 'PASS' END AS result
FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name;
```

**Output**

```text
SELECT s.name, ROUND(AVG(m.marks),1) AS avg_marks,
  CASE WHEN MIN(m.marks) < 40 THEN 'FAIL' WHEN AVG(m.marks) >= 75 THEN 'DISTINCTION' ELSE 'PASS' END AS result
FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name

+---------+-----------+-------------+
| name    | avg_marks | result      |
+---------+-----------+-------------+
| Asha    |      81.5 | DISTINCTION |
| Bhushan |      48.5 | FAIL        |
| Chetan  |      82.5 | DISTINCTION |
| Divya   |      46.5 | FAIL        |
| Esha    |      67.0 | PASS        |
+---------+-----------+-------------+
5 rows in set
```

**Why this output is correct:** MIN(marks) < 40 means at least one failed subject.

### Adv 3 - Students appearing in every subject (division via counts)

```sql
SELECT s.name FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(DISTINCT m.sub_id) = (SELECT COUNT(*) FROM Subject);
```

**Output**

```text
SELECT s.name FROM Student s JOIN Marks m USING (roll_no) GROUP BY s.roll_no, s.name HAVING COUNT(DISTINCT m.sub_id) = (SELECT COUNT(*) FROM Subject)

Empty set
```

### Adv 4 - Subject-wise rank of every student (PARTITION BY)

```sql
SELECT sub.sub_name, s.name, m.marks, RANK() OVER (PARTITION BY m.sub_id ORDER BY m.marks DESC) AS rank_in_subject
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY sub.sub_id, rank_in_subject;
```

**Output**

```text
SELECT sub.sub_name, s.name, m.marks, RANK() OVER (PARTITION BY m.sub_id ORDER BY m.marks DESC) AS rank_in_subject
FROM Marks m JOIN Student s USING (roll_no) JOIN Subject sub USING (sub_id) ORDER BY sub.sub_id, rank_in_subject

+----------+---------+-------+-----------------+
| sub_name | name    | marks | rank_in_subject |
+----------+---------+-------+-----------------+
| DBMS     | Chetan  |    91 |               1 |
| DBMS     | Asha    |    78 |               2 |
| DBMS     | Esha    |    67 |               3 |
| DBMS     | Divya   |    55 |               4 |
| DBMS     | Bhushan |    35 |               5 |
| ML       | Asha    |    85 |               1 |
| ML       | Bhushan |    62 |               2 |
| DAA      | Chetan  |    74 |               1 |
| DAA      | Divya   |    38 |               2 |
+----------+---------+-------+-----------------+
9 rows in set
```

### Adv 5 - Marks above the subject maximum (CHECK would be needed) - show how to guard

```sql
START TRANSACTION;
INSERT INTO Marks VALUES (5, 'S2', 150);
SELECT * FROM Marks WHERE roll_no = 5;
ROLLBACK;
```

**Output**

```text
START TRANSACTION

Query OK, 0 rows affected

INSERT INTO Marks VALUES (5, 'S2', 150)

Query OK, 1 row affected

SELECT * FROM Marks WHERE roll_no = 5

+---------+--------+-------+
| roll_no | sub_id | marks |
+---------+--------+-------+
|       5 | S1     |    67 |
|       5 | S2     |   150 |
+---------+--------+-------+
2 rows in set

ROLLBACK

Query OK, 0 rows affected
```

**Why this output is correct:** The schema only checks marks >= 0, so 150 is accepted; this demonstrates a missing-constraint discussion point, rolled back.

### Adv 6 - Negative marks

```sql
INSERT INTO Marks VALUES (5, 'S3', -5);
```

**Output**

```text
INSERT INTO Marks VALUES (5, 'S3', -5)

ERROR 3819 (HY000) at line 1: Check constraint 'chk_marks' is violated.
```

**Why this output is correct:** chk_marks rejects it with error 3819.

# Expected output - Experiment_09_Student_Records / 9B_Result_Analysis

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create the four collections (students, courses, attendance, exams) with validation
collections: [ 'attendance', 'courses', 'exams', 'students' ]

### Task 2 - Negative tests for the validation rules
semester 9 -> code 121: Document failed validation
missing name -> code 121: Document failed validation
ise 45 (> 40) -> code 121: Document failed validation
```

## `insert_data.js`

```text
### Task 1 - Insert the data into students, courses, attendance and exams
students    4
courses     3
attendance  6
exams       6
```

## `queries.js`

```text
### Task 1 - All exam records sorted by total, highest first
{ student_id: 'S102', course_id: 'C1', ise: 38, ese: 54, total: 92 }
{ student_id: 'S101', course_id: 'C1', ise: 32, ese: 48, total: 80 }
{ student_id: 'S102', course_id: 'C2', ise: 30, ese: 46, total: 76 }
{ student_id: 'S103', course_id: 'C3', ise: 28, ese: 42, total: 70 }
{ student_id: 'S101', course_id: 'C2', ise: 20, ese: 25, total: 45 }
{ student_id: 'S104', course_id: 'C1', ise: 15, ese: 20, total: 35 }

### Task 2 - Students who failed in any course (total < 40; pass mark is 40)
{ student_id: 'S104', course_id: 'C1', total: 35 }

### Task 11 - Students whose ISE >= 30 but ESE < 30
[]
-- empty: every student with ISE >= 30 also scored >= 46 in ESE. For comparison, ISE >= 20 and ESE < 30:
{ student_id: 'S101', course_id: 'C2', ise: 20, ese: 25, total: 45 }
```

## `aggregation.js`

```text
### Task 3 - Course-wise average, highest and lowest total
{ _id: 'C1', avg: 69, highest: 92, lowest: 35, students: 3 }
{ _id: 'C2', avg: 60.5, highest: 76, lowest: 45, students: 2 }
{ _id: 'C3', avg: 70, highest: 70, lowest: 70, students: 1 }

### Task 4 - Course-wise pass percentage (pass = total >= 40)
{ _id: 'C1', appeared: 3, passed: 2, pass_percentage: 66.67 }
{ _id: 'C2', appeared: 2, passed: 2, pass_percentage: 100 }
{ _id: 'C3', appeared: 1, passed: 1, pass_percentage: 100 }

### Task 5 - Topper of each course with the student's name ($sort + $group/$first, then $lookup)
{ top_total: 92, course: 'C1', topper: 'Neha Gaikwad' }
{ top_total: 76, course: 'C2', topper: 'Neha Gaikwad' }
{ top_total: 70, course: 'C3', topper: 'Omkar Salunkhe' }

### Task 8 - Students who scored above the course average
{ student_id: 'S101', course_id: 'C1', total: 80, course_avg: 69 }
{ student_id: 'S102', course_id: 'C1', total: 92, course_avg: 69 }
{ student_id: 'S102', course_id: 'C2', total: 76, course_avg: 60.5 }

### Task 9 - Faculty-wise average marks of their course
{ avg_marks: 70, faculty: 'Dr. Joshi', course: 'Operating Systems' }
{ avg_marks: 60.5, faculty: 'Dr. Kale', course: 'DAA' }
{ avg_marks: 69, faculty: 'Dr. Patil', course: 'DBMS' }
```

## `crud.js`

```text
### Task 6 - Add a grade field: O >= 90, A >= 75, B >= 60, C >= 40, F < 40 (update with an aggregation pipeline and $switch)
{
  acknowledged: true,
  matchedCount: 6,
  modifiedCount: 6,
  upsertedCount: 0,
  upsertedId: null
}
{ student_id: 'S101', course_id: 'C1', total: 80, grade: 'A' }
{ student_id: 'S101', course_id: 'C2', total: 45, grade: 'C' }
{ student_id: 'S102', course_id: 'C1', total: 92, grade: 'O' }
{ student_id: 'S102', course_id: 'C2', total: 76, grade: 'A' }
{ student_id: 'S103', course_id: 'C3', total: 70, grade: 'B' }
{ student_id: 'S104', course_id: 'C1', total: 35, grade: 'F' }

### Task 7 - Count of students per grade per course
{ _id: { course: 'C1', grade: 'A' }, students: 1 }
{ _id: { course: 'C1', grade: 'F' }, students: 1 }
{ _id: { course: 'C1', grade: 'O' }, students: 1 }
{ _id: { course: 'C2', grade: 'A' }, students: 1 }
{ _id: { course: 'C2', grade: 'C' }, students: 1 }
{ _id: { course: 'C3', grade: 'B' }, students: 1 }

### Task 10 - Revaluation: S104's ESE in C1 +6, recompute total (pipeline update keeps ise + ese = total consistent)
before: {"student_id":"S104","course_id":"C1","ise":15,"ese":20,"total":35,"grade":"F"}
after : {"student_id":"S104","course_id":"C1","ise":15,"ese":26,"total":41,"grade":"C"}
-- 35 (F) became 41 (C): the student now passes DBMS.

### Task 12 - Delete exam records with total = 0 (absentees)
{ acknowledged: true, deletedCount: 1 }
exam records now: 6
```

## `indexes.js`

```text
### Task idx - Index {course_id: 1, total: -1} supports 'toppers per course' and course-wise ranges
{ stage: 'COLLSCAN', nReturned: 3, totalDocsExamined: 6 }
created: course_id_1_total_-1
{ stage: 'IXSCAN', nReturned: 3, totalDocsExamined: 3 }
created: student_id_1_course_id_1
{ v: 2, key: { _id: 1 }, name: '_id_' }
{ v: 2, key: { course_id: 1, total: -1 }, name: 'course_id_1_total_-1' }
{
  v: 2,
  key: { student_id: 1, course_id: 1 },
  name: 'student_id_1_course_id_1',
  unique: true
}
```

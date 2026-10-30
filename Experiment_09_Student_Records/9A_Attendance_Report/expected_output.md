# Expected output - Experiment_09_Student_Records / 9A_Attendance_Report

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
### Task 3 - All AIML students of semester 3
{ _id: 'S101', name: 'Aditya Pawar', dept: 'AIML', semester: 3 }
{ _id: 'S102', name: 'Neha Gaikwad', dept: 'AIML', semester: 3 }
{ _id: 'S104', name: 'Priya Mane', dept: 'AIML', semester: 3 }

### Task 4 - Students from Sangli - name and phone only
{ name: 'Aditya Pawar', contact: { phone: '9822011111' } }
{ name: 'Priya Mane', contact: { phone: '9822044444' } }
```

## `aggregation.js`

```text
### Task 5 - Attendance % for every student and course
{ student_id: 'S101', course_id: 'C1', total: 40, attended: 36, pct: 90 }
{ student_id: 'S101', course_id: 'C2', total: 38, attended: 27, pct: 71.05 }
{ student_id: 'S102', course_id: 'C1', total: 40, attended: 39, pct: 97.5 }
{ student_id: 'S102', course_id: 'C2', total: 38, attended: 35, pct: 92.11 }
{ student_id: 'S103', course_id: 'C3', total: 36, attended: 30, pct: 83.33 }
{ student_id: 'S104', course_id: 'C1', total: 40, attended: 25, pct: 62.5 }

### Task 6 - Defaulters (< 75 %) with student name and course name ($lookup)
{ pct: 62.5, student: 'Priya Mane', course: 'DBMS' }
{ pct: 71.05, student: 'Aditya Pawar', course: 'DAA' }

### Task 7 - Course-wise average attendance %
{ records: 2, course: 'DAA', avg_pct: 81.58 }
{ records: 3, course: 'DBMS', avg_pct: 83.33 }
{ records: 1, course: 'Operating Systems', avg_pct: 83.33 }

### Task 9 - Number of defaulters per department
{ _id: 'AIML', defaulter_records: 2, distinct_students: 2 }
```

## `crud.js`

```text
### Task 8 - 2 more C2 lectures were held and S101 attended both
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ student_id: 'S101', course_id: 'C2', total: 40, attended: 29 }

### Task 10 - Add a new student S105 with attendance records in C1 and C2
{ student_id: 'S105', course_id: 'C1', total: 40, attended: 38 }
{ student_id: 'S105', course_id: 'C2', total: 40, attended: 30 }

### Task 12 - Delete the attendance records of students who have left (S103)
{ acknowledged: true, deletedCount: 1 }
remaining attendance documents: 7
```

## `indexes.js`

```text
### Task 11 - Before the index
{ stage: 'COLLSCAN', nReturned: 1, totalDocsExamined: 7 }

### Task 11 - Create the compound index (unique: one attendance document per student and course) and compare
created: student_id_1_course_id_1
{ stage: 'IXSCAN', nReturned: 1, totalDocsExamined: 1 }
{ v: 2, key: { _id: 1 }, name: '_id_' }
{
  v: 2,
  key: { student_id: 1, course_id: 1 },
  name: 'student_id_1_course_id_1',
  unique: true
}

### Task 11 - The unique index enforces 'one document per (student, course)'
code 11000: E11000 duplicate key error collection: collegeDB.attendance index: student_id_1_course_id_1 dup key: { student_id: 'S101', course_id: 'C2' }
```

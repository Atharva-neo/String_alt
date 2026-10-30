# Expected output - Experiment_09_Student_Records / 9D_Department_Statistics

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
### Task 1 - Count students per department
{ _id: 'AIML', students: 3 }
{ _id: 'CSE', students: 1 }

### Task 2 - Count students per department per semester
{ _id: { dept: 'AIML', semester: 3 }, students: 3 }
{ _id: { dept: 'CSE', semester: 5 }, students: 1 }

### Task 3 - Gender-wise count in each department
{ _id: { dept: 'AIML', gender: 'F' }, students: 2 }
{ _id: { dept: 'AIML', gender: 'M' }, students: 1 }
{ _id: { dept: 'CSE', gender: 'M' }, students: 1 }

### Task 6 - City-wise number of students
{ _id: 'Sangli', students: 2 }
{ _id: 'Kolhapur', students: 1 }
{ _id: 'Miraj', students: 1 }

### Task 7 - Students born after 2006-01-01
{ _id: 'S102', name: 'Neha Gaikwad', dob: ISODate('2006-02-20T00:00:00.000Z') }
{ _id: 'S101', name: 'Aditya Pawar', dob: ISODate('2006-05-14T00:00:00.000Z') }
{ _id: 'S104', name: 'Priya Mane', dob: ISODate('2006-08-09T00:00:00.000Z') }
```

## `aggregation.js`

```text
### Task 4 - Students who failed in more than one course (total < 40 in 2 or more exams)
[]
-- empty with the PDF data: S104 failed only DBMS. Students with at least ONE failed course:
{ _id: 'S104', failed_courses: 1 }

### Task 5 - Students with no exam record ($lookup and an empty array)
with the PDF data: [] (every student has an exam record)
after adding a temporary student S900: [{"_id":"S900","name":"Temp No-Exam Student"}]

### Task 10 - Average marks per department ($lookup students)
{ _id: 'AIML', avg_marks: 65.6, exam_records: 5 }
{ _id: 'CSE', avg_marks: 70, exam_records: 1 }
```

## `crud.js`

```text
### Task 8 - Promote all semester 3 students to semester 4 ($inc)
{
  acknowledged: true,
  matchedCount: 3,
  modifiedCount: 3,
  upsertedCount: 0,
  upsertedId: null
}
{ _id: 'S101', name: 'Aditya Pawar', semester: 4 }
{ _id: 'S102', name: 'Neha Gaikwad', semester: 4 }
{ _id: 'S103', name: 'Omkar Salunkhe', semester: 5 }
{ _id: 'S104', name: 'Priya Mane', semester: 4 }

### Task 9 - Add a new course C4 'Machine Learning' and enrol S101 and S102
{ _id: 'C1', name: 'DBMS', semester: 3 }
{ _id: 'C2', name: 'DAA', semester: 3 }
{ _id: 'C3', name: 'Operating Systems', semester: 5 }
{ _id: 'C4', name: 'Machine Learning', semester: 4 }
{ student_id: 'S101', course_id: 'C4', total: 0, attended: 0 }
{ student_id: 'S102', course_id: 'C4', total: 0, attended: 0 }

### Task 11 - Remove the email field from all students ($unset)
{
  acknowledged: true,
  matchedCount: 4,
  modifiedCount: 4,
  upsertedCount: 0,
  upsertedId: null
}
{ _id: 'S101', name: 'Aditya Pawar', contact: { phone: '9822011111', city: 'Sangli' } }
{ _id: 'S102', name: 'Neha Gaikwad', contact: { phone: '9822022222', city: 'Miraj' } }
{ _id: 'S103', name: 'Omkar Salunkhe', contact: { phone: '9822033333', city: 'Kolhapur' } }
{ _id: 'S104', name: 'Priya Mane', contact: { phone: '9822044444', city: 'Sangli' } }

### Task 12 - Back up attendance, drop the backup copy and list the remaining collections
collections with the backup: [ 'attendance', 'attendance_backup', 'courses', 'exams', 'students' ]
backup documents: 8 | original: 8
dropped: true
remaining collections: [ 'attendance', 'courses', 'exams', 'students' ]
```

## `indexes.js`

```text
### Task idx - Compound index {dept: 1, semester: 1} for the department / semester reports and an index on contact.city
{ stage: 'COLLSCAN', nReturned: 3, totalDocsExamined: 4 }
created: dept_1_semester_1 contact.city_1
{ stage: 'IXSCAN', nReturned: 3, totalDocsExamined: 3 }
_id_
dept_1_semester_1
contact.city_1
```

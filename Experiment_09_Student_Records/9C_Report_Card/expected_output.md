# Expected output - Experiment_09_Student_Records / 9C_Report_Card

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
### Task 1 - List each student's courses with marks (exams grouped by student)
{
  _id: 'S101',
  courses: [ { course_id: 'C1', total: 80 }, { course_id: 'C2', total: 45 } ]
}
{
  _id: 'S102',
  courses: [ { course_id: 'C1', total: 92 }, { course_id: 'C2', total: 76 } ]
}
{ _id: 'S103', courses: [ { course_id: 'C3', total: 70 } ] }
{ _id: 'S104', courses: [ { course_id: 'C1', total: 35 } ] }
```

## `aggregation.js`

```text
### Task 2 - One aggregation that joins students, exams, courses and attendance
(stages: $lookup exams -> $unwind -> $lookup courses -> $unwind -> $lookup attendance -> $filter on course -> computed fields)

### Task 3 - Per student: name, dept, course name, marks, attendance %, grade
{
  dept: 'AIML',
  attendance_pct: 71.05,
  grade: 'C',
  student: 'Aditya Pawar',
  course: 'DAA',
  marks: 45
}
{
  dept: 'AIML',
  attendance_pct: 90,
  grade: 'A',
  student: 'Aditya Pawar',
  course: 'DBMS',
  marks: 80
}
{
  dept: 'AIML',
  attendance_pct: 92.11,
  grade: 'A',
  student: 'Neha Gaikwad',
  course: 'DAA',
  marks: 76
}
{
  dept: 'AIML',
  attendance_pct: 97.5,
  grade: 'O',
  student: 'Neha Gaikwad',
  course: 'DBMS',
  marks: 92
}
{
  dept: 'CSE',
  attendance_pct: 83.33,
  grade: 'B',
  student: 'Omkar Salunkhe',
  course: 'Operating Systems',
  marks: 70
}
{
  dept: 'AIML',
  attendance_pct: 62.5,
  grade: 'F',
  student: 'Priya Mane',
  course: 'DBMS',
  marks: 35
}

### Task 4 - SGPA = sum(credits x grade points) / sum(credits); O=10 A=9 B=8 C=6 F=0
{ _id: 'S101', name: 'Aditya Pawar', credits: 8, sgpa: 7.5 }
{ _id: 'S102', name: 'Neha Gaikwad', credits: 8, sgpa: 9.5 }
{ _id: 'S103', name: 'Omkar Salunkhe', credits: 3, sgpa: 8 }
{ _id: 'S104', name: 'Priya Mane', credits: 4, sgpa: 0 }

### Task 5 - Class topper by SGPA
{ _id: 'S102', name: 'Neha Gaikwad', sgpa: 9.5 }

### Task 6 - Report card of S102 only
{
  _id: 'S102',
  name: 'Neha Gaikwad',
  dept: 'AIML',
  semester: 3,
  phone: '9822022222',
  courses: [
    { course: 'DBMS', credits: 4, marks: 92, attendance_pct: 97.5, grade: 'O', points: 10 },
    { course: 'DAA', credits: 4, marks: 76, attendance_pct: 92.11, grade: 'A', points: 9 }
  ],
  credits: 8,
  sgpa: 9.5,
  result: 'Pass',
  remark: 'Eligible'
}

### Task 7 - Result: Pass / Fail (fail if any course < 40)
{ _id: 'S101', name: 'Aditya Pawar', result: 'Pass' }
{ _id: 'S102', name: 'Neha Gaikwad', result: 'Pass' }
{ _id: 'S103', name: 'Omkar Salunkhe', result: 'Pass' }
{ _id: 'S104', name: 'Priya Mane', result: 'Fail' }

### Task 8 - 'Detained' remark where attendance < 75 % in any course
{ _id: 'S101', name: 'Aditya Pawar', result: 'Pass', min_attendance_note: 'Detained' }
{ _id: 'S102', name: 'Neha Gaikwad', result: 'Pass', min_attendance_note: 'Eligible' }
{ _id: 'S103', name: 'Omkar Salunkhe', result: 'Pass', min_attendance_note: 'Eligible' }
{ _id: 'S104', name: 'Priya Mane', result: 'Fail', min_attendance_note: 'Detained' }

### Task 9 - Store the report as a new collection report_cards with $out
report_cards documents: 4
{ _id: 'S101', name: 'Aditya Pawar', sgpa: 7.5, result: 'Pass', remark: 'Detained' }
{ _id: 'S102', name: 'Neha Gaikwad', sgpa: 9.5, result: 'Pass', remark: 'Eligible' }
{ _id: 'S103', name: 'Omkar Salunkhe', sgpa: 8, result: 'Pass', remark: 'Eligible' }
{ _id: 'S104', name: 'Priya Mane', sgpa: 0, result: 'Fail', remark: 'Detained' }

### Task 10 - Export report_cards to CSV (mongosh + Node fs; alternative: the mongoexport command shown below)
written report_cards.csv with 4 rows:
_id,name,dept,semester,sgpa,result,remark
"S101","Aditya Pawar","AIML","3","7.5","Pass","Detained"
"S102","Neha Gaikwad","AIML","3","9.5","Pass","Eligible"
"S103","Omkar Salunkhe","CSE","5","8","Pass","Eligible"
"S104","Priya Mane","AIML","3","0","Fail","Detained"

### Task 11 - Update a student's phone number and show it in the next report run
phone in report before: 9822011111
phone in report after : 9999900000
```

## `crud.js`

```text
### Task crud - students: create, read, update, delete
{ _id: 'S999', name: 'Temp Student', dept: 'CSE' }
{ _id: 'S999', name: 'Temp Student', dept: 'AIML' }
{ acknowledged: true, deletedCount: 1 }

### Task crud - courses: create, read, update, delete
{ _id: 'CX', name: 'Temp Course', credits: 3, faculty: 'Dr. Temp', semester: 3 }
{ acknowledged: true, deletedCount: 1 }

### Task crud - attendance: create, read, update, delete
{ student_id: 'S999', course_id: 'C1', total: 11, attended: 10 }
{ acknowledged: true, deletedCount: 1 }

### Task crud - exams: create, read, update, delete (with a negative test)
{ student_id: 'S999', course_id: 'C1', ise: 10, ese: 20, total: 30, grade: 'F' }
ese 99 rejected -> code 121: Document failed validation
{ acknowledged: true, deletedCount: 1 }
counts: students=4, courses=3, attendance=6, exams=6
```

## `indexes.js`

```text
### Task 12 - explain() of the lookup access path BEFORE the indexes
{ collection: 'exams', stage: 'COLLSCAN', nReturned: 2, totalDocsExamined: 6 }
{ collection: 'attendance', stage: 'COLLSCAN', nReturned: 2, totalDocsExamined: 6 }

### Task 12 - Create {student_id: 1, course_id: 1} on exams and attendance, explain again
created: student_id_1_course_id_1 student_id_1_course_id_1
{ collection: 'exams', stage: 'IXSCAN', nReturned: 2, totalDocsExamined: 2 }
{ collection: 'attendance', stage: 'IXSCAN', nReturned: 2, totalDocsExamined: 2 }
-- In a real MongoDB 7 shell you can also explain the whole report: db.students.explain('executionStats').aggregate([...]) and compare totalDocsExamined of each $lookup stage.
```

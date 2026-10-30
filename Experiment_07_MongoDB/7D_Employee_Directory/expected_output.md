# Expected output - Experiment_07_MongoDB / 7D_Employee_Directory

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create collection employees (validated)
collections: [ 'employees' ]

### Task 1 - Negative test: PIN code with 5 digits
code 121: Document failed validation
```

## `insert_data.js`

```text
### Task 1 - Insert the employees
count: 4
{
  emp_id: 1,
  name: 'Anil',
  dept: 'IT',
  salary: 60000,
  skills: [ 'Python', 'SQL' ],
  address: { city: 'Pune', pin: '411001' }
}
{
  emp_id: 2,
  name: 'Bharti',
  dept: 'IT',
  salary: 55000,
  skills: [ 'Java', 'SQL' ],
  address: { city: 'Sangli', pin: '416416' }
}
{
  emp_id: 3,
  name: 'Chirag',
  dept: 'HR',
  salary: 40000,
  skills: [ 'Excel' ],
  address: { city: 'Pune', pin: '411038' }
}
{
  emp_id: 4,
  name: 'Deepa',
  dept: 'Sales',
  salary: 45000,
  skills: [ 'Excel', 'CRM' ],
  address: { city: 'Kolhapur', pin: '416003' }
}
```

## `queries.js`

```text
### Task 2 - Employees in Pune who know SQL
{ name: 'Anil' }

### Task 3 - Employees who have BOTH Python and SQL ($all)
{ name: 'Anil', skills: [ 'Python', 'SQL' ] }

### Task 4 - Employees whose salary is NOT between 40000 and 60000 ($not / $nin)
-- inclusive range [40000, 60000]: every salary of the data set lies inside, so nobody is outside:
-- exclusive range (40000, 60000): the two boundary salaries are 'not between':
{ name: 'Anil', salary: 60000 }
{ name: 'Chirag', salary: 40000 }
-- $nin (not in a list of values):
{ name: 'Anil', salary: 60000 }

### Task 5 - Name and city only, sorted by name
{ name: 'Anil', address: { city: 'Pune' } }
{ name: 'Bharti', address: { city: 'Sangli' } }
{ name: 'Chirag', address: { city: 'Pune' } }
{ name: 'Deepa', address: { city: 'Kolhapur' } }
```

## `aggregation.js`

```text
### Task 6 - Department-wise average and maximum salary, sorted by average (highest first)
{ _id: 'IT', avg_salary: 57500, max_salary: 60000, employees: 2 }
{ _id: 'Sales', avg_salary: 45000, max_salary: 45000, employees: 1 }
{ _id: 'HR', avg_salary: 40000, max_salary: 40000, employees: 1 }

### Task 7 - Number of employees per city
{ _id: 'Pune', employees: 2 }
{ _id: 'Kolhapur', employees: 1 }
{ _id: 'Sangli', employees: 1 }
```

## `crud.js`

```text
### Task 8 - Add skill 'MongoDB' to all IT employees ($push)
{
  acknowledged: true,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0,
  upsertedId: null
}
{ name: 'Anil', skills: [ 'Python', 'SQL', 'MongoDB' ] }
{ name: 'Bharti', skills: [ 'Java', 'SQL', 'MongoDB' ] }

### Task 9 - Change Chirag's city to Satara (dot notation on the embedded document)
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ name: 'Chirag', address: { city: 'Satara', pin: '411038' } }

### Task 10 - Rename field salary to monthly_salary in all documents ($rename)
{
  acknowledged: true,
  matchedCount: 4,
  modifiedCount: 4,
  upsertedCount: 0,
  upsertedId: null
}
{ name: 'Anil', monthly_salary: 60000 }
{ name: 'Bharti', monthly_salary: 55000 }
{ name: 'Chirag', monthly_salary: 40000 }
{ name: 'Deepa', monthly_salary: 45000 }

### Task 12 - Delete employees of the Sales department and count the remaining documents
{ acknowledged: true, deletedCount: 1 }
remaining: 3
```

## `indexes.js`

```text
### Task 11 - Query on address.city without an index
{ stage: 'COLLSCAN', nReturned: 1, totalDocsExamined: 3 }

### Task 11 - Create the index on address.city, list indexes, test with explain()
created: address.city_1
{ v: 2, key: { _id: 1 }, name: '_id_' }
{ v: 2, key: { 'address.city': 1 }, name: 'address.city_1' }
{ stage: 'IXSCAN', nReturned: 1, totalDocsExamined: 1 }
```

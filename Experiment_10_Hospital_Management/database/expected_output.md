# Expected output - Experiment_10_Hospital_Management / database

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create the five collections with $jsonSchema validation
collections: [ 'appointments', 'billing', 'doctors', 'patients', 'prescriptions' ]

### Task 1 - Relationship diagram (references by id; embedded arrays: schedule, medicines, items)
appointments.patient_id -> patients._id | appointments.doctor_id -> doctors._id | prescriptions.appointment_id/patient_id/doctor_id -> appointments/patients/doctors
billing.patient_id -> patients._id | billing.appointment_id -> appointments._id   (many-to-one everywhere; see explanation.md for the Mermaid diagram)
```

## `insert_data.js`

```text
### Task 2 - Insert the sample data (hospitalDB)
patients       3
doctors        3
appointments   4
prescriptions  3
billing        3

### Task 2 - Negative test: a bill with total -100 is rejected
code 121 (DocumentValidationFailure): Document failed validation
-- more negative tests (invalid phone, invalid status):
phone '12345' -> code 121: Document failed validation
status 'Postponed' -> code 121: Document failed validation

### Task 3 - Book a new appointment for PT03 with D3 and generate its bill
{
  _id: 'A1005',
  patient_id: 'PT03',
  doctor_id: 'D3',
  date: ISODate('2026-10-29T10:00:00.000Z'),
  status: 'Scheduled',
  reason: 'General check-up'
}
{
  _id: 'BL04',
  patient_id: 'PT03',
  appointment_id: 'A1005',
  items: [ { desc: 'Consultation', amount: 300 } ],
  total: 300,
  status: 'Pending',
  date: ISODate('2026-10-29T00:00:00.000Z')
}
```

## `queries.js`

```text
### Task 4 - All appointments of Dr. Anjali Deshmukh (D1) for today, with patient names ($lookup)
{
  _id: 'A1001',
  reason: 'Chest pain',
  status: 'Completed',
  time: ISODate('2026-10-27T10:30:00.000Z'),
  doctor: 'Dr. Anjali Deshmukh',
  patient: 'Ramesh Jadhav'
}

### Task 5 - Complete history of PT01: appointments, diagnoses, medicines and bills in ONE aggregation
{
  _id: 'PT01',
  name: 'Ramesh Jadhav',
  past_conditions: [ 'Hypertension' ],
  appointments: [
    {
      id: 'A1001',
      date: ISODate('2026-10-27T10:30:00.000Z'),
      doctor_id: 'D1',
      reason: 'Chest pain',
      status: 'Completed'
    }
  ],
  diagnoses: [ 'Angina' ],
  medicines: [
    { name: 'Aspirin 75', dose: '1-0-0', days: 30 },
    { name: 'Atorvastatin 10', dose: '0-0-1', days: 30 }
  ],
  bills: [ { id: 'BL01', total: 1000, status: 'Paid' } ],
  total_billed: 1000
}

### Task 6 - All unpaid bills with patient name and phone, and the total pending amount
{
  _id: 'BL02',
  appointment_id: 'A1002',
  total: 300,
  patient: 'Sunita More',
  phone: '9765022222'
}
{
  _id: 'BL03',
  appointment_id: 'A1004',
  total: 900,
  patient: 'Vikram Shinde',
  phone: '9765033333'
}
{
  _id: 'BL04',
  appointment_id: 'A1005',
  total: 300,
  patient: 'Vikram Shinde',
  phone: '9765033333'
}
total pending: [{"_id":null,"total_pending":1500,"bills":3}]
```

## `aggregation.js`

```text
### Task 7 - The 5 most prescribed medicines ($unwind on medicines)
{ _id: 'Aspirin 75', prescribed: 2, total_days: 60 }
{ _id: 'Atorvastatin 10', prescribed: 1, total_days: 30 }
{ _id: 'Metoprolol 25', prescribed: 1, total_days: 30 }
{ _id: 'Paracetamol 500', prescribed: 1, total_days: 3 }

### Task 8 - Doctor-wise number of (distinct) patients and revenue
{
  _id: 'D1',
  appointments: 2,
  pending: 900,
  doctor: 'Dr. Anjali Deshmukh',
  patients: 2,
  revenue_paid: 1000
}
{
  _id: 'D2',
  appointments: 1,
  pending: 0,
  doctor: 'Dr. Rahul Kulkarni',
  patients: 1,
  revenue_paid: 0
}
{
  _id: 'D3',
  appointments: 2,
  pending: 600,
  doctor: 'Dr. Sneha Patil',
  patients: 2,
  revenue_paid: 0
}

### Task dash - The four dashboard pipelines (same ones used by dashboard/app.py)
-- 1. appointments per hour (line chart)
{ _id: 9, appointments: 1 }
{ _id: 10, appointments: 2 }
{ _id: 11, appointments: 1 }
{ _id: 12, appointments: 1 }
-- 2. patients per doctor (bar chart)
{ _id: 'D1', patients: 2 }
{ _id: 'D2', patients: 1 }
{ _id: 'D3', patients: 2 }
-- 3. daily revenue paid vs pending (stacked bar)
{ _id: { day: '2026-10-27', status: 'Paid' }, amount: 1000 }
{ _id: { day: '2026-10-27', status: 'Pending' }, amount: 300 }
{ _id: { day: '2026-10-28', status: 'Pending' }, amount: 900 }
{ _id: { day: '2026-10-29', status: 'Pending' }, amount: 300 }
-- 4. top 5 diagnoses (bar chart)
{ _id: 'Angina', cases: 1 }
{ _id: 'Arrhythmia', cases: 1 }
{ _id: 'Viral fever', cases: 1 }
```

## `crud.js`

```text
### Task 9 - Cancel appointment A1003 and mark its bill 'Cancelled'
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ _id: 'A1003', status: 'Cancelled' }
{ _id: 'BL05', status: 'Cancelled', total: 500 }

### Task crud-patients - Create, read, update, delete a patient
{ _id: 'PT99', name: 'Temp Patient', contact: { phone: '9000000099' } }
{ _id: 'PT99', history: [ 'Asthma' ], contact: { city: 'Satara' } }
{ acknowledged: true, deletedCount: 1 }

### Task crud-doctors - Create, read, update, delete a doctor (embedded schedule)
{
  _id: 'D99',
  fee: 500,
  schedule: [
    { day: 'Fri', from: '10:00', to: '12:00' },
    { day: 'Sat', from: '10:00', to: '12:00' }
  ]
}
{ acknowledged: true, deletedCount: 1 }

### Task crud-appointments - Create, read, update, delete an appointment
{ _id: 'A9999', status: 'Completed', reason: 'Follow-up' }
{ acknowledged: true, deletedCount: 1 }

### Task crud-prescriptions - Create, read, update, delete a prescription (embedded medicine list)
{
  _id: 'RX99',
  medicines: [
    { name: 'Vitamin D3', dose: '1-0-0', days: 10 },
    { name: 'Calcium', dose: '0-0-1', days: 10 }
  ]
}
invalid dose format -> code 121: Document failed validation
{ acknowledged: true, deletedCount: 1 }

### Task crud-billing - Create, read, update (pay), delete a bill
{ _id: 'BL99', total: 250, status: 'Paid' }
{ acknowledged: true, deletedCount: 1 }
counts: patients=3, doctors=3, appointments=5, prescriptions=3, billing=5
```

## `indexes.js`

```text
### Task 10 - explain() BEFORE the indexes
{ collection: 'appointments', stage: 'COLLSCAN', nReturned: 1, totalDocsExamined: 5 }
{ collection: 'billing', stage: 'COLLSCAN', nReturned: 3, totalDocsExamined: 5 }

### Task 10 - Create the indexes
doctor_id_1_date_1
patient_id_1
status_1
patient_id_1
patient_id_1
medicines.name_1

### Task 10 - explain() AFTER the indexes
{ collection: 'appointments', stage: 'IXSCAN', nReturned: 1, totalDocsExamined: 1 }
{ collection: 'billing', stage: 'IXSCAN', nReturned: 3, totalDocsExamined: 3 }
appointments: _id_, doctor_id_1_date_1, patient_id_1
billing: _id_, status_1, patient_id_1
prescriptions: _id_, patient_id_1, medicines.name_1
```

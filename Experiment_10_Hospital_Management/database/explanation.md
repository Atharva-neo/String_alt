# Explanation - Experiment 10 database (hospitalDB)

## Schema design: one sample document per collection and the references

```mermaid
erDiagram
    PATIENTS     ||--o{ APPOINTMENTS  : "patient_id"
    DOCTORS      ||--o{ APPOINTMENTS  : "doctor_id"
    APPOINTMENTS ||--o| PRESCRIPTIONS : "appointment_id"
    PATIENTS     ||--o{ PRESCRIPTIONS : "patient_id"
    DOCTORS      ||--o{ PRESCRIPTIONS : "doctor_id"
    APPOINTMENTS ||--o| BILLING       : "appointment_id"
    PATIENTS     ||--o{ BILLING       : "patient_id"
    PATIENTS { string _id PK
               string name
               int age
               string gender
               string blood_group
               object contact "phone required, city"
               array history }
    DOCTORS { string _id PK
              string name
              string specialization
              int fee
              string phone
              array schedule "embedded day/from/to" }
    APPOINTMENTS { string _id PK
                   string patient_id FK
                   string doctor_id FK
                   date date
                   string status "Scheduled/Completed/Cancelled"
                   string reason }
    PRESCRIPTIONS { string _id PK
                    string appointment_id FK
                    string patient_id FK
                    string doctor_id FK
                    string diagnosis
                    array medicines "embedded name/dose/days" }
    BILLING { string _id PK
              string patient_id FK
              string appointment_id FK
              array items "embedded desc/amount"
              int total "> 0"
              string status "Paid/Pending/Cancelled"
              date date }
```

Embedded (never queried alone, bounded): `contact`, `history`, `schedule`, `medicines`, `items`. Referenced (shared / grow independently): patients, doctors, appointments. A prescription and a bill belong to exactly one appointment.

## Task map

| PDF task | Where | Notes |
|---|---|---|
| 1 five collections with `$jsonSchema` | `schema.js` | patient name + phone required, phone = 10 digits, bill total > 0 (`exclusiveMinimum`), appointment status enum |
| 2 CRUD for every collection; invalid bill | `crud.js`, `insert_data.js` | total -100 -> error 121 DocumentValidationFailure |
| 3 book appointment + bill | `insert_data.js` | bill amount = doctor's fee |
| 4 doctor's appointments today with names | `queries.js` | `$match` day range, 2x `$lookup` |
| 5 patient history in one aggregation | `queries.js` | `$lookup` appointments, prescriptions, billing + `$map`/`$reduce` |
| 6 unpaid bills + total pending | `queries.js` | |
| 7 most prescribed medicines | `aggregation.js` | `$unwind medicines` |
| 8 doctor-wise patients and revenue | `aggregation.js` | distinct patients via `$addToSet`; revenue = paid bills |
| 9 cancel A1003 and its bill | `crud.js` | the sample has no bill for A1003: the script creates BL05 first |
| 10 indexes + explain | `indexes.js` | `{doctor_id, date}`, `{status}`, patient ids, multikey `medicines.name` |
| 11 generator + change stream | `../realtime/` | |
| 12 live dashboard | `../dashboard/` | |

Extra rows A1004, RX02, RX03, BL03 are the ones the Neo4j section of the PDF adds; they are loaded so that MongoDB and the graph hold the same data.

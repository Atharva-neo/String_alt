// Experiment 10 - Task 1 (schema design + validation): the five collections of hospitalDB with $jsonSchema
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create the five collections with $jsonSchema validation");
["patients", "doctors", "appointments", "prescriptions", "billing"].forEach(c => db.getCollection(c).drop());

db.createCollection("patients", { validator: { $jsonSchema: {
  bsonType: "object", required: ["name", "contact"],                                   // patient name and phone are required
  properties: {
    name: { bsonType: "string", minLength: 2 }, age: { bsonType: "int", minimum: 0, maximum: 120 }, gender: { enum: ["M", "F"] },
    blood_group: { enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"] },
    contact: { bsonType: "object", required: ["phone"], properties: { phone: { bsonType: "string", pattern: "^[0-9]{10}$" }, city: { bsonType: "string" } } },   // valid phone = 10 digits
    history: { bsonType: "array", items: { bsonType: "string" } }
  } } } });

db.createCollection("doctors", { validator: { $jsonSchema: {
  bsonType: "object", required: ["name", "specialization", "fee", "phone"],
  properties: {
    name: { bsonType: "string" }, specialization: { bsonType: "string" }, fee: { bsonType: "int", minimum: 1 },
    phone: { bsonType: "string", pattern: "^[0-9]{10}$" },
    schedule: { bsonType: "array", items: { bsonType: "object", required: ["day", "from", "to"], properties: { day: { bsonType: "string" }, from: { bsonType: "string" }, to: { bsonType: "string" } } } }
  } } } });

db.createCollection("appointments", { validator: { $jsonSchema: {
  bsonType: "object", required: ["patient_id", "doctor_id", "date", "status"],
  properties: {
    patient_id: { bsonType: "string" }, doctor_id: { bsonType: "string" }, date: { bsonType: "date" },
    status: { enum: ["Scheduled", "Completed", "Cancelled"] },                          // status in Scheduled / Completed / Cancelled
    reason: { bsonType: "string" }
  } } } });

db.createCollection("prescriptions", { validator: { $jsonSchema: {
  bsonType: "object", required: ["appointment_id", "patient_id", "doctor_id", "diagnosis", "medicines"],
  properties: {
    appointment_id: { bsonType: "string" }, patient_id: { bsonType: "string" }, doctor_id: { bsonType: "string" }, diagnosis: { bsonType: "string" },
    medicines: { bsonType: "array", minItems: 1,                                         // embedded medicine list
                 items: { bsonType: "object", required: ["name", "dose", "days"], properties: { name: { bsonType: "string" }, dose: { bsonType: "string", pattern: "^[0-9]-[0-9]-[0-9]$" }, days: { bsonType: "int", minimum: 1 } } } }
  } } } });

db.createCollection("billing", { validator: { $jsonSchema: {
  bsonType: "object", required: ["patient_id", "appointment_id", "items", "total", "status", "date"],
  properties: {
    patient_id: { bsonType: "string" }, appointment_id: { bsonType: "string" },
    items: { bsonType: "array", minItems: 1, items: { bsonType: "object", required: ["desc", "amount"], properties: { desc: { bsonType: "string" }, amount: { bsonType: ["int", "double"], minimum: 0, exclusiveMinimum: true } } } },
    total: { bsonType: ["int", "double"], minimum: 0, exclusiveMinimum: true },          // bill total must be > 0
    status: { enum: ["Paid", "Pending", "Cancelled"] }, date: { bsonType: "date" }
  } } } });
print("collections:", db.getCollectionNames());

task(1, "Relationship diagram (references by id; embedded arrays: schedule, medicines, items)");
print("appointments.patient_id -> patients._id | appointments.doctor_id -> doctors._id | prescriptions.appointment_id/patient_id/doctor_id -> appointments/patients/doctors");
print("billing.patient_id -> patients._id | billing.appointment_id -> appointments._id   (many-to-one everywhere; see explanation.md for the Mermaid diagram)");

// Experiment 10 - Tasks 2 and 3: insert the sample data of the PDF, show the validation error, book a new appointment and generate its bill
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(2, "Insert the sample data (hospitalDB)");
["patients", "doctors", "appointments", "prescriptions", "billing"].forEach(c => db.getCollection(c).deleteMany({}));
db.doctors.insertMany([
  { _id: "D1", name: "Dr. Anjali Deshmukh", specialization: "Cardiology", fee: 600, phone: "9890011111", schedule: [ { day: "Mon", from: "10:00", to: "14:00" }, { day: "Thu", from: "10:00", to: "14:00" } ] },
  { _id: "D2", name: "Dr. Rahul Kulkarni", specialization: "Orthopedics", fee: 500, phone: "9890022222", schedule: [ { day: "Tue", from: "09:00", to: "13:00" } ] },
  { _id: "D3", name: "Dr. Sneha Patil", specialization: "General Medicine", fee: 300, phone: "9890033333", schedule: [ { day: "Mon-Sat", from: "09:00", to: "17:00" } ] }
]);
db.patients.insertMany([
  { _id: "PT01", name: "Ramesh Jadhav", age: 58, gender: "M", blood_group: "B+", contact: { phone: "9765011111", city: "Sangli" }, history: ["Hypertension"] },
  { _id: "PT02", name: "Sunita More", age: 34, gender: "F", blood_group: "O+", contact: { phone: "9765022222", city: "Miraj" }, history: [] },
  { _id: "PT03", name: "Vikram Shinde", age: 45, gender: "M", blood_group: "A+", contact: { phone: "9765033333", city: "Kolhapur" }, history: ["Diabetes"] }
]);
db.appointments.insertMany([
  { _id: "A1001", patient_id: "PT01", doctor_id: "D1", date: ISODate("2026-10-27T10:30:00Z"), status: "Completed", reason: "Chest pain" },
  { _id: "A1002", patient_id: "PT02", doctor_id: "D3", date: ISODate("2026-10-27T11:00:00Z"), status: "Scheduled", reason: "Fever" },
  { _id: "A1003", patient_id: "PT03", doctor_id: "D2", date: ISODate("2026-10-28T09:30:00Z"), status: "Scheduled", reason: "Knee pain" }
]);
db.prescriptions.insertOne({ _id: "RX01", appointment_id: "A1001", patient_id: "PT01", doctor_id: "D1", diagnosis: "Angina",
  medicines: [ { name: "Aspirin 75", dose: "1-0-0", days: 30 }, { name: "Atorvastatin 10", dose: "0-0-1", days: 30 } ] });
db.billing.insertMany([
  { _id: "BL01", patient_id: "PT01", appointment_id: "A1001", items: [ { desc: "Consultation", amount: 600 }, { desc: "ECG", amount: 400 } ], total: 1000, status: "Paid", date: ISODate("2026-10-27") },
  { _id: "BL02", patient_id: "PT02", appointment_id: "A1002", items: [ { desc: "Consultation", amount: 300 } ], total: 300, status: "Pending", date: ISODate("2026-10-27") }
]);
// Extra rows that exist in the Neo4j sample (appointment A1004, prescriptions RX02-RX03, bill BL03) so that MongoDB and the graph hold the same data.
db.appointments.insertOne({ _id: "A1004", patient_id: "PT03", doctor_id: "D1", date: ISODate("2026-10-28T12:00:00Z"), status: "Completed", reason: "Palpitations" });
db.prescriptions.insertMany([
  { _id: "RX02", appointment_id: "A1002", patient_id: "PT02", doctor_id: "D3", diagnosis: "Viral fever", medicines: [ { name: "Paracetamol 500", dose: "1-1-1", days: 3 } ] },
  { _id: "RX03", appointment_id: "A1004", patient_id: "PT03", doctor_id: "D1", diagnosis: "Arrhythmia", medicines: [ { name: "Aspirin 75", dose: "1-0-0", days: 30 }, { name: "Metoprolol 25", dose: "1-0-1", days: 30 } ] }
]);
db.billing.insertOne({ _id: "BL03", patient_id: "PT03", appointment_id: "A1004", items: [ { desc: "Consultation", amount: 600 }, { desc: "Holter test", amount: 300 } ], total: 900, status: "Pending", date: ISODate("2026-10-28") });
["patients", "doctors", "appointments", "prescriptions", "billing"].forEach(c => print(c.padEnd(14), db.getCollection(c).countDocuments()));

task(2, "Negative test: a bill with total -100 is rejected");
try { db.billing.insertOne({ _id: "BLX", patient_id: "PT01", appointment_id: "A1001", items: [ { desc: "Refund", amount: 100 } ], total: -100, status: "Pending", date: new Date() }); }
catch (e) { print("code " + e.code + " (" + e.codeName + "): " + e.message); }
print("-- more negative tests (invalid phone, invalid status):");
try { db.patients.insertOne({ _id: "PTX", name: "Bad Phone", contact: { phone: "12345" } }); } catch (e) { print("phone '12345' -> code " + e.code + ": " + e.message); }
try { db.appointments.insertOne({ _id: "AX", patient_id: "PT01", doctor_id: "D1", date: new Date(), status: "Postponed" }); } catch (e) { print("status 'Postponed' -> code " + e.code + ": " + e.message); }

task(3, "Book a new appointment for PT03 with D3 and generate its bill");
// the bill amount comes from the doctor's fee (one consultation item), status Pending until paid
const doc3 = db.doctors.findOne({ _id: "D3" });
db.appointments.insertOne({ _id: "A1005", patient_id: "PT03", doctor_id: "D3", date: ISODate("2026-10-29T10:00:00Z"), status: "Scheduled", reason: "General check-up" });
db.billing.insertOne({ _id: "BL04", patient_id: "PT03", appointment_id: "A1005", items: [ { desc: "Consultation", amount: doc3.fee } ], total: doc3.fee, status: "Pending", date: ISODate("2026-10-29") });
printjson(db.appointments.findOne({ _id: "A1005" }));
printjson(db.billing.findOne({ _id: "BL04" }));

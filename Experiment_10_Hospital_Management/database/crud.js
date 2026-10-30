// Experiment 10 - Task 2 (CRUD for every collection) and Task 9 (cancel appointment A1003 and mark its bill 'Cancelled')
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(9, "Cancel appointment A1003 and mark its bill 'Cancelled'");
// A1003 has no bill in the sample data: create the pending bill first so that the cancellation of both can be shown
db.billing.deleteOne({ _id: "BL05" });
db.billing.insertOne({ _id: "BL05", patient_id: "PT03", appointment_id: "A1003", items: [ { desc: "Consultation", amount: 500 } ], total: 500, status: "Pending", date: ISODate("2026-10-28") });
printjson(db.appointments.updateOne({ _id: "A1003" }, { $set: { status: "Cancelled" } }));
printjson(db.billing.updateMany({ appointment_id: "A1003" }, { $set: { status: "Cancelled" } }));
printjson(db.appointments.findOne({ _id: "A1003" }, { status: 1 }));
printjson(db.billing.findOne({ appointment_id: "A1003" }, { status: 1, total: 1 }));

task("crud-patients", "Create, read, update, delete a patient");
db.patients.insertOne({ _id: "PT99", name: "Temp Patient", age: 30, gender: "F", blood_group: "O-", contact: { phone: "9000000099", city: "Pune" }, history: [] });
printjson(db.patients.findOne({ _id: "PT99" }, { name: 1, "contact.phone": 1 }));
db.patients.updateOne({ _id: "PT99" }, { $push: { history: "Asthma" }, $set: { "contact.city": "Satara" } });
printjson(db.patients.findOne({ _id: "PT99" }, { history: 1, "contact.city": 1 }));
printjson(db.patients.deleteOne({ _id: "PT99" }));

task("crud-doctors", "Create, read, update, delete a doctor (embedded schedule)");
db.doctors.insertOne({ _id: "D99", name: "Dr. Temp", specialization: "ENT", fee: 400, phone: "9890099999", schedule: [ { day: "Fri", from: "10:00", to: "12:00" } ] });
db.doctors.updateOne({ _id: "D99" }, { $push: { schedule: { day: "Sat", from: "10:00", to: "12:00" } }, $inc: { fee: 100 } });
printjson(db.doctors.findOne({ _id: "D99" }, { fee: 1, schedule: 1 }));
printjson(db.doctors.deleteOne({ _id: "D99" }));

task("crud-appointments", "Create, read, update, delete an appointment");
db.appointments.insertOne({ _id: "A9999", patient_id: "PT02", doctor_id: "D3", date: ISODate("2026-11-01T09:00:00Z"), status: "Scheduled", reason: "Follow-up" });
db.appointments.updateOne({ _id: "A9999" }, { $set: { status: "Completed" } });
printjson(db.appointments.findOne({ _id: "A9999" }, { status: 1, reason: 1 }));
printjson(db.appointments.deleteOne({ _id: "A9999" }));

task("crud-prescriptions", "Create, read, update, delete a prescription (embedded medicine list)");
db.prescriptions.insertOne({ _id: "RX99", appointment_id: "A1001", patient_id: "PT01", doctor_id: "D1", diagnosis: "Check", medicines: [ { name: "Vitamin D3", dose: "1-0-0", days: 10 } ] });
db.prescriptions.updateOne({ _id: "RX99" }, { $push: { medicines: { name: "Calcium", dose: "0-0-1", days: 10 } } });
printjson(db.prescriptions.findOne({ _id: "RX99" }, { medicines: 1 }));
try { db.prescriptions.updateOne({ _id: "RX99" }, { $set: { "medicines.0.dose": "morning" } }); } catch (e) { print("invalid dose format -> code " + e.code + ": " + e.message); }
printjson(db.prescriptions.deleteOne({ _id: "RX99" }));

task("crud-billing", "Create, read, update (pay), delete a bill");
db.billing.insertOne({ _id: "BL99", patient_id: "PT02", appointment_id: "A1002", items: [ { desc: "Lab test", amount: 250 } ], total: 250, status: "Pending", date: ISODate("2026-10-27") });
db.billing.updateOne({ _id: "BL99" }, { $set: { status: "Paid" } });
printjson(db.billing.findOne({ _id: "BL99" }, { total: 1, status: 1 }));
printjson(db.billing.deleteOne({ _id: "BL99" }));
print("counts:", ["patients", "doctors", "appointments", "prescriptions", "billing"].map(c => c + "=" + db.getCollection(c).countDocuments()).join(", "));

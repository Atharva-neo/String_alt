// Experiment 10 - Task 10 (and requirement 4): indexes on patient id, doctor id and appointment date; explain() before / after
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }
function plan(coll, q) {
  const e = db.getCollection(coll).find(q).explain("executionStats");
  return { collection: coll, stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined };
}
const qAppt = { doctor_id: "D1", date: { $gte: ISODate("2026-10-27"), $lt: ISODate("2026-10-28") } };
const qBill = { status: "Pending" };

task(10, "explain() BEFORE the indexes");
["appointments", "billing"].forEach(c => db.getCollection(c).dropIndexes());
printjson(plan("appointments", qAppt));
printjson(plan("billing", qBill));

task(10, "Create the indexes");
print(db.appointments.createIndex({ doctor_id: 1, date: 1 }));                 // doctor's agenda: equality on doctor, range on date
print(db.appointments.createIndex({ patient_id: 1 }));                          // patient history
print(db.billing.createIndex({ status: 1 }));                                   // unpaid-bill report
print(db.billing.createIndex({ patient_id: 1 }));
print(db.prescriptions.createIndex({ patient_id: 1 }));
print(db.prescriptions.createIndex({ "medicines.name": 1 }));                   // multikey index on the embedded medicine list

task(10, "explain() AFTER the indexes");
printjson(plan("appointments", qAppt));
printjson(plan("billing", qBill));
["appointments", "billing", "prescriptions"].forEach(c => { print(c + ": " + db.getCollection(c).getIndexes().map(i => i.name).join(", ")); });

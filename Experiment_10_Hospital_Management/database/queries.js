// Experiment 10 - Tasks 4, 5, 6: doctor's appointments for a day, a patient's full history, unpaid bills
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

// "today" of the sample data is 2026-10-27. On a live system use:  const TODAY = new Date(new Date().setUTCHours(0,0,0,0));
const TODAY = ISODate("2026-10-27");
const TOMORROW = new Date(TODAY.getTime() + 24 * 3600 * 1000);

task(4, "All appointments of Dr. Anjali Deshmukh (D1) for today, with patient names ($lookup)");
db.appointments.aggregate([
  { $match: { doctor_id: "D1", date: { $gte: TODAY, $lt: TOMORROW } } },
  { $lookup: { from: "patients", localField: "patient_id", foreignField: "_id", as: "patient" } }, { $unwind: "$patient" },
  { $lookup: { from: "doctors", localField: "doctor_id", foreignField: "_id", as: "doctor" } }, { $unwind: "$doctor" },
  { $project: { _id: 1, time: "$date", doctor: "$doctor.name", patient: "$patient.name", reason: 1, status: 1 } },
  { $sort: { time: 1 } }
]).forEach(printjson);

task(5, "Complete history of PT01: appointments, diagnoses, medicines and bills in ONE aggregation");
db.patients.aggregate([
  { $match: { _id: "PT01" } },
  { $lookup: { from: "appointments",  localField: "_id", foreignField: "patient_id", as: "appointments" } },
  { $lookup: { from: "prescriptions", localField: "_id", foreignField: "patient_id", as: "prescriptions" } },
  { $lookup: { from: "billing",       localField: "_id", foreignField: "patient_id", as: "bills" } },
  { $project: { _id: 1, name: 1, past_conditions: "$history",
      appointments: { $map: { input: "$appointments", as: "a", in: { id: "$$a._id", date: "$$a.date", doctor_id: "$$a.doctor_id", reason: "$$a.reason", status: "$$a.status" } } },
      diagnoses: "$prescriptions.diagnosis",
      medicines: { $reduce: { input: "$prescriptions.medicines", initialValue: [], in: { $concatArrays: ["$$value", "$$this"] } } },
      bills: { $map: { input: "$bills", as: "b", in: { id: "$$b._id", total: "$$b.total", status: "$$b.status" } } },
      total_billed: { $sum: "$bills.total" } } }
]).forEach(printjson);

task(6, "All unpaid bills with patient name and phone, and the total pending amount");
db.billing.aggregate([
  { $match: { status: "Pending" } },
  { $lookup: { from: "patients", localField: "patient_id", foreignField: "_id", as: "p" } }, { $unwind: "$p" },
  { $project: { _id: 1, appointment_id: 1, total: 1, patient: "$p.name", phone: "$p.contact.phone" } },
  { $sort: { _id: 1 } }
]).forEach(printjson);
print("total pending:", JSON.stringify(db.billing.aggregate([{ $match: { status: "Pending" } }, { $group: { _id: null, total_pending: { $sum: "$total" }, bills: { $sum: 1 } } }]).toArray()));

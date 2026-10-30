// Experiment 10 - Tasks 7, 8: most prescribed medicines, doctor-wise patients and revenue (+ the four dashboard pipelines)
db = db.getSiblingDB("hospitalDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(7, "The 5 most prescribed medicines ($unwind on medicines)");
db.prescriptions.aggregate([
  { $unwind: "$medicines" },
  { $group: { _id: "$medicines.name", prescribed: { $sum: 1 }, total_days: { $sum: "$medicines.days" } } },
  { $sort: { prescribed: -1, _id: 1 } },
  { $limit: 5 }
]).forEach(printjson);

task(8, "Doctor-wise number of (distinct) patients and revenue");
// revenue = sum of PAID bills of the doctor's appointments; pending = still to be collected; Cancelled bills count for neither
db.appointments.aggregate([
  { $lookup: { from: "billing", localField: "_id", foreignField: "appointment_id", as: "bill" } },
  { $group: { _id: "$doctor_id", patients: { $addToSet: "$patient_id" }, appointments: { $sum: 1 },
              paid: { $sum: { $sum: { $map: { input: { $filter: { input: "$bill", as: "b", cond: { $eq: ["$$b.status", "Paid"] } } }, as: "b", in: "$$b.total" } } } },
              pending: { $sum: { $sum: { $map: { input: { $filter: { input: "$bill", as: "b", cond: { $eq: ["$$b.status", "Pending"] } } }, as: "b", in: "$$b.total" } } } } } },
  { $lookup: { from: "doctors", localField: "_id", foreignField: "_id", as: "d" } }, { $unwind: "$d" },
  { $project: { _id: 1, doctor: "$d.name", patients: { $size: "$patients" }, appointments: 1, revenue_paid: "$paid", pending: 1 } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

task("dash", "The four dashboard pipelines (same ones used by dashboard/app.py)");
print("-- 1. appointments per hour (line chart)");
db.appointments.aggregate([{ $group: { _id: { $hour: "$date" }, appointments: { $sum: 1 } } }, { $sort: { _id: 1 } }]).forEach(printjson);
print("-- 2. patients per doctor (bar chart)");
db.appointments.aggregate([{ $group: { _id: "$doctor_id", patients: { $addToSet: "$patient_id" } } }, { $project: { patients: { $size: "$patients" } } }, { $sort: { _id: 1 } }]).forEach(printjson);
print("-- 3. daily revenue paid vs pending (stacked bar)");
db.billing.aggregate([{ $match: { status: { $in: ["Paid", "Pending"] } } },
  { $group: { _id: { day: { $dateToString: { format: "%Y-%m-%d", date: "$date" } }, status: "$status" }, amount: { $sum: "$total" } } }, { $sort: { "_id.day": 1, "_id.status": 1 } }]).forEach(printjson);
print("-- 4. top 5 diagnoses (bar chart)");
db.prescriptions.aggregate([{ $group: { _id: "$diagnosis", cases: { $sum: 1 } } }, { $sort: { cases: -1, _id: 1 } }, { $limit: 5 }]).forEach(printjson);

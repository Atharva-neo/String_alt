// 9A Attendance report - Tasks 5, 6, 7, 9 (run before crud.js so the numbers are those of the PDF data)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

// attendance % = attended / total * 100, rounded to 2 decimals; defaulter = below 75 %
const withPct = { $set: { pct: { $round: [{ $multiply: [{ $divide: ["$attended", "$total"] }, 100] }, 2] } } };

task(5, "Attendance % for every student and course");
db.attendance.aggregate([withPct, { $project: { _id: 0, student_id: 1, course_id: 1, total: 1, attended: 1, pct: 1 } }, { $sort: { student_id: 1, course_id: 1 } }]).forEach(printjson);

task(6, "Defaulters (< 75 %) with student name and course name ($lookup)");
db.attendance.aggregate([
  withPct,
  { $match: { pct: { $lt: 75 } } },
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "student" } },
  { $lookup: { from: "courses",  localField: "course_id",  foreignField: "_id", as: "course" } },
  { $unwind: "$student" }, { $unwind: "$course" },
  { $project: { _id: 0, student: "$student.name", course: "$course.name", pct: 1 } },
  { $sort: { pct: 1 } }
]).forEach(printjson);

task(7, "Course-wise average attendance %");
db.attendance.aggregate([
  withPct,
  { $group: { _id: "$course_id", avg_pct: { $avg: "$pct" }, records: { $sum: 1 } } },
  { $lookup: { from: "courses", localField: "_id", foreignField: "_id", as: "c" } }, { $unwind: "$c" },
  { $project: { _id: 0, course: "$c.name", avg_pct: { $round: ["$avg_pct", 2] }, records: 1 } },
  { $sort: { course: 1 } }
]).forEach(printjson);

task(9, "Number of defaulters per department");
db.attendance.aggregate([
  withPct,
  { $match: { pct: { $lt: 75 } } },
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "s" } }, { $unwind: "$s" },
  { $group: { _id: "$s.dept", defaulter_records: { $sum: 1 }, students: { $addToSet: "$student_id" } } },
  { $project: { _id: 1, defaulter_records: 1, distinct_students: { $size: "$students" } } }
]).forEach(printjson);

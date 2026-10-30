// 9B Result analysis - Tasks 3, 4, 5, 8, 9 (run before crud.js, which assigns grades and revalues marks)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(3, "Course-wise average, highest and lowest total");
db.exams.aggregate([
  { $group: { _id: "$course_id", avg: { $avg: "$total" }, highest: { $max: "$total" }, lowest: { $min: "$total" }, students: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

task(4, "Course-wise pass percentage (pass = total >= 40)");
db.exams.aggregate([
  { $group: { _id: "$course_id", appeared: { $sum: 1 }, passed: { $sum: { $cond: [{ $gte: ["$total", 40] }, 1, 0] } } } },
  { $project: { appeared: 1, passed: 1, pass_percentage: { $round: [{ $multiply: [{ $divide: ["$passed", "$appeared"] }, 100] }, 2] } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

task(5, "Topper of each course with the student's name ($sort + $group/$first, then $lookup)");
db.exams.aggregate([
  { $sort: { total: -1 } },
  { $group: { _id: "$course_id", student_id: { $first: "$student_id" }, top_total: { $first: "$total" } } },
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "s" } }, { $unwind: "$s" },
  { $project: { _id: 0, course: "$_id", topper: "$s.name", top_total: 1 } },
  { $sort: { course: 1 } }
]).forEach(printjson);

task(8, "Students who scored above the course average");
db.exams.aggregate([
  { $setWindowFields: { partitionBy: "$course_id", output: { course_avg: { $avg: "$total", window: { documents: ["unbounded", "unbounded"] } } } } },
  { $match: { $expr: { $gt: ["$total", "$course_avg"] } } },
  { $project: { _id: 0, student_id: 1, course_id: 1, total: 1, course_avg: 1 } },
  { $sort: { course_id: 1, student_id: 1 } }
]).forEach(printjson);

task(9, "Faculty-wise average marks of their course");
db.exams.aggregate([
  { $group: { _id: "$course_id", avg_marks: { $avg: "$total" } } },
  { $lookup: { from: "courses", localField: "_id", foreignField: "_id", as: "c" } }, { $unwind: "$c" },
  { $project: { _id: 0, faculty: "$c.faculty", course: "$c.name", avg_marks: 1 } },
  { $sort: { faculty: 1 } }
]).forEach(printjson);

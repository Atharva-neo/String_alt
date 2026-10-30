// 9C Report card - Task 1: each student's courses with marks
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "List each student's courses with marks (exams grouped by student)");
db.exams.aggregate([
  { $group: { _id: "$student_id", courses: { $push: { course_id: "$course_id", total: "$total" } } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

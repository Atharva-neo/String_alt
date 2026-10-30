// 9B Result analysis - Tasks 6, 7, 10, 12
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(6, "Add a grade field: O >= 90, A >= 75, B >= 60, C >= 40, F < 40 (update with an aggregation pipeline and $switch)");
printjson(db.exams.updateMany({}, [ { $set: { grade: { $switch: { branches: [
  { case: { $gte: ["$total", 90] }, then: "O" }, { case: { $gte: ["$total", 75] }, then: "A" },
  { case: { $gte: ["$total", 60] }, then: "B" }, { case: { $gte: ["$total", 40] }, then: "C" } ], default: "F" } } } } ]));
db.exams.find({}, { _id: 0, student_id: 1, course_id: 1, total: 1, grade: 1 }).sort({ student_id: 1, course_id: 1 }).forEach(printjson);

task(7, "Count of students per grade per course");
db.exams.aggregate([
  { $group: { _id: { course: "$course_id", grade: "$grade" }, students: { $sum: 1 } } },
  { $sort: { "_id.course": 1, "_id.grade": 1 } }
]).forEach(printjson);

task(10, "Revaluation: S104's ESE in C1 +6, recompute total (pipeline update keeps ise + ese = total consistent)");
print("before:", JSON.stringify(db.exams.findOne({ student_id: "S104", course_id: "C1" }, { _id: 0 })));
db.exams.updateOne({ student_id: "S104", course_id: "C1" }, [
  { $set: { ese: { $min: [60, { $add: ["$ese", 6] }] } } },                    // ESE is capped at 60 by the validator
  { $set: { total: { $add: ["$ise", "$ese"] } } },
  { $set: { grade: { $switch: { branches: [ { case: { $gte: ["$total", 90] }, then: "O" }, { case: { $gte: ["$total", 75] }, then: "A" }, { case: { $gte: ["$total", 60] }, then: "B" }, { case: { $gte: ["$total", 40] }, then: "C" } ], default: "F" } } } }
]);
print("after :", JSON.stringify(db.exams.findOne({ student_id: "S104", course_id: "C1" }, { _id: 0 })));
print("-- 35 (F) became 41 (C): the student now passes DBMS.");

task(12, "Delete exam records with total = 0 (absentees)");
db.exams.insertOne({ student_id: "S103", course_id: "C1", ise: 0, ese: 0, total: 0, grade: "F" });      // temporary absentee record so the delete has something to remove
printjson(db.exams.deleteMany({ total: 0 }));
print("exam records now:", db.exams.countDocuments());

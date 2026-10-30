// 9A Attendance report - Task 11: compound index {student_id: 1, course_id: 1} on attendance
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

function plan() {
  const e = db.attendance.find({ student_id: "S101", course_id: "C2" }).explain("executionStats");
  return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined };
}
task(11, "Before the index");
db.attendance.dropIndexes();
printjson(plan());
task(11, "Create the compound index (unique: one attendance document per student and course) and compare");
print("created:", db.attendance.createIndex({ student_id: 1, course_id: 1 }, { unique: true }));
printjson(plan());
db.attendance.getIndexes().forEach(printjson);
task(11, "The unique index enforces 'one document per (student, course)'");
try { db.attendance.insertOne({ student_id: "S101", course_id: "C2", total: 1, attended: 1 }); } catch (e) { print("code " + e.code + ": " + e.message); }

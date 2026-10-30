// 9C Report card - Task 12: index to speed up the report and compare explain()
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }
// every $lookup of the report probes exams / attendance by student_id (and then filters by course): that is the access path to index
function plan(coll) {
  const e = db.getCollection(coll).find({ student_id: "S102" }).explain("executionStats");
  return { collection: coll, stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined };
}
task(12, "explain() of the lookup access path BEFORE the indexes");
db.exams.dropIndexes(); db.attendance.dropIndexes();
printjson(plan("exams")); printjson(plan("attendance"));
task(12, "Create {student_id: 1, course_id: 1} on exams and attendance, explain again");
print("created:", db.exams.createIndex({ student_id: 1, course_id: 1 }), db.attendance.createIndex({ student_id: 1, course_id: 1 }));
printjson(plan("exams")); printjson(plan("attendance"));
print("-- In a real MongoDB 7 shell you can also explain the whole report: db.students.explain('executionStats').aggregate([...]) and compare totalDocsExamined of each $lookup stage.");

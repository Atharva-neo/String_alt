// 9B Result analysis - supporting indexes and explain()
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }
function plan(q) { const e = db.exams.find(q).explain("executionStats"); return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined }; }

task("idx", "Index {course_id: 1, total: -1} supports 'toppers per course' and course-wise ranges");
db.exams.dropIndexes();
printjson(plan({ course_id: "C1" }));
print("created:", db.exams.createIndex({ course_id: 1, total: -1 }));
printjson(plan({ course_id: "C1" }));
print("created:", db.exams.createIndex({ student_id: 1, course_id: 1 }, { unique: true }));
db.exams.getIndexes().forEach(printjson);

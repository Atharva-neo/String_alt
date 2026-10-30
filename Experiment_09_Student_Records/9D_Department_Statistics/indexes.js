// 9D Department and semester statistics - supporting indexes (dept / semester grouping, city lookups)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }
function plan(q) { const e = db.students.find(q).explain("executionStats"); return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined }; }

task("idx", "Compound index {dept: 1, semester: 1} for the department / semester reports and an index on contact.city");
db.students.dropIndexes();
printjson(plan({ dept: "AIML", semester: 4 }));
print("created:", db.students.createIndex({ dept: 1, semester: 1 }), db.students.createIndex({ "contact.city": 1 }));
printjson(plan({ dept: "AIML", semester: 4 }));
db.students.getIndexes().forEach(i => print(i.name));

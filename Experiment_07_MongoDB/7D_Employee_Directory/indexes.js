// 7D Employee directory - Task 11: index on address.city, getIndexes(), explain()
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

function plan() {
  const e = db.employees.find({ "address.city": "Pune" }).explain("executionStats");
  return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN",
           nReturned: e.executionStats.nReturned, totalDocsExamined: e.executionStats.totalDocsExamined };
}
task(11, "Query on address.city without an index");
db.employees.dropIndexes();
printjson(plan());
task(11, "Create the index on address.city, list indexes, test with explain()");
print("created:", db.employees.createIndex({ "address.city": 1 }));
db.employees.getIndexes().forEach(printjson);
printjson(plan());

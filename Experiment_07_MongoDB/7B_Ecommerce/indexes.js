// 7B E-commerce - Task 10: execution statistics before / after a compound index {category: 1, price: 1}
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

const q = { category: "Electronics", price: { $gt: 400 } };
function stats() {
  const e = db.products.find(q).explain("executionStats");
  return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN",
           nReturned: e.executionStats.nReturned, totalKeysExamined: e.executionStats.totalKeysExamined, totalDocsExamined: e.executionStats.totalDocsExamined };
}

task(10, "Electronics products priced above 400: before the index");
db.products.dropIndexes();
printjson(stats());
task(10, "Create the compound index and run the query again");
print("created:", db.products.createIndex({ category: 1, price: 1 }));
printjson(stats());
print("-- COLLSCAN reads every document (4); IXSCAN reads only index entries of category 'Electronics' with price > 400 (2) and fetches just those documents.");
db.products.getIndexes().forEach(printjson);

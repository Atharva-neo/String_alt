// 7A Blog - single, compound and text indexes + explain() (common task of Experiment 7)
db = db.getSiblingDB("blogDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task("idx-1", "Query without an index: explain('executionStats')");
db.posts.dropIndexes();                                // keeps only the mandatory _id index
function stats(q) { const e = db.posts.find(q).explain("executionStats"); return { stage: JSON.stringify(e.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN" : "COLLSCAN", nReturned: e.executionStats.nReturned, totalKeysExamined: e.executionStats.totalKeysExamined, totalDocsExamined: e.executionStats.totalDocsExamined }; }
printjson(stats({ author: "Riya" }));

task("idx-2", "Single-field index on author, then the same query again");
print("created:", db.posts.createIndex({ author: 1 }));
printjson(stats({ author: "Riya" }));

task("idx-3", "Compound index {author: 1, date: -1} (equality field first, then the sort/range field)");
print("created:", db.posts.createIndex({ author: 1, date: -1 }));
db.posts.getIndexes().forEach(printjson);

task("idx-4", "Text index on title and a text search");
print("created:", db.posts.createIndex({ title: "text" }));
db.posts.find({ $text: { $search: "index" } }, { title: 1 }).forEach(printjson);

task("idx-5", "Unique index demonstration (title must be unique) and cleanup");
print("created:", db.posts.createIndex({ title: 1 }, { unique: true, name: "uq_title" }));
try { db.posts.insertOne({ title: "Python Tips", author: "x", tags: [], likes: 0, date: new Date(), comments: [] }); }
catch (e) { print("Duplicate title -> code " + e.code + ": " + e.message); }
db.posts.dropIndex("uq_title");
print("indexes now:", db.posts.getIndexes().map(i => i.name).join(", "));

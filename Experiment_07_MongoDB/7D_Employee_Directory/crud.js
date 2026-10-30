// 7D Employee directory - Tasks 8, 9, 10, 12
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(8, "Add skill 'MongoDB' to all IT employees ($push)");
printjson(db.employees.updateMany({ dept: "IT" }, { $push: { skills: "MongoDB" } }));
db.employees.find({ dept: "IT" }, { name: 1, skills: 1, _id: 0 }).forEach(printjson);

task(9, "Change Chirag's city to Satara (dot notation on the embedded document)");
printjson(db.employees.updateOne({ name: "Chirag" }, { $set: { "address.city": "Satara" } }));
printjson(db.employees.findOne({ name: "Chirag" }, { name: 1, address: 1, _id: 0 }));

task(10, "Rename field salary to monthly_salary in all documents ($rename)");
printjson(db.employees.updateMany({}, { $rename: { salary: "monthly_salary" } }));
db.employees.find({}, { name: 1, monthly_salary: 1, _id: 0 }).sort({ name: 1 }).forEach(printjson);

task(12, "Delete employees of the Sales department and count the remaining documents");
printjson(db.employees.deleteMany({ dept: "Sales" }));
print("remaining:", db.employees.countDocuments());

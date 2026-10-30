// 7D Employee directory - Tasks 2 - 5
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(2, "Employees in Pune who know SQL");
db.employees.find({ "address.city": "Pune", skills: "SQL" }, { name: 1, _id: 0 }).forEach(printjson);

task(3, "Employees who have BOTH Python and SQL ($all)");
db.employees.find({ skills: { $all: ["Python", "SQL"] } }, { name: 1, skills: 1, _id: 0 }).forEach(printjson);

task(4, "Employees whose salary is NOT between 40000 and 60000 ($not / $nin)");
print("-- inclusive range [40000, 60000]: every salary of the data set lies inside, so nobody is outside:");
db.employees.find({ salary: { $not: { $gte: 40000, $lte: 60000 } } }, { name: 1, salary: 1, _id: 0 }).forEach(printjson);
print("-- exclusive range (40000, 60000): the two boundary salaries are 'not between':");
db.employees.find({ salary: { $not: { $gt: 40000, $lt: 60000 } } }, { name: 1, salary: 1, _id: 0 }).sort({ name: 1 }).forEach(printjson);
print("-- $nin (not in a list of values):");
db.employees.find({ salary: { $nin: [40000, 45000, 55000] } }, { name: 1, salary: 1, _id: 0 }).forEach(printjson);

task(5, "Name and city only, sorted by name");
db.employees.find({}, { name: 1, "address.city": 1, _id: 0 }).sort({ name: 1 }).forEach(printjson);

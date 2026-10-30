// 7D Employee directory - Tasks 6, 7 (run before crud.js, because crud.js renames salary)
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(6, "Department-wise average and maximum salary, sorted by average (highest first)");
db.employees.aggregate([
  { $group: { _id: "$dept", avg_salary: { $avg: "$salary" }, max_salary: { $max: "$salary" }, employees: { $sum: 1 } } },
  { $sort: { avg_salary: -1 } }
]).forEach(printjson);

task(7, "Number of employees per city");
db.employees.aggregate([
  { $group: { _id: "$address.city", employees: { $sum: 1 } } },
  { $sort: { employees: -1, _id: 1 } }
]).forEach(printjson);

// 7D Employee directory - Task 1: insert the employees collection
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Insert the employees");
db.employees.deleteMany({});
db.employees.insertMany([
  { emp_id: 1, name: "Anil",   dept: "IT",    salary: 60000, skills: ["Python", "SQL"],   address: { city: "Pune",     pin: "411001" } },
  { emp_id: 2, name: "Bharti", dept: "IT",    salary: 55000, skills: ["Java", "SQL"],     address: { city: "Sangli",   pin: "416416" } },
  { emp_id: 3, name: "Chirag", dept: "HR",    salary: 40000, skills: ["Excel"],           address: { city: "Pune",     pin: "411038" } },
  { emp_id: 4, name: "Deepa",  dept: "Sales", salary: 45000, skills: ["Excel", "CRM"],    address: { city: "Kolhapur", pin: "416003" } }
]);
print("count:", db.employees.countDocuments());
db.employees.find({}, { _id: 0 }).forEach(printjson);

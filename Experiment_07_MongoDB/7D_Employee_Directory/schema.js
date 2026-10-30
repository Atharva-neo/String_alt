// 7D Employee directory - collection employees with $jsonSchema validation
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("companyDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create collection employees (validated)");
db.employees.drop();
db.createCollection("employees", {
  validator: { $jsonSchema: {
    bsonType: "object",
    // salary is NOT required: Task 10 renames it to monthly_salary, and the renamed document must still pass the validator
    required: ["emp_id", "name", "dept", "skills", "address"],
    properties: {
      emp_id: { bsonType: "int" },
      name:   { bsonType: "string" },
      dept:   { enum: ["IT", "HR", "Sales"] },
      salary: { bsonType: ["int", "double"], minimum: 0 },
      monthly_salary: { bsonType: ["int", "double"], minimum: 0 },
      skills: { bsonType: "array", items: { bsonType: "string" } },
      address: { bsonType: "object", required: ["city", "pin"],
                 properties: { city: { bsonType: "string" }, pin: { bsonType: "string", pattern: "^[0-9]{6}$" } } }
    }
  } }
});
print("collections:", db.getCollectionNames());
task(1, "Negative test: PIN code with 5 digits");
try { db.employees.insertOne({ emp_id: 9, name: "Bad", dept: "IT", salary: 1, skills: [], address: { city: "Pune", pin: "4110" } }); }
catch (e) { print("code " + e.code + ": " + e.message); }

// 9B Result analysis - Task 1/2: the four collections of collegeDB with $jsonSchema validation (students validation is Task 2 of 9A)
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create the four collections (students, courses, attendance, exams) with validation");
["students", "courses", "attendance", "exams"].forEach(c => db.getCollection(c).drop());
db.createCollection("students", { validator: { $jsonSchema: {
  bsonType: "object", required: ["name", "dept", "semester"],
  properties: {
    name: { bsonType: "string" }, dob: { bsonType: "date" }, gender: { enum: ["M", "F"] }, dept: { bsonType: "string" },
    semester: { bsonType: "int", minimum: 1, maximum: 8 },
    contact: { bsonType: "object", properties: { phone: { bsonType: "string" }, email: { bsonType: "string" }, city: { bsonType: "string" } } }
  } } } });
db.createCollection("courses", { validator: { $jsonSchema: {
  bsonType: "object", required: ["name", "credits", "faculty", "semester"],
  properties: { name: { bsonType: "string" }, credits: { bsonType: "int", minimum: 1 }, faculty: { bsonType: "string" }, semester: { bsonType: "int", minimum: 1, maximum: 8 } } } } });
db.createCollection("attendance", { validator: { $jsonSchema: {
  bsonType: "object", required: ["student_id", "course_id", "total", "attended"],
  properties: { student_id: { bsonType: "string" }, course_id: { bsonType: "string" }, total: { bsonType: "int", minimum: 0 }, attended: { bsonType: "int", minimum: 0 } } } } });
db.createCollection("exams", { validator: { $jsonSchema: {
  bsonType: "object", required: ["student_id", "course_id", "ise", "ese", "total"],
  properties: { student_id: { bsonType: "string" }, course_id: { bsonType: "string" }, ise: { bsonType: "int", minimum: 0, maximum: 40 },
                ese: { bsonType: "int", minimum: 0, maximum: 60 }, total: { bsonType: "int", minimum: 0, maximum: 100 }, grade: { enum: ["O", "A", "B", "C", "F"] } } } } });
print("collections:", db.getCollectionNames());

task(2, "Negative tests for the validation rules");
try { db.students.insertOne({ _id: "BAD1", name: "Nine", dept: "AIML", semester: 9 }); } catch (e) { print("semester 9 -> code " + e.code + ": " + e.message); }
try { db.students.insertOne({ _id: "BAD2", dept: "AIML", semester: 3 }); } catch (e) { print("missing name -> code " + e.code + ": " + e.message); }
try { db.exams.insertOne({ student_id: "S101", course_id: "C1", ise: 45, ese: 10, total: 55 }); } catch (e) { print("ise 45 (> 40) -> code " + e.code + ": " + e.message); }

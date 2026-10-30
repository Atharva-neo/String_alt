// 9A Attendance report - find queries (Tasks 3, 4)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(3, "All AIML students of semester 3");
db.students.find({ dept: "AIML", semester: 3 }, { name: 1, dept: 1, semester: 1 }).forEach(printjson);

task(4, "Students from Sangli - name and phone only");
db.students.find({ "contact.city": "Sangli" }, { name: 1, "contact.phone": 1, _id: 0 }).forEach(printjson);

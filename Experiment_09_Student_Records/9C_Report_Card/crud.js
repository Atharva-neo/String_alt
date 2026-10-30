// 9C Report card - CRUD on each of the four collections (temporary documents, removed again)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task("crud", "students: create, read, update, delete");
db.students.insertOne({ _id: "S999", name: "Temp Student", dob: ISODate("2006-01-01"), gender: "M", dept: "CSE", semester: 3, contact: { phone: "9000000000", email: "t@college.edu", city: "Pune" } });
printjson(db.students.findOne({ _id: "S999" }, { name: 1, dept: 1 }));
db.students.updateOne({ _id: "S999" }, { $set: { dept: "AIML" } });
printjson(db.students.findOne({ _id: "S999" }, { name: 1, dept: 1 }));
printjson(db.students.deleteOne({ _id: "S999" }));

task("crud", "courses: create, read, update, delete");
db.courses.insertOne({ _id: "CX", name: "Temp Course", credits: 2, faculty: "Dr. Temp", semester: 3 });
db.courses.updateOne({ _id: "CX" }, { $inc: { credits: 1 } });
printjson(db.courses.findOne({ _id: "CX" }));
printjson(db.courses.deleteOne({ _id: "CX" }));

task("crud", "attendance: create, read, update, delete");
db.attendance.insertOne({ student_id: "S999", course_id: "C1", total: 10, attended: 9 });
db.attendance.updateOne({ student_id: "S999" }, { $inc: { total: 1, attended: 1 } });
printjson(db.attendance.findOne({ student_id: "S999" }, { _id: 0 }));
printjson(db.attendance.deleteMany({ student_id: "S999" }));

task("crud", "exams: create, read, update, delete (with a negative test)");
db.exams.insertOne({ student_id: "S999", course_id: "C1", ise: 10, ese: 20, total: 30 });
db.exams.updateOne({ student_id: "S999" }, { $set: { grade: "F" } });
printjson(db.exams.findOne({ student_id: "S999" }, { _id: 0 }));
try { db.exams.updateOne({ student_id: "S999" }, { $set: { ese: 99 } }); } catch (e) { print("ese 99 rejected -> code " + e.code + ": " + e.message); }
printjson(db.exams.deleteMany({ student_id: "S999" }));
print("counts:", ["students", "courses", "attendance", "exams"].map(c => c + "=" + db.getCollection(c).countDocuments()).join(", "));

// 9D Department and semester statistics - Tasks 8, 9, 11, 12
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(8, "Promote all semester 3 students to semester 4 ($inc)");
printjson(db.students.updateMany({ semester: 3 }, { $inc: { semester: 1 } }));
db.students.find({}, { name: 1, semester: 1 }).sort({ _id: 1 }).forEach(printjson);

task(9, "Add a new course C4 'Machine Learning' and enrol S101 and S102");
// "enrolling" = one attendance document (0 lectures so far) per (student, course) pair, the same structure the other collections use
db.courses.deleteOne({ _id: "C4" }); db.attendance.deleteMany({ course_id: "C4" });
db.courses.insertOne({ _id: "C4", name: "Machine Learning", credits: 4, faculty: "Dr. Mane", semester: 4 });
db.attendance.insertMany([ { student_id: "S101", course_id: "C4", total: 0, attended: 0 }, { student_id: "S102", course_id: "C4", total: 0, attended: 0 } ]);
db.courses.find({}, { name: 1, semester: 1 }).forEach(printjson);
db.attendance.find({ course_id: "C4" }, { _id: 0 }).forEach(printjson);

task(11, "Remove the email field from all students ($unset)");
printjson(db.students.updateMany({}, { $unset: { "contact.email": "" } }));
db.students.find({}, { name: 1, contact: 1 }).sort({ _id: 1 }).forEach(printjson);

task(12, "Back up attendance, drop the backup copy and list the remaining collections");
db.attendance.aggregate([{ $match: {} }, { $out: "attendance_backup" }]);          // $out creates the copy
print("collections with the backup:", db.getCollectionNames());
print("backup documents:", db.attendance_backup.countDocuments(), "| original:", db.attendance.countDocuments());
print("dropped:", db.attendance_backup.drop());
print("remaining collections:", db.getCollectionNames());

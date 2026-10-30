// 9A Attendance report - Tasks 8, 10, 12
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(8, "2 more C2 lectures were held and S101 attended both");
// $inc changes both counters atomically; 27/38 = 71.05 %  ->  29/40 = 72.5 % (still a defaulter)
printjson(db.attendance.updateOne({ student_id: "S101", course_id: "C2" }, { $inc: { total: 2, attended: 2 } }));
printjson(db.attendance.findOne({ student_id: "S101", course_id: "C2" }, { _id: 0 }));

task(10, "Add a new student S105 with attendance records in C1 and C2");
db.students.deleteOne({ _id: "S105" }); db.attendance.deleteMany({ student_id: "S105" });
db.students.insertOne({ _id: "S105", name: "Rohan Kamble", dob: ISODate("2006-03-30"), gender: "M", dept: "AIML", semester: 3,
                        contact: { phone: "9822055555", email: "rohan@college.edu", city: "Miraj" } });
db.attendance.insertMany([ { student_id: "S105", course_id: "C1", total: 40, attended: 38 }, { student_id: "S105", course_id: "C2", total: 40, attended: 30 } ]);
db.attendance.find({ student_id: "S105" }, { _id: 0 }).forEach(printjson);

task(12, "Delete the attendance records of students who have left (S103)");
printjson(db.attendance.deleteMany({ student_id: "S103" }));
print("remaining attendance documents:", db.attendance.countDocuments());

// 9D Department and semester statistics - Tasks 1, 2, 3, 6, 7
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Count students per department");
db.students.aggregate([{ $group: { _id: "$dept", students: { $sum: 1 } } }, { $sort: { _id: 1 } }]).forEach(printjson);

task(2, "Count students per department per semester");
db.students.aggregate([{ $group: { _id: { dept: "$dept", semester: "$semester" }, students: { $sum: 1 } } }, { $sort: { "_id.dept": 1, "_id.semester": 1 } }]).forEach(printjson);

task(3, "Gender-wise count in each department");
db.students.aggregate([{ $group: { _id: { dept: "$dept", gender: "$gender" }, students: { $sum: 1 } } }, { $sort: { "_id.dept": 1, "_id.gender": 1 } }]).forEach(printjson);

task(6, "City-wise number of students");
db.students.aggregate([{ $group: { _id: "$contact.city", students: { $sum: 1 } } }, { $sort: { students: -1, _id: 1 } }]).forEach(printjson);

task(7, "Students born after 2006-01-01");
db.students.find({ dob: { $gt: ISODate("2006-01-01") } }, { name: 1, dob: 1 }).sort({ dob: 1 }).forEach(printjson);

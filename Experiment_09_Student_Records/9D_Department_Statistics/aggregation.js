// 9D Department and semester statistics - Tasks 4, 5, 10
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(4, "Students who failed in more than one course (total < 40 in 2 or more exams)");
printjson(db.exams.aggregate([
  { $match: { total: { $lt: 40 } } },
  { $group: { _id: "$student_id", failed_courses: { $sum: 1 } } },
  { $match: { failed_courses: { $gt: 1 } } }
]).toArray());
print("-- empty with the PDF data: S104 failed only DBMS. Students with at least ONE failed course:");
db.exams.aggregate([{ $match: { total: { $lt: 40 } } }, { $group: { _id: "$student_id", failed_courses: { $sum: 1 } } }]).forEach(printjson);

task(5, "Students with no exam record ($lookup and an empty array)");
const noExams = () => db.students.aggregate([
  { $lookup: { from: "exams", localField: "_id", foreignField: "student_id", as: "exam_records" } },
  { $match: { exam_records: { $size: 0 } } },
  { $project: { name: 1 } }
]).toArray();
print("with the PDF data:", JSON.stringify(noExams()), "(every student has an exam record)");
db.students.insertOne({ _id: "S900", name: "Temp No-Exam Student", dob: ISODate("2007-01-01"), gender: "F", dept: "CSE", semester: 3, contact: { phone: "9000000001", email: "x@college.edu", city: "Pune" } });
print("after adding a temporary student S900:", JSON.stringify(noExams()));
db.students.deleteOne({ _id: "S900" });

task(10, "Average marks per department ($lookup students)");
db.exams.aggregate([
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "s" } }, { $unwind: "$s" },
  { $group: { _id: "$s.dept", avg_marks: { $avg: "$total" }, exam_records: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

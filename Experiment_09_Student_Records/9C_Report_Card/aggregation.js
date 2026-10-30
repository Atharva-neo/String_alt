// 9C Report card - Tasks 2 - 8 and 9 ($out). One aggregation joins students, exams, courses and attendance.
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

const gradeOf = { $switch: { branches: [
  { case: { $gte: ["$exams.total", 90] }, then: "O" }, { case: { $gte: ["$exams.total", 75] }, then: "A" },
  { case: { $gte: ["$exams.total", 60] }, then: "B" }, { case: { $gte: ["$exams.total", 40] }, then: "C" } ], default: "F" } };
const pointsOf = { $switch: { branches: [ { case: { $eq: ["$grade", "O"] }, then: 10 }, { case: { $eq: ["$grade", "A"] }, then: 9 },
  { case: { $eq: ["$grade", "B"] }, then: 8 }, { case: { $eq: ["$grade", "C"] }, then: 6 } ], default: 0 } };

// stages 1-6: one document per (student, course) with name, dept, course name, marks, attendance %, grade and grade points
const perCourse = [
  { $lookup: { from: "exams", localField: "_id", foreignField: "student_id", as: "exams" } }, { $unwind: "$exams" },
  { $lookup: { from: "courses", localField: "exams.course_id", foreignField: "_id", as: "course" } }, { $unwind: "$course" },
  { $lookup: { from: "attendance", localField: "_id", foreignField: "student_id", as: "att" } },
  { $set: { att: { $arrayElemAt: [ { $filter: { input: "$att", as: "a", cond: { $eq: ["$$a.course_id", "$exams.course_id"] } } }, 0 ] } } },
  { $set: { grade: gradeOf, attendance_pct: { $round: [{ $multiply: [{ $divide: ["$att.attended", "$att.total"] }, 100] }, 2] } } },
  { $set: { points: pointsOf } }
];

task(2, "One aggregation that joins students, exams, courses and attendance");
print("(stages: $lookup exams -> $unwind -> $lookup courses -> $unwind -> $lookup attendance -> $filter on course -> computed fields)");

task(3, "Per student: name, dept, course name, marks, attendance %, grade");
db.students.aggregate([...perCourse,
  { $project: { _id: 0, student: "$name", dept: 1, course: "$course.name", marks: "$exams.total", attendance_pct: 1, grade: 1 } },
  { $sort: { student: 1, course: 1 } }
]).forEach(printjson);

// stages 7-8: roll the per-course rows up to one report-card document per student
const reportCard = [...perCourse,
  { $group: { _id: "$_id", name: { $first: "$name" }, dept: { $first: "$dept" }, semester: { $first: "$semester" }, phone: { $first: "$contact.phone" },
              courses: { $push: { course: "$course.name", credits: "$course.credits", marks: "$exams.total", attendance_pct: "$attendance_pct", grade: "$grade", points: "$points" } },
              weighted: { $sum: { $multiply: ["$course.credits", "$points"] } }, credits: { $sum: "$course.credits" },
              min_marks: { $min: "$exams.total" }, min_att: { $min: "$attendance_pct" } } },
  { $set: { sgpa: { $round: [{ $divide: ["$weighted", "$credits"] }, 2] },
            result: { $cond: [{ $lt: ["$min_marks", 40] }, "Fail", "Pass"] },
            remark: { $cond: [{ $lt: ["$min_att", 75] }, "Detained", "Eligible"] } } },
  { $project: { weighted: 0, min_marks: 0, min_att: 0 } },
  { $sort: { _id: 1 } }
];

task(4, "SGPA = sum(credits x grade points) / sum(credits); O=10 A=9 B=8 C=6 F=0");
db.students.aggregate([...reportCard, { $project: { name: 1, credits: 1, sgpa: 1 } }]).forEach(printjson);

task(5, "Class topper by SGPA");
db.students.aggregate([...reportCard, { $sort: { sgpa: -1 } }, { $limit: 1 }, { $project: { name: 1, sgpa: 1 } }]).forEach(printjson);

task(6, "Report card of S102 only");
db.students.aggregate([{ $match: { _id: "S102" } }, ...reportCard]).forEach(printjson);

task(7, "Result: Pass / Fail (fail if any course < 40)");
db.students.aggregate([...reportCard, { $project: { name: 1, result: 1 } }]).forEach(printjson);

task(8, "'Detained' remark where attendance < 75 % in any course");
db.students.aggregate([...reportCard, { $project: { name: 1, min_attendance_note: "$remark", result: 1 } }]).forEach(printjson);

task(9, "Store the report as a new collection report_cards with $out");
db.students.aggregate([...reportCard, { $out: "report_cards" }]);
print("report_cards documents:", db.report_cards.countDocuments());
db.report_cards.find({}, { name: 1, sgpa: 1, result: 1, remark: 1 }).sort({ _id: 1 }).forEach(printjson);

task(10, "Export report_cards to CSV (mongosh + Node fs; alternative: the mongoexport command shown below)");
// mongoexport --db=collegeDB --collection=report_cards --type=csv --fields=_id,name,dept,semester,sgpa,result,remark --out=report_cards.csv
const fs = require("fs");
const rows = db.report_cards.find({}).sort({ _id: 1 }).toArray();
const cols = ["_id", "name", "dept", "semester", "sgpa", "result", "remark"];
const csv = [cols.join(",")].concat(rows.map(r => cols.map(c => '"' + String(r[c]) + '"').join(","))).join("\n");
fs.writeFileSync("report_cards.csv", csv + "\n");
print("written report_cards.csv with " + rows.length + " rows:\n" + csv);

task(11, "Update a student's phone number and show it in the next report run");
print("phone in report before:", db.report_cards.findOne({ _id: "S101" }).phone);
db.students.updateOne({ _id: "S101" }, { $set: { "contact.phone": "9999900000" } });
db.students.aggregate([...reportCard, { $out: "report_cards" }]);          // the next report run reads the current student data
print("phone in report after :", db.report_cards.findOne({ _id: "S101" }).phone);
db.students.updateOne({ _id: "S101" }, { $set: { "contact.phone": "9822011111" } });   // restore the PDF value

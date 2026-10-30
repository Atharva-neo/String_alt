// 9B Result analysis - find queries (Tasks 1, 2, 11)
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "All exam records sorted by total, highest first");
db.exams.find({}, { _id: 0 }).sort({ total: -1 }).forEach(printjson);

task(2, "Students who failed in any course (total < 40; pass mark is 40)");
db.exams.find({ total: { $lt: 40 } }, { _id: 0, student_id: 1, course_id: 1, total: 1 }).forEach(printjson);

task(11, "Students whose ISE >= 30 but ESE < 30");
printjson(db.exams.find({ ise: { $gte: 30 }, ese: { $lt: 30 } }).toArray());
print("-- empty: every student with ISE >= 30 also scored >= 46 in ESE. For comparison, ISE >= 20 and ESE < 30:");
db.exams.find({ ise: { $gte: 20 }, ese: { $lt: 30 } }, { _id: 0 }).forEach(printjson);

// 9A Attendance report - insert the common data of Experiment 9 (database collegeDB) exactly as given in the PDF
db = db.getSiblingDB("collegeDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Insert the data into students, courses, attendance and exams");
["students", "courses", "attendance", "exams"].forEach(c => db.getCollection(c).deleteMany({}));
db.students.insertMany([
  { _id: "S101", name: "Aditya Pawar", dob: ISODate("2006-05-14"), gender: "M", dept: "AIML", semester: 3, contact: { phone: "9822011111", email: "aditya@college.edu", city: "Sangli" } },
  { _id: "S102", name: "Neha Gaikwad", dob: ISODate("2006-02-20"), gender: "F", dept: "AIML", semester: 3, contact: { phone: "9822022222", email: "neha@college.edu", city: "Miraj" } },
  { _id: "S103", name: "Omkar Salunkhe", dob: ISODate("2005-11-02"), gender: "M", dept: "CSE", semester: 5, contact: { phone: "9822033333", email: "omkar@college.edu", city: "Kolhapur" } },
  { _id: "S104", name: "Priya Mane", dob: ISODate("2006-08-09"), gender: "F", dept: "AIML", semester: 3, contact: { phone: "9822044444", email: "priya@college.edu", city: "Sangli" } }
]);
db.courses.insertMany([
  { _id: "C1", name: "DBMS", credits: 4, faculty: "Dr. Patil", semester: 3 },
  { _id: "C2", name: "DAA", credits: 4, faculty: "Dr. Kale", semester: 3 },
  { _id: "C3", name: "Operating Systems", credits: 3, faculty: "Dr. Joshi", semester: 5 }
]);
db.attendance.insertMany([                                 // one document per (student, course) pair
  { student_id: "S101", course_id: "C1", total: 40, attended: 36 }, { student_id: "S101", course_id: "C2", total: 38, attended: 27 },
  { student_id: "S102", course_id: "C1", total: 40, attended: 39 }, { student_id: "S102", course_id: "C2", total: 38, attended: 35 },
  { student_id: "S104", course_id: "C1", total: 40, attended: 25 }, { student_id: "S103", course_id: "C3", total: 36, attended: 30 }
]);
db.exams.insertMany([
  { student_id: "S101", course_id: "C1", ise: 32, ese: 48, total: 80 }, { student_id: "S101", course_id: "C2", ise: 20, ese: 25, total: 45 },
  { student_id: "S102", course_id: "C1", ise: 38, ese: 54, total: 92 }, { student_id: "S102", course_id: "C2", ise: 30, ese: 46, total: 76 },
  { student_id: "S104", course_id: "C1", ise: 15, ese: 20, total: 35 }, { student_id: "S103", course_id: "C3", ise: 28, ese: 42, total: 70 }
]);
["students", "courses", "attendance", "exams"].forEach(c => print(c.padEnd(11), db.getCollection(c).countDocuments()));

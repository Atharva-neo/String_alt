// 7A Blog - Task 1 (part 2): insertMany with the documents of the PDF (+ two extra posts, _id 4 and 5, to reach the 4-5 documents asked for)
db = db.getSiblingDB("blogDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "insertMany into posts and show them with find().pretty()");
db.posts.deleteMany({});
const res = db.posts.insertMany([
  { _id: 1, title: "Intro to MongoDB", author: "Riya", tags: ["mongodb", "nosql"], likes: 25, date: ISODate("2026-09-01"),
    comments: [ { user: "Amit", text: "Very helpful", likes: 3 }, { user: "Sneha", text: "Nice examples", likes: 1 } ] },
  { _id: 2, title: "Python Tips", author: "Amit", tags: ["python"], likes: 40, date: ISODate("2026-09-10"),
    comments: [ { user: "Riya", text: "Great", likes: 2 } ] },
  { _id: 3, title: "Indexes Explained", author: "Riya", tags: ["mongodb", "performance"], likes: 12, date: ISODate("2026-10-02"),
    comments: [] },
  // --- two additional documents (not in the PDF) ---
  { _id: 4, title: "Aggregation Pipeline Guide", author: "Sneha", tags: ["mongodb", "aggregation"], likes: 8, date: ISODate("2026-10-15"),
    comments: [] },
  { _id: 5, title: "Schema Design Patterns", author: "Amit", tags: ["nosql", "design"], likes: 30, date: ISODate("2026-09-20"),
    comments: [ { user: "Riya", text: "Useful patterns", likes: 4 } ] }
]);
print("inserted:", Object.keys(res.insertedIds).length, "documents");
db.posts.find().pretty().forEach(printjson);
print("countDocuments:", db.posts.countDocuments());

// 7A Blog - update / delete operators (Tasks 6, 7, 8 and 12) + insertOne / deleteOne / error demonstrations
db = db.getSiblingDB("blogDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(6, "$push a comment to post 3; $pull Amit's comment from post 1");
printjson(db.posts.updateOne({ _id: 3 }, { $push: { comments: { user: "Neha", text: "Great explanation", likes: 0 } } }));
printjson(db.posts.updateOne({ _id: 1 }, { $pull: { comments: { user: "Amit" } } }));
db.posts.find({ _id: { $in: [1, 3] } }, { title: 1, comments: 1 }).forEach(printjson);

task(7, "$inc likes of post 2 by 5");
printjson(db.posts.updateOne({ _id: 2 }, { $inc: { likes: 5 } }));
printjson(db.posts.findOne({ _id: 2 }, { title: 1, likes: 1 }));

task(8, "$addToSet tag 'database' to all mongodb posts (no duplicates)");
printjson(db.posts.updateMany({ tags: "mongodb" }, { $addToSet: { tags: "database" } }));
print("-- run it a second time: modifiedCount must be 0 because the element is already in each set");
printjson(db.posts.updateMany({ tags: "mongodb" }, { $addToSet: { tags: "database" } }));
db.posts.find({ tags: "mongodb" }, { title: 1, tags: 1 }).forEach(printjson);

task(12, "Delete posts with zero comments AND likes < 15");
// post 3 had no comments but received one in Task 6 (so it survives); post 4 (0 comments, 8 likes) is removed
print("candidates:", JSON.stringify(db.posts.find({ comments: { $size: 0 }, likes: { $lt: 15 } }, { title: 1 }).toArray()));
printjson(db.posts.deleteMany({ comments: { $size: 0 }, likes: { $lt: 15 } }));
print("remaining posts:", db.posts.countDocuments(), JSON.stringify(db.posts.find({}, { title: 1 }).sort({ _id: 1 }).toArray()));

task("extra", "Negative tests: duplicate _id and invalid document");
try { db.posts.insertOne({ _id: 1, title: "dup", author: "x", tags: [], likes: 0, date: new Date(), comments: [] }); }
catch (e) { print("Duplicate _id -> code " + e.code + ": " + e.message); }
try { db.posts.insertOne({ title: "bad likes", author: "x", tags: [], likes: -5, date: new Date(), comments: [] }); }
catch (e) { print("Validation -> code " + e.code + ": " + e.message); }
printjson(db.posts.updateOne({ _id: 999 }, { $set: { likes: 1 } }));
print("(matchedCount 0: updating a missing document is not an error)");

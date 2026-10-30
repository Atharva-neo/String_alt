// 7A Blog - find / projection / comparison / array operators (Tasks 2-5)
db = db.getSiblingDB("blogDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(2, "Posts by Riya with likes > 20, only title and likes");
db.posts.find({ author: "Riya", likes: { $gt: 20 } }, { title: 1, likes: 1, _id: 0 }).forEach(printjson);

task(3, "Posts tagged 'mongodb', newest first");
// { tags: "mongodb" } matches when the ARRAY contains that element
db.posts.find({ tags: "mongodb" }, { title: 1, date: 1 }).sort({ date: -1 }).forEach(printjson);

task(4, "Posts published in September 2026 (date range)");
// half-open range [1 Sep, 1 Oct) avoids the last-day / time-of-day problem
db.posts.find({ date: { $gte: ISODate("2026-09-01"), $lt: ISODate("2026-10-01") } }, { title: 1, date: 1 }).sort({ date: 1 }).forEach(printjson);

task(5, "Posts where ANY comment has likes >= 3 ($elemMatch)");
db.posts.find({ comments: { $elemMatch: { likes: { $gte: 3 } } } }, { title: 1, "comments.user": 1, "comments.likes": 1 }).forEach(printjson);
print("-- why $elemMatch? With { 'comments.likes': {$gte:3}, 'comments.user': 'Sneha' } the two conditions may be satisfied by DIFFERENT comments:");
print("   without $elemMatch :", db.posts.countDocuments({ "comments.likes": { $gte: 3 }, "comments.user": "Sneha" }));
print("   with    $elemMatch :", db.posts.countDocuments({ comments: { $elemMatch: { likes: { $gte: 3 }, user: "Sneha" } } }));

// 7A Blog - aggregation pipelines (Tasks 9, 10, 11)
db = db.getSiblingDB("blogDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(9, "Count posts per tag ($unwind + $group)");
// $unwind turns each post into one document PER TAG; $group counts them
db.posts.aggregate([
  { $unwind: "$tags" },
  { $group: { _id: "$tags", posts: { $sum: 1 } } },
  { $sort: { posts: -1, _id: 1 } }
]).forEach(printjson);

task(10, "Post(s) with the most comments ($size inside $project)");
// $size works on an array field; $group by the count collects every post that shares the maximum (ties are possible)
db.posts.aggregate([
  { $project: { title: 1, comment_count: { $size: "$comments" } } },
  { $group: { _id: "$comment_count", titles: { $push: "$title" } } },
  { $sort: { _id: -1 } },
  { $limit: 1 }
]).forEach(printjson);
print("-- all posts with their comment counts:");
db.posts.aggregate([{ $project: { _id: 0, title: 1, comment_count: { $size: "$comments" } } }, { $sort: { comment_count: -1, title: 1 } }]).forEach(printjson);

task(11, "Author-wise total likes, highest first");
db.posts.aggregate([
  { $group: { _id: "$author", total_likes: { $sum: "$likes" }, posts: { $sum: 1 } } },
  { $sort: { total_likes: -1 } }
]).forEach(printjson);

task("extra", "Average likes per tag and most active commenter");
db.posts.aggregate([{ $unwind: "$tags" }, { $group: { _id: "$tags", avg_likes: { $avg: "$likes" } } }, { $sort: { _id: 1 } }]).forEach(printjson);
db.posts.aggregate([{ $unwind: "$comments" }, { $group: { _id: "$comments.user", comments: { $sum: 1 } } }, { $sort: { comments: -1, _id: 1 } }]).forEach(printjson);

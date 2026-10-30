// 7C Movie catalogue - Tasks 10, 11, 12
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(10, "Add genre 'Adventure' to Space Journey with $addToSet");
printjson(db.movies.updateOne({ title: "Space Journey" }, { $addToSet: { genre: "Adventure" } }));
printjson(db.movies.findOne({ title: "Space Journey" }, { title: 1, genre: 1, _id: 0 }));

task(11, "Increase the rating of all 2019 movies by 0.2");
// a plain $inc of 0.2 on 8.1 gives 8.299999999999999 (binary floating point); a pipeline update with $round stores the clean 8.3
print("naive 8.1 + 0.2 =", db.movies.aggregate([{ $match: { year: 2019 } }, { $project: { _id: 0, naive: { $add: ["$rating", 0.2] } } }]).toArray()[0].naive);
printjson(db.movies.updateMany({ year: 2019 }, [ { $set: { rating: { $round: [{ $add: ["$rating", 0.2] }, 1] } } } ]));
db.movies.find({ year: 2019 }, { title: 1, rating: 1, _id: 0 }).forEach(printjson);

task(12, "Remove Actor B from City Lights ($pull) and delete movies with rating < 7");
printjson(db.movies.updateOne({ title: "City Lights" }, { $pull: { cast: { name: "Actor B" } } }));
printjson(db.movies.findOne({ title: "City Lights" }, { title: 1, cast: 1, _id: 0 }));
printjson(db.movies.deleteMany({ rating: { $lt: 7 } }));
db.movies.find({}, { title: 1, rating: 1, _id: 0 }).sort({ title: 1 }).forEach(printjson);

// 7C Movie catalogue - arrays, embedded documents, ranges (Tasks 2 - 5)
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(2, "Sci-Fi movies released after 2020");
db.movies.find({ genre: "Sci-Fi", year: { $gt: 2020 } }, { title: 1, year: 1, genre: 1, _id: 0 }).forEach(printjson);

task(3, "Movies with rating between 7 and 8.5 - title and rating only");
db.movies.find({ rating: { $gte: 7, $lte: 8.5 } }, { title: 1, rating: 1, _id: 0 }).sort({ rating: -1 }).forEach(printjson);

task(4, "Movies in which Actor A acted (dot notation on cast.name)");
db.movies.find({ "cast.name": "Actor A" }, { title: 1, _id: 0 }).forEach(printjson);

task(5, "Movies that belong to exactly two genres ($size)");
db.movies.find({ genre: { $size: 2 } }, { title: 1, genre: 1, _id: 0 }).forEach(printjson);

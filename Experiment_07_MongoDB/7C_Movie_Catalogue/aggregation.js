// 7C Movie catalogue - aggregation (Tasks 6, 7, 8)
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(6, "Each actor with the number of films ($unwind cast, $group)");
db.movies.aggregate([
  { $unwind: "$cast" },
  { $group: { _id: "$cast.name", films: { $sum: 1 }, titles: { $push: "$title" } } },
  { $sort: { films: -1, _id: 1 } }
]).forEach(printjson);

task(7, "Average rating per genre ($unwind genre)");
// a movie with two genres counts once for each genre
db.movies.aggregate([
  { $unwind: "$genre" },
  { $group: { _id: "$genre", avg_rating: { $avg: "$rating" }, movies: { $sum: 1 } } },
  { $sort: { avg_rating: -1 } }
]).forEach(printjson);

task(8, "Highest rated movie of each year ($sort then $group with $first)");
db.movies.aggregate([
  { $sort: { rating: -1 } },
  { $group: { _id: "$year", title: { $first: "$title" }, rating: { $first: "$rating" } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

// 7C Movie catalogue - Task 1: insert the movies (documents of the PDF; _id is a generated ObjectId)
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Insert the movies");
db.movies.deleteMany({});
db.movies.insertMany([
  { title: "Space Journey", year: 2019, genre: ["Sci-Fi", "Drama"], rating: 8.1,
    plot: "A crew travels beyond the solar system to save Earth",
    cast: [ { name: "Actor A", role: "Captain" }, { name: "Actor B", role: "Engineer" } ] },
  { title: "City Lights", year: 2021, genre: ["Drama"], rating: 7.4,
    plot: "Two friends chase their dreams in a big city",
    cast: [ { name: "Actor B", role: "Friend" }, { name: "Actor C", role: "Friend" } ] },
  { title: "Deep Ocean", year: 2023, genre: ["Sci-Fi", "Thriller"], rating: 6.9,
    plot: "Scientists discover a hidden city under the ocean",
    cast: [ { name: "Actor A", role: "Scientist" } ] }
]);
print("count:", db.movies.countDocuments());
db.movies.find({}, { title: 1, year: 1, genre: 1, rating: 1 }).sort({ year: 1 }).forEach(printjson);

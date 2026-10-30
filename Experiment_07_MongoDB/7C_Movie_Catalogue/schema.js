// 7C Movie catalogue - collection movies with $jsonSchema validation
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create collection movies (validated)");
db.movies.drop();
db.createCollection("movies", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["title", "year", "genre", "rating", "plot", "cast"],
    properties: {
      title:  { bsonType: "string" },
      year:   { bsonType: "int", minimum: 1888, maximum: 2100 },
      genre:  { bsonType: "array", minItems: 1, items: { bsonType: "string" } },
      rating: { bsonType: ["int", "double"], minimum: 0, maximum: 10 },
      plot:   { bsonType: "string" },
      cast:   { bsonType: "array", items: { bsonType: "object", required: ["name", "role"],
                properties: { name: { bsonType: "string" }, role: { bsonType: "string" } } } }
    }
  } }
});
print("collections:", db.getCollectionNames());
task(1, "Negative test: rating 11 is rejected");
try { db.movies.insertOne({ title: "Too good", year: 2024, genre: ["Drama"], rating: 11, plot: "x", cast: [] }); }
catch (e) { print("code " + e.code + ": " + e.message); }

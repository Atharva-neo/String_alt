// 7C Movie catalogue - Task 9: text index on title and plot, search for 'city'
db = db.getSiblingDB("movieDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(9, "Create a text index on title and plot");
db.movies.dropIndexes();
print("created:", db.movies.createIndex({ title: "text", plot: "text" }));   // only ONE text index is allowed per collection

task(9, "Search for 'city' ($text, sorted by title for a stable output)");
// matches City Lights (title + plot) and Deep Ocean (plot: 'a hidden city'). Space Journey has no such word.
db.movies.find({ $text: { $search: "city" } }, { title: 1, _id: 0 }).sort({ title: 1 }).forEach(printjson);
print("-- negation and phrase search: 'city -ocean' and \"big city\"");
db.movies.find({ $text: { $search: "city -ocean" } }, { title: 1, _id: 0 }).forEach(printjson);
db.movies.find({ $text: { $search: "\"big city\"" } }, { title: 1, _id: 0 }).forEach(printjson);
db.movies.getIndexes().forEach(i => print(i.name));

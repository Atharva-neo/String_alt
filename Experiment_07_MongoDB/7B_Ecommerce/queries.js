// 7B E-commerce - comparison, logical operators, sort and limit (Tasks 2, 3, 4)
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(2, "Products with price between 400 and 2000 ($gte, $lte)");
db.products.find({ price: { $gte: 400, $lte: 2000 } }, { name: 1, price: 1, _id: 0 }).sort({ price: 1 }).forEach(printjson);

task(3, "Products in Electronics or Home: $in and the equivalent $or");
db.products.find({ category: { $in: ["Electronics", "Home"] } }, { name: 1, category: 1, _id: 0 }).forEach(printjson);
print("-- same result with $or:");
db.products.find({ $or: [{ category: "Electronics" }, { category: "Home" }] }, { name: 1, category: 1, _id: 0 }).forEach(printjson);

task(4, "Product names in descending order of price, top 2 only");
db.products.find({}, { name: 1, price: 1, _id: 0 }).sort({ price: -1 }).limit(2).forEach(printjson);

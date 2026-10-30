// 7B E-commerce - $unwind + $lookup joins and revenue pipelines (Tasks 5 - 9)
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

// Reusable first stages: one document per ordered item, joined with the referenced product
const joinStages = [
  { $unwind: "$items" },
  { $lookup: { from: "products", localField: "items.prod_id", foreignField: "_id", as: "product" } },
  { $unwind: "$product" },
  { $set: { amount: { $multiply: ["$items.qty", "$product.price"] } } }
];

task(5, "Join orders with products: customer, product name, qty and amount");
db.orders.aggregate([...joinStages,
  { $project: { _id: 0, order: "$_id", customer: 1, product: "$product.name", qty: "$items.qty", amount: 1 } },
  { $sort: { order: 1, product: 1 } }
]).forEach(printjson);

task(6, "Total amount of each order");
db.orders.aggregate([...joinStages,
  { $group: { _id: "$_id", customer: { $first: "$customer" }, total: { $sum: "$amount" } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);

task(7, "Category-wise revenue");
db.orders.aggregate([...joinStages,
  { $group: { _id: "$product.category", revenue: { $sum: "$amount" } } },
  { $sort: { revenue: -1 } }
]).forEach(printjson);

task(8, "Customer with the highest total spending");
db.orders.aggregate([...joinStages,
  { $group: { _id: "$customer", spent: { $sum: "$amount" } } },
  { $sort: { spent: -1 } },
  { $limit: 1 }
]).forEach(printjson);

task(9, "Products never ordered ($lookup into orders, keep products with an empty match)");
const neverOrdered = () => db.products.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "items.prod_id", as: "orders_containing" } },
  { $match: { orders_containing: { $size: 0 } } },
  { $project: { name: 1 } }
]).toArray();
print("with the PDF data:", JSON.stringify(neverOrdered()), " (every product was ordered at least once)");
db.products.insertOne({ _id: "P5", name: "USB Cable", category: "Electronics", price: 250, stock: 40 });   // temporary product nobody ordered
print("after adding a temporary product P5:", JSON.stringify(neverOrdered()));
db.products.deleteOne({ _id: "P5" });
print("temporary product removed again:", db.products.countDocuments(), "products");

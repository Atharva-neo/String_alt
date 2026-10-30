// 7B E-commerce - Tasks 11 and 12: reduce stock per ordered item, delete old orders, drop the index
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(11, "Reduce stock for each ordered item with updateOne");
db.orders.find().sort({ _id: 1 }).forEach(order => {
  order.items.forEach(item => {
    const r = db.products.updateOne({ _id: item.prod_id }, { $inc: { stock: -item.qty } });   // $inc with a negative number
    print("order " + order._id + ": " + item.prod_id + " -" + item.qty + "  (modifiedCount " + r.modifiedCount + ")");
  });
});
db.products.find({}, { name: 1, stock: 1 }).sort({ _id: 1 }).forEach(printjson);
print("-- negative test: the validator keeps stock >= 0");
try { db.products.updateOne({ _id: "P1" }, { $inc: { stock: -1000 } }); } catch (e) { print("code " + e.code + ": " + e.message); }

task(12, "Delete orders older than 2026-10-05 and drop the index");
printjson(db.orders.deleteMany({ date: { $lt: ISODate("2026-10-05") } }));
db.orders.find({}, { customer: 1, date: 1 }).sort({ _id: 1 }).forEach(printjson);
db.products.dropIndex("category_1_price_1");
print("indexes now:", db.products.getIndexes().map(i => i.name).join(", "));

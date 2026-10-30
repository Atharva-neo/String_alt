// 7B E-commerce - Task 1: insert the products and orders collections (documents of the PDF)
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Insert products and orders");
db.products.deleteMany({});
db.orders.deleteMany({});
db.products.insertMany([
  { _id: "P1", name: "Laptop",    category: "Electronics", price: 55000, stock: 10 },
  { _id: "P2", name: "Mouse",     category: "Electronics", price: 500,   stock: 100 },
  { _id: "P3", name: "Notebook",  category: "Stationery",  price: 60,    stock: 500 },
  { _id: "P4", name: "Desk Lamp", category: "Home",        price: 1200,  stock: 25 }
]);
db.orders.insertMany([
  { _id: 1001, customer: "Sagar", date: ISODate("2026-10-02"), items: [ { prod_id: "P1", qty: 1 }, { prod_id: "P2", qty: 2 } ] },
  { _id: 1002, customer: "Meera", date: ISODate("2026-10-05"), items: [ { prod_id: "P3", qty: 10 } ] },
  { _id: 1003, customer: "Sagar", date: ISODate("2026-10-09"), items: [ { prod_id: "P4", qty: 1 } ] }
]);
print("products:", db.products.countDocuments(), " orders:", db.orders.countDocuments());
db.products.find().forEach(printjson);
db.orders.find().forEach(printjson);

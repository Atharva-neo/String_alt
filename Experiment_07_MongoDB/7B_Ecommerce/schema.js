// 7B E-commerce - collections products and orders with $jsonSchema validation
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("shopDB");
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create collections products and orders (validated)");
db.orders.drop();
db.products.drop();
db.createCollection("products", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["name", "category", "price", "stock"],
    properties: {
      _id:      { bsonType: "string", description: "product id P1.. (referenced by orders.items.prod_id)" },
      name:     { bsonType: "string" },
      category: { enum: ["Electronics", "Stationery", "Home"] },
      price:    { bsonType: ["int", "double"], minimum: 0, exclusiveMinimum: true },
      stock:    { bsonType: "int", minimum: 0 }
    }
  } }
});
db.createCollection("orders", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["customer", "date", "items"],
    properties: {
      customer: { bsonType: "string" },
      date:     { bsonType: "date" },
      items: {
        bsonType: "array", minItems: 1,                // embedded line items
        items: { bsonType: "object", required: ["prod_id", "qty"],
                 properties: { prod_id: { bsonType: "string" }, qty: { bsonType: "int", minimum: 1 } } }   // prod_id is a REFERENCE to products._id
      }
    }
  } }
});
print("collections:", db.getCollectionNames());

task(1, "Negative tests");
try { db.orders.insertOne({ _id: 9, customer: "X", date: new Date(), items: [{ prod_id: "P1", qty: 0 }] }); }
catch (e) { print("qty 0 -> code " + e.code + ": " + e.message); }
try { db.products.insertOne({ _id: "P9", name: "Bad", category: "Toys", price: 10, stock: 1 }); }
catch (e) { print("unknown category -> code " + e.code + ": " + e.message); }

# Explanation - 8D Node.js REST API

| Task | Implementation |
|---|---|
| 1 | `package.json` in the repository root: `express`, `mongodb`, `dotenv` |
| 2 | `MongoClient.connect()`, success message, `db('shopApiDB')` |
| 3 | `POST /products` -> `insertOne`, 201 + created document, validated first |
| 4 | `GET /products` -> `find({}).toArray()` |
| 5 | `GET /products/:id` -> `new ObjectId(id)`; malformed id -> 400, unknown id -> 404 |
| 6 | `GET /products?category=Electronics` -> filter from `req.query` (converted with `String()` so an attacker cannot inject `{ "$ne": ... }` operators) |
| 7 | `PUT /products/:id` -> `$set` of price/stock |
| 8 | `DELETE /products/:id` -> `deleteOne`, 404 if nothing deleted |
| 9 | `GET /products/low-stock` -> `stock < 20`; declared **before** `/products/:id` because Express matches routes in order |
| 10 | `GET /stats` -> `$group` by category: count and `$avg` price |
| 11 | `validate()`: name required, price number > 0, stock integer >= 0 -> HTTP 400 with the error list; malformed JSON -> 400 |
| 12 | `test_api.js` / curl |

`createApp(db)` receives the database object, so the same code runs against MongoDB or the in-memory test double.

# 8D - Node.js REST API (products)

```bash
npm install                              # once, in the repository root (express, mongodb, dotenv)
export MONGODB_URI=mongodb://localhost:27017      # PowerShell: $env:MONGODB_URI='mongodb://localhost:27017'
node Experiment_08_Database_Connectivity_ML/8D_Node_REST_API/server.js    # Task 2: prints "Connected successfully ..." and seeds the 3 PDF products
# test every route (Task 12):
curl -X POST localhost:3000/products -H "Content-Type: application/json" -d '{"name":"USB Cable","category":"Electronics","price":250,"stock":8}'
curl localhost:3000/products
curl "localhost:3000/products?category=Electronics"
curl localhost:3000/products/low-stock
curl localhost:3000/stats
curl -X PUT localhost:3000/products/<id> -H "Content-Type: application/json" -d '{"price":275,"stock":50}'
curl -X DELETE localhost:3000/products/<id>
node test_api.js                         # automatic test of all routes (in-memory fake DB; REAL=1 uses MONGODB_URI)
```

| File | Purpose |
|---|---|
| `server.js` | Tasks 1-2: `MongoClient` connection, seed data, start the server |
| `app.js` | Tasks 3-11: all routes, validation (400), 404 handling |
| `test_api.js` | Task 12: calls every route and prints status + body |
| `expected_output.md` | output of `test_api.js` against the **in-memory fake** (`tools/fake_mongodb.js`); the real-MongoDB run was not possible here |
| `explanation.md`, `viva_questions.md` | explanation and viva |

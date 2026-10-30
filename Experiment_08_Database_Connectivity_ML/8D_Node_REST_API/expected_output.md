# Expected output - 8D Node.js REST API

> Produced by `node test_api.js` against the **in-memory fake database** (`tools/fake_mongodb.js`, built on mingo) - no MongoDB server was available. ObjectIds are random. Run `REAL=1 node test_api.js` against a real server for a genuine transcript.

```text
(in-memory fake database - not a real MongoDB; see tools/fake_mongodb.js)

### Task 3  POST /products
$ curl -X POST /products -H 'Content-Type: application/json' -d '{"name":"USB Cable","category":"Electronics","price":250,"stock":8}'
HTTP 201
{"_id":"6ae42b1c981073836731b29b","name":"USB Cable","category":"Electronics","price":250,"stock":8}

### Task 4  GET /products
$ curl -X GET /products
HTTP 200
[{"_id":"6ae42b1c981073836731b298","name":"Pen Drive","category":"Electronics","price":450,"stock":30},{"_id":"6ae42b1c981073836731b299","name":"Notebook","category":"Stationery","price":60,"stock":200},{"_id":"6ae42b1c981073836731b29a","name":"Headphones","category":"Electronics","price":1500,"stock":12},{"_id":"6ae42b1c981073836731b29b","name":"USB Cable","category":"Electronics","price":250,"stock":8}]

### Task 5  GET /products/:id
$ curl -X GET /products/6ae42b1c981073836731b29b
HTTP 200
{"_id":"6ae42b1c981073836731b29b","name":"USB Cable","category":"Electronics","price":250,"stock":8}

### Task 5  GET /products/:id (valid id, not found)
$ curl -X GET /products/ffffffffffffffffffffffff
HTTP 404
{"error":"product not found"}

### Task 5  GET /products/:id (malformed id)
$ curl -X GET /products/abc
HTTP 400
{"error":"invalid id format"}

### Task 6  GET /products?category=Electronics
$ curl -X GET /products?category=Electronics
HTTP 200
[{"_id":"6ae42b1c981073836731b298","name":"Pen Drive","category":"Electronics","price":450,"stock":30},{"_id":"6ae42b1c981073836731b29a","name":"Headphones","category":"Electronics","price":1500,"stock":12},{"_id":"6ae42b1c981073836731b29b","name":"USB Cable","category":"Electronics","price":250,"stock":8}]

### Task 7  PUT /products/:id
$ curl -X PUT /products/6ae42b1c981073836731b29b -H 'Content-Type: application/json' -d '{"price":275,"stock":50}'
HTTP 200
{"_id":"6ae42b1c981073836731b29b","name":"USB Cable","category":"Electronics","price":275,"stock":50}

### Task 9  GET /products/low-stock
$ curl -X GET /products/low-stock
HTTP 200
[{"_id":"6ae42b1c981073836731b29a","name":"Headphones","category":"Electronics","price":1500,"stock":12}]

### Task 10 GET /stats
$ curl -X GET /stats
HTTP 200
[{"_id":"Electronics","count":3,"avg_price":741.6666666666666},{"_id":"Stationery","count":1,"avg_price":60}]

### Task 11 POST invalid: price 0, no name
$ curl -X POST /products -H 'Content-Type: application/json' -d '{"price":0,"category":"x"}'
HTTP 400
{"errors":["name is required (non-empty string)","price must be a number > 0"]}

### Task 11 POST invalid: negative price
$ curl -X POST /products -H 'Content-Type: application/json' -d '{"name":"Bad","price":-5}'
HTTP 400
{"errors":["price must be a number > 0"]}

### Task 11 POST malformed JSON
$ curl -X POST /products -H 'Content-Type: application/json' -d '{"name": '
HTTP 400
{"error":"invalid JSON body"}

### Task 11 PUT invalid stock
$ curl -X PUT /products/6ae42b1c981073836731b29b -H 'Content-Type: application/json' -d '{"stock":-1}'
HTTP 400
{"errors":["stock must be an integer >= 0"]}

### Task 8  DELETE /products/:id
$ curl -X DELETE /products/6ae42b1c981073836731b29b
HTTP 200
{"deleted":"6ae42b1c981073836731b29b"}

### Task 8  DELETE again -> 404
$ curl -X DELETE /products/6ae42b1c981073836731b29b
HTTP 404
{"error":"product not found"}
```

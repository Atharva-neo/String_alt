# Viva questions - 8D Node.js REST API

**Q1. What is REST? Which verbs map to CRUD?** Resource-oriented HTTP API: POST create, GET read, PUT/PATCH update, DELETE delete; resources are URLs (`/products/:id`).

**Q2. Why must `/products/low-stock` be declared before `/products/:id`?** Express tries routes in registration order; otherwise "low-stock" would be treated as an id (and fail with 400).

**Q3. Which status codes did you use and why?** 201 created, 200 ok, 400 invalid input, 404 not found, 500 server error.

**Q4. How do you search by `_id`?** `{_id: new ObjectId(idString)}`; a plain string never equals an ObjectId. `ObjectId.isValid` + length check guards malformed ids.

**Q5. How do you avoid NoSQL injection through query parameters?** Convert to string (`String(req.query.category)`) or validate; with `?category[$ne]=x` Express would otherwise produce an object and the filter `{category: {$ne: 'x'}}`.

**Q6. Why `app.use(express.json())`?** Parses JSON bodies into `req.body`; malformed JSON raises an error we turn into 400.

**Q7. What does `/stats` use?** An aggregation: `$group` by category with `$sum` and `$avg`.

**Q8. Why connect once at start-up instead of per request?** `MongoClient` maintains a connection pool; creating a client per request is slow and exhausts connections.

**Q9. How do you test without Postman?** `curl`, or the Node `fetch` script `test_api.js`.

**Q10. What validation would you add for production?** Schema validation in MongoDB, a library such as Joi/zod, authentication, rate limiting.

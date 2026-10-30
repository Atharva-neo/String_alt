'use strict';
// 8D - Task 12: exercise every route and print request / status / response. Uses an in-memory fake DB unless MONGODB_URI is set with REAL=1.
//   node test_api.js                     (fake DB, no server needed)
//   REAL=1 node test_api.js              (real MongoDB from MONGODB_URI, database shopApiTestDB - emptied first)
require('dotenv').config();
const { createApp } = require('./app');

async function main() {
  let db;
  if (process.env.REAL === '1') {
    const { MongoClient } = require('mongodb');
    const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017');
    await client.connect(); db = client.db('shopApiTestDB'); await db.collection('products').deleteMany({});
    console.log('(real MongoDB)');
  } else {
    db = new (require('../../tools/fake_mongodb').FakeDb)();
    console.log('(in-memory fake database - not a real MongoDB; see tools/fake_mongodb.js)');
  }
  for (const p of [{ name: 'Pen Drive', category: 'Electronics', price: 450, stock: 30 }, { name: 'Notebook', category: 'Stationery', price: 60, stock: 200 },
                   { name: 'Headphones', category: 'Electronics', price: 1500, stock: 12 }]) await db.collection('products').insertOne(p);
  const server = createApp(db).listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (label, method, path, body) => {
    const r = await fetch(base + path, { method, headers: { 'content-type': 'application/json' }, body: body === undefined ? undefined : (typeof body === 'string' ? body : JSON.stringify(body)) });
    const text = await r.text();
    console.log(`\n### ${label}\n$ curl -X ${method} ${path}${body !== undefined ? " -H 'Content-Type: application/json' -d '" + (typeof body === 'string' ? body : JSON.stringify(body)) + "'" : ''}\nHTTP ${r.status}\n${text}`);
    try { return JSON.parse(text); } catch { return text; }
  };
  const created = await call('Task 3  POST /products', 'POST', '/products', { name: 'USB Cable', category: 'Electronics', price: 250, stock: 8 });
  await call('Task 4  GET /products', 'GET', '/products');
  await call('Task 5  GET /products/:id', 'GET', '/products/' + created._id);
  await call('Task 5  GET /products/:id (valid id, not found)', 'GET', '/products/ffffffffffffffffffffffff');
  await call('Task 5  GET /products/:id (malformed id)', 'GET', '/products/abc');
  await call('Task 6  GET /products?category=Electronics', 'GET', '/products?category=Electronics');
  await call('Task 7  PUT /products/:id', 'PUT', '/products/' + created._id, { price: 275, stock: 50 });
  await call('Task 9  GET /products/low-stock', 'GET', '/products/low-stock');
  await call('Task 10 GET /stats', 'GET', '/stats');
  await call('Task 11 POST invalid: price 0, no name', 'POST', '/products', { price: 0, category: 'x' });
  await call('Task 11 POST invalid: negative price', 'POST', '/products', { name: 'Bad', price: -5 });
  await call('Task 11 POST malformed JSON', 'POST', '/products', '{"name": ');
  await call('Task 11 PUT invalid stock', 'PUT', '/products/' + created._id, { stock: -1 });
  await call('Task 8  DELETE /products/:id', 'DELETE', '/products/' + created._id);
  await call('Task 8  DELETE again -> 404', 'DELETE', '/products/' + created._id);
  server.close();
  process.exit(0);
}
main().catch((e) => { console.error(e); process.exit(1); });

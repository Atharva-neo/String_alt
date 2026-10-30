'use strict';
// 8D - Task 2: connect with MongoClient and start the API.   node server.js     (PORT and MONGODB_URI from the environment / .env)
require('dotenv').config();
const { MongoClient } = require('mongodb');
const { createApp } = require('./app');

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const port = Number(process.env.PORT || 3000);

async function main() {
  let db;
  if (process.env.USE_FAKE_MONGO === '1') {                      // test aid only
    const { FakeDb } = require('../../tools/fake_mongodb');
    db = new FakeDb();
    console.log('[!] USE_FAKE_MONGO=1: in-memory fake instead of MongoDB');
  } else {
    const client = new MongoClient(uri, { serverSelectionTimeoutMS: 4000 });
    await client.connect();
    console.log('Connected successfully to MongoDB at', uri);   // Task 2: success message
    db = client.db('shopApiDB');
  }
  const col = db.collection('products');
  if ((await col.countDocuments({})) === 0) {                    // seed the three documents of the PDF once
    for (const p of [
      { name: 'Pen Drive', category: 'Electronics', price: 450, stock: 30 },
      { name: 'Notebook', category: 'Stationery', price: 60, stock: 200 },
      { name: 'Headphones', category: 'Electronics', price: 1500, stock: 12 },
    ]) await col.insertOne(p);
    console.log('seeded 3 products');
  }
  createApp(db).listen(port, () => console.log(`API listening on http://localhost:${port}`));
}
main().catch((e) => { console.error('Startup failed:', e.message); process.exit(1); });

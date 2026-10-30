'use strict';
// 8F Task 12 - print the product count from MySQL (mysql2) and MongoDB (mongodb driver).   node node_count.js
// Configuration from the environment: MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PWD, MONGODB_URI (see .env.example)
require('dotenv').config();
const mysql = require('mysql2/promise');
const { MongoClient } = require('mongodb');

async function main() {
  let failed = false;
  try {
    const conn = await mysql.createConnection({
      host: process.env.MYSQL_HOST || '127.0.0.1', port: Number(process.env.MYSQL_PORT || 3306),
      user: process.env.MYSQL_USER || 'root', password: process.env.MYSQL_PWD || '', database: 'catalog_8f',
    });
    const [rows] = await conn.execute('SELECT COUNT(*) AS n FROM product');       // parameterised API: execute()
    console.log('MySQL   product count:', rows[0].n);
    await conn.end();
  } catch (e) { failed = true; console.error('MySQL   FAILED:', e.code || '', e.message); }

  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017', { serverSelectionTimeoutMS: 3000 });
  try {
    await client.connect();
    console.log('MongoDB product count:', await client.db('catalogDB').collection('products').countDocuments({}));
  } catch (e) { failed = true; console.error('MongoDB FAILED:', e.message.split('\n')[0]); }
  finally { await client.close(); }
  process.exit(failed ? 1 : 0);
}
main();

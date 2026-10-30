'use strict';
// 8D - Express REST API for the products collection (Tasks 3-11). createApp(db) takes any object with the driver's collection API.
const express = require('express');
const { ObjectId } = require('mongodb');

function validate(body, partial = false) {
  const errors = [];
  if (!partial || body.name !== undefined) if (typeof body.name !== 'string' || !body.name.trim()) errors.push('name is required (non-empty string)');
  if (!partial || body.price !== undefined) if (typeof body.price !== 'number' || !(body.price > 0)) errors.push('price must be a number > 0');
  if (body.stock !== undefined && (!Number.isInteger(body.stock) || body.stock < 0)) errors.push('stock must be an integer >= 0');
  if (body.category !== undefined && typeof body.category !== 'string') errors.push('category must be a string');
  return errors;
}
const parseId = (s) => (ObjectId.isValid(s) && String(s).length === 24 ? new ObjectId(s) : null);

function createApp(db) {
  const products = db.collection('products');
  const app = express();
  app.use(express.json());

  // Task 3 - POST /products (Task 11 validation -> 400)
  app.post('/products', async (req, res, next) => {
    try {
      const errors = validate(req.body || {});
      if (errors.length) return res.status(400).json({ errors });
      const { name, category = 'General', price, stock = 0 } = req.body;
      const r = await products.insertOne({ name: name.trim(), category, price, stock });
      res.status(201).json({ _id: r.insertedId, name: name.trim(), category, price, stock });
    } catch (e) { next(e); }
  });

  // Task 9 - GET /products/low-stock  (declared BEFORE /products/:id, otherwise "low-stock" would be taken as an id)
  app.get('/products/low-stock', async (_req, res, next) => {
    try { res.json(await products.find({ stock: { $lt: 20 } }).toArray()); } catch (e) { next(e); }
  });

  // Task 4 + Task 6 - GET /products and GET /products?category=Electronics
  app.get('/products', async (req, res, next) => {
    try {
      const filter = req.query.category ? { category: String(req.query.category) } : {};   // String(): query values are never used as operators
      res.json(await products.find(filter).toArray());
    } catch (e) { next(e); }
  });

  // Task 5 - GET /products/:id (404 when missing, 400 for a malformed id)
  app.get('/products/:id', async (req, res, next) => {
    try {
      const id = parseId(req.params.id);
      if (!id) return res.status(400).json({ error: 'invalid id format' });
      const doc = await products.findOne({ _id: id });
      if (!doc) return res.status(404).json({ error: 'product not found' });
      res.json(doc);
    } catch (e) { next(e); }
  });

  // Task 7 - PUT /products/:id : update price and stock
  app.put('/products/:id', async (req, res, next) => {
    try {
      const id = parseId(req.params.id);
      if (!id) return res.status(400).json({ error: 'invalid id format' });
      const { price, stock } = req.body || {};
      if (price === undefined && stock === undefined) return res.status(400).json({ errors: ['send price and/or stock'] });
      const errors = validate({ price, stock }, true);
      if (errors.length) return res.status(400).json({ errors });
      const $set = {}; if (price !== undefined) $set.price = price; if (stock !== undefined) $set.stock = stock;
      const r = await products.updateOne({ _id: id }, { $set });
      if (!r.matchedCount) return res.status(404).json({ error: 'product not found' });
      res.json(await products.findOne({ _id: id }));
    } catch (e) { next(e); }
  });

  // Task 8 - DELETE /products/:id
  app.delete('/products/:id', async (req, res, next) => {
    try {
      const id = parseId(req.params.id);
      if (!id) return res.status(400).json({ error: 'invalid id format' });
      const r = await products.deleteOne({ _id: id });
      if (!r.deletedCount) return res.status(404).json({ error: 'product not found' });
      res.json({ deleted: req.params.id });
    } catch (e) { next(e); }
  });

  // Task 10 - GET /stats : category-wise count and average price
  app.get('/stats', async (_req, res, next) => {
    try {
      res.json(await products.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 }, avg_price: { $avg: '$price' } } },
        { $sort: { _id: 1 } },
      ]).toArray());
    } catch (e) { next(e); }
  });

  app.use((err, _req, res, _next) => {                 // malformed JSON etc.
    if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'invalid JSON body' });
    console.error(err);
    res.status(500).json({ error: 'internal server error' });
  });
  return app;
}
module.exports = { createApp };

#!/usr/bin/env node
/*
 * mongosh_shim.js - a small IN-MEMORY emulation of the mongosh API, built on the `mingo` library.
 *
 * WHY: lets the mongosh scripts of Experiments 7, 9 and 10 be executed (and their logic checked) on a machine
 *      that has no MongoDB server. It is a TEST AID, not MongoDB:
 *        - query / aggregation / update operators are evaluated by mingo (very close to MongoDB, not identical);
 *        - explain() plans are SIMULATED (collection scan vs. index scan decided by a simple rule);
 *        - no transactions, no change streams, no real storage engine, no concurrency.
 *      Always run the scripts on real MongoDB 7 for the final check:  mongosh --quiet --file crud.js
 *
 * USAGE:  node tools/mongosh_shim.js script1.js [script2.js ...]     (state is shared between the scripts, like one server)
 * Provided globals: db, ObjectId, ISODate, NumberInt, NumberLong, NumberDecimal, print, printjson, sleep
 */
'use strict';
const fs = require('fs');
const util = require('util');
const vm = require('vm');
require('mingo/init/system');
const { Query: MingoQuery, Aggregator } = require('mingo');
// mingo's $round is off by one decimal for some values (92.105.. -> 92.1) and cannot be overridden, so every $round in a pipeline is
// rewritten into equivalent arithmetic ($trunc of x*10^p + 0.5, sign aware). Difference to MongoDB: exact .5 ties round away from zero (MongoDB: to even).
function fixRound(node) {
  if (Array.isArray(node)) return node.map(fixRound);
  if (node && typeof node === 'object' && !(node instanceof Date) && !(node instanceof ObjectId)) {
    if (Object.keys(node).length === 1 && Array.isArray(node.$round) && (node.$round.length === 1 || typeof node.$round[1] === 'number')) {
      const e = fixRound(node.$round[0]); const f = 10 ** (node.$round[1] || 0);
      const scaled = { $multiply: [e, f] };
      const rounded = { $cond: [{ $gte: [scaled, 0] }, { $trunc: [{ $add: [scaled, 0.5] }, 0] }, { $multiply: [-1, { $trunc: [{ $add: [{ $multiply: [scaled, -1] }, 0.5] }, 0] }] }] };
      return { $divide: [rounded, f] };
    }
    return Object.fromEntries(Object.entries(node).map(([k, v]) => [k, fixRound(v)]));
  }
  return node;
}const { updateObject } = require('mingo/updater');

// ------------------------------------------------------------------ BSON-like helpers
let idCounter = 0;
class ObjectId {
  constructor(h) { this.str = h ? String(h) : '6540a1b2c3d4' + (++idCounter).toString(16).padStart(12, '0'); }
  toString() { return this.str; }
  toHexString() { return this.str; }
  toJSON() { return this.str; }
  equals(o) { return String(o) === this.str; }
  getTimestamp() { return new Date(parseInt(this.str.slice(0, 8), 16) * 1000); }
  [util.inspect.custom]() { return `ObjectId('${this.str}')`; }
}
Date.prototype[util.inspect.custom] = function () { return isNaN(this) ? 'Invalid Date' : `ISODate('${this.toISOString()}')`; };
const ISODate = (s) => (s === undefined ? new Date() : new Date(s));
const NumberInt = (x) => parseInt(x, 10);
const NumberLong = (x) => Number(x);
const NumberDecimal = (x) => Number(x);

class MongoServerError extends Error {
  constructor(message, code, codeName, extra) { super(message); this.name = 'MongoServerError'; this.code = code; this.codeName = codeName; Object.assign(this, extra || {}); }
}

function clone(v) {
  if (v === null || typeof v !== 'object') return v;
  if (v instanceof Date) return new Date(v.getTime());
  if (v instanceof ObjectId) return new ObjectId(v.str);
  if (Array.isArray(v)) return v.map(clone);
  const o = {};
  for (const k of Object.keys(v)) o[k] = clone(v[k]);
  return o;
}
const show = (v) => util.inspect(v, { depth: null, breakLength: 100, compact: 3 });
const getPath = (o, p) => p.split('.').reduce((a, k) => (a === undefined || a === null ? undefined : a[k]), o);


// ------------------------------------------------------------------ $jsonSchema (MongoDB subset) - mingo needs a validator callback
function bsonTypeOf(v) {
  if (v === null) return 'null';
  if (typeof v === 'string') return 'string';
  if (typeof v === 'boolean') return 'bool';
  if (typeof v === 'number') return Number.isInteger(v) && Math.abs(v) <= 2147483647 ? 'int' : 'double';   // like js-bson: int32 when it fits
  if (v instanceof Date) return 'date';
  if (v instanceof ObjectId) return 'objectId';
  if (Array.isArray(v)) return 'array';
  return 'object';
}
function schemaOk(schema, v) {
  const types = [].concat(schema.bsonType || schema.type || []);
  if (types.length) {
    const t = bsonTypeOf(v);
    const okType = types.some((x) => x === t || (x === 'number' && (t === 'int' || t === 'double')) || (x === 'long' && t === 'int') || (x === 'decimal' && (t === 'int' || t === 'double')) || (x === 'boolean' && t === 'bool'));
    if (!okType) return false;
  }
  if (schema.enum && !schema.enum.some((e) => JSON.stringify(e) === JSON.stringify(v))) return false;
  if (typeof v === 'number') {
    if (schema.minimum !== undefined && (schema.exclusiveMinimum ? v <= schema.minimum : v < schema.minimum)) return false;
    if (schema.maximum !== undefined && (schema.exclusiveMaximum ? v >= schema.maximum : v > schema.maximum)) return false;
  }
  if (typeof v === 'string') {
    if (schema.minLength !== undefined && v.length < schema.minLength) return false;
    if (schema.maxLength !== undefined && v.length > schema.maxLength) return false;
    if (schema.pattern && !new RegExp(schema.pattern).test(v)) return false;
  }
  if (Array.isArray(v)) {
    if (schema.minItems !== undefined && v.length < schema.minItems) return false;
    if (schema.maxItems !== undefined && v.length > schema.maxItems) return false;
    if (schema.items && !v.every((x) => schemaOk(schema.items, x))) return false;
  }
  if (bsonTypeOf(v) === 'object') {
    if (schema.required && !schema.required.every((k) => v[k] !== undefined)) return false;
    for (const [k, sub] of Object.entries(schema.properties || {})) if (v[k] !== undefined && !schemaOk(sub, v[k])) return false;
    if (schema.additionalProperties === false) {
      const allowed = new Set([...Object.keys(schema.properties || {}), '_id']);
      if (!Object.keys(v).every((k) => allowed.has(k))) return false;
    }
  }
  return true;
}
const QOPT = { jsonSchemaValidator: (schema) => (obj) => schemaOk(schema, obj) };
const Q = (filter) => new MingoQuery(filter, QOPT);
// ------------------------------------------------------------------ storage
const store = {};                                  // store[db][collection] = {docs, indexes, validator}
function getColl(dbName, name, create = true) {
  store[dbName] = store[dbName] || {};
  if (!store[dbName][name] && create) store[dbName][name] = { docs: [], indexes: [{ name: '_id_', key: { _id: 1 }, v: 2 }], validator: null };
  return store[dbName][name];
}

// ------------------------------------------------------------------ text search ($text)
const tokens = (s) => String(s).toLowerCase().match(/[a-z0-9]+/g) || [];
const stem = (w) => w.replace(/(ing|ed|es|s)$/, '');
function textFieldsOf(coll) {
  const t = coll.indexes.find((i) => i.text);
  if (!t) throw new MongoServerError('text index required for $text query', 27, 'IndexNotFound');
  return t.textFields;
}
function textMatch(doc, fields, search) {
  const hay = new Set();
  const collect = (v) => { if (typeof v === 'string') tokens(v).forEach((w) => hay.add(stem(w))); else if (Array.isArray(v)) v.forEach(collect); };
  for (const f of fields) collect(f === '$**' ? Object.values(doc) : getPath(doc, f));
  const neg = [...search.matchAll(/-(\w+)/g)].map((m) => stem(m[1].toLowerCase()));
  const phrases = [...search.matchAll(/"([^"]+)"/g)].map((m) => m[1].toLowerCase());
  const words = tokens(search.replace(/"[^"]+"/g, ' ').replace(/-\w+/g, ' ')).map(stem);
  if (neg.some((w) => hay.has(w))) return false;
  const text = fields.map((f) => JSON.stringify(f === '$**' ? doc : getPath(doc, f))).join(' ').toLowerCase();
  if (phrases.length && !phrases.every((p) => text.includes(p))) return false;
  return words.length === 0 ? phrases.length > 0 : words.some((w) => hay.has(w));
}
function matchDocs(coll, filter) {
  filter = filter || {};
  let docs = coll.docs;
  if (filter.$text) {
    const { $text, ...rest } = filter;
    const fields = textFieldsOf(coll);
    docs = docs.filter((d) => textMatch(d, fields, $text.$search));
    filter = rest;
  }
  return Q(filter).find(docs).all();
}

// ------------------------------------------------------------------ validation + unique indexes
function validate(coll, db, name, doc) {
  if (coll.validator && !Q(coll.validator).test(doc)) {
    throw new MongoServerError('Document failed validation', 121, 'DocumentValidationFailure',
      { errInfo: { failingDocumentId: doc._id, details: 'schema validation rules not satisfied (shim does not list the failing rules)' } });
  }
}
function keyString(index, doc) { return JSON.stringify(Object.keys(index.key).map((k) => getPath(doc, k))); }
function checkUnique(coll, dbName, name, doc, ignoreDoc) {
  for (const ix of coll.indexes) {
    if (!(ix.unique || ix.name === '_id_')) continue;
    const ks = keyString(ix, doc);
    if (coll.docs.some((d) => d !== ignoreDoc && keyString(ix, d) === ks)) {
      const dup = Object.keys(ix.key).map((k) => `${k}: ${show(getPath(doc, k))}`).join(', ');
      throw new MongoServerError(`E11000 duplicate key error collection: ${dbName}.${name} index: ${ix.name} dup key: { ${dup} }`, 11000, 'DuplicateKey', { keyValue: Object.fromEntries(Object.keys(ix.key).map((k) => [k, getPath(doc, k)])) });
    }
  }
}

// ------------------------------------------------------------------ cursor
class Cursor {
  constructor(coll, docs, projection, filter) { this.coll = coll; this.docs = docs; this.proj = projection; this.filter = filter || {}; this._sort = null; this._limit = 0; this._skip = 0; this.pos = 0; this.cache = null; }
  sort(s) { this._sort = s; return this; }
  limit(n) { this._limit = n; return this; }
  skip(n) { this._skip = n; return this; }
  hint() { return this; }
  pretty() { return this; }
  _all() {
    if (this.cache) return this.cache;
    let r = this.docs;
    if (this._sort) r = Q({}).find(r).sort(this._sort).all();
    if (this._skip) r = r.slice(this._skip);
    if (this._limit) r = r.slice(0, this._limit);
    if (this.proj && Object.keys(this.proj).length) r = Q({}).find(r, this.proj).all();
    // MongoDB always returns _id first; mingo appends it after the other fields in projections
    this.cache = r.map(clone).map((d) => (d && typeof d === 'object' && '_id' in d && Object.keys(d)[0] !== '_id' ? { _id: d._id, ...d } : d));
    return this.cache;
  }
  toArray() { return this._all(); }
  forEach(fn) { this._all().forEach(fn); }
  map(fn) { return this._all().map(fn); }
  count() { return this.docs.length; }
  itcount() { return this._all().length; }
  hasNext() { return this.pos < this._all().length; }
  next() { return this._all()[this.pos++]; }
  [Symbol.iterator]() { return this._all()[Symbol.iterator](); }
  explain(verbosity) {
    const c = this.coll, f = this.filter;
    const fields = Object.keys(f).filter((k) => !k.startsWith('$'));
    const usable = c.indexes.filter((ix) => ix.name !== '_id_' || fields.includes('_id')).find((ix) => !ix.text && fields.includes(Object.keys(ix.key)[0]));
    const total = c.docs.length;
    let examined = total, stage = 'COLLSCAN', keys = 0;
    if (usable) {
      const prefix = Object.keys(usable.key).filter((k) => fields.includes(k));
      const sub = Object.fromEntries(prefix.map((k) => [k, f[k]]));
      examined = Q(sub).find(c.docs).all().length;
      keys = examined; stage = 'IXSCAN';
    }
    const n = matchDocs(c, f).length;
    const out = { queryPlanner: { namespace: 'shim', winningPlan: stage === 'COLLSCAN' ? { stage: 'COLLSCAN' } : { stage: 'FETCH', inputStage: { stage: 'IXSCAN', indexName: usable.name, keyPattern: usable.key } } } };
    if (verbosity === 'executionStats') out.executionStats = { nReturned: n, totalKeysExamined: keys, totalDocsExamined: examined, executionTimeMillis: 0 };
    out._note = 'SIMULATED by mongosh_shim (plan chosen by a simple rule); run explain() on real MongoDB for the real plan';
    return out;
  }
}

// ------------------------------------------------------------------ collection
function applyUpdate(doc, update, filter, arrayFilters) {
  if (Array.isArray(update)) {                       // pipeline-style update
    const res = new Aggregator(fixRound(update), {}).run([clone(doc)])[0];
    return { ...res, _id: doc._id };
  }
  const d = clone(doc);
  const { $setOnInsert, ...ops } = update;
  if (Object.keys(ops).length === 0 && !$setOnInsert) return d;
  if (!Object.keys(ops).every((k) => k.startsWith('$'))) return { ...ops, _id: doc._id };   // replacement document
  for (const [op, val] of Object.entries(ops)) updateObject(d, { [op]: val }, arrayFilters || [], filter || {}, { cloneMode: 'none' });   // mingo: one operator per call
  return d;
}
function equalityFields(filter) {
  const o = {};
  for (const [k, v] of Object.entries(filter || {})) if (!k.startsWith('$') && (v === null || typeof v !== 'object' || v instanceof Date || v instanceof ObjectId)) o[k] = v;
  return o;
}
function setPath(o, p, v) { const ks = p.split('.'); let c = o; ks.slice(0, -1).forEach((k) => { c[k] = c[k] || {}; c = c[k]; }); c[ks.at(-1)] = v; }

class Collection {
  constructor(dbName, name) { this.dbName = dbName; this.name = name; }
  get _c() { return getColl(this.dbName, this.name); }
  _insert(doc) {
    const c = this._c;
    const d = clone(doc);
    if (d._id === undefined) d._id = new ObjectId();
    validate(c, this.dbName, this.name, d);
    checkUnique(c, this.dbName, this.name, d, null);
    c.docs.push(d);
    return d._id;
  }
  insertOne(doc) { return { acknowledged: true, insertedId: this._insert(doc) }; }
  insertMany(docs) { const ids = {}; docs.forEach((d, i) => { ids[i] = this._insert(d); }); return { acknowledged: true, insertedIds: ids }; }
  find(filter, projection) { return new Cursor(this._c, matchDocs(this._c, filter), projection, filter); }
  findOne(filter, projection) { return this.find(filter, projection).limit(1).toArray()[0] || null; }
  countDocuments(filter) { return matchDocs(this._c, filter).length; }
  estimatedDocumentCount() { return this._c.docs.length; }
  count(filter) { return this.countDocuments(filter); }
  distinct(field, filter) { const s = new Map(); matchDocs(this._c, filter).forEach((d) => { const v = getPath(d, field); (Array.isArray(v) ? v : [v]).forEach((x) => { if (x !== undefined) s.set(JSON.stringify(x), x); }); }); return [...s.values()]; }
  _update(filter, update, opts, many) {
    const c = this._c; opts = opts || {};
    const matched = matchDocs(c, filter);
    const targets = many ? matched : matched.slice(0, 1);
    let modified = 0, upsertedId, upsertedCount = 0;
    for (const d of targets) {
      const before = JSON.stringify(d);
      const nd = applyUpdate(d, update, filter, opts.arrayFilters);
      if (JSON.stringify(nd) !== before) {
        validate(c, this.dbName, this.name, nd);
        checkUnique(c, this.dbName, this.name, nd, d);
        c.docs[c.docs.indexOf(d)] = nd;
        modified++;
      }
    }
    if (targets.length === 0 && opts.upsert) {
      let base = equalityFields(filter);
      const nest = {}; Object.entries(base).forEach(([k, v]) => setPath(nest, k, v));
      let nd = applyUpdate(nest, update, filter, opts.arrayFilters);
      if (update.$setOnInsert) Object.entries(update.$setOnInsert).forEach(([k, v]) => setPath(nd, k, v));
      upsertedId = this._insert(nd); upsertedCount = 1;
    }
    return { acknowledged: true, matchedCount: targets.length, modifiedCount: modified, upsertedCount, upsertedId: upsertedId === undefined ? null : upsertedId };
  }
  updateOne(f, u, o) { return this._update(f, u, o, false); }
  updateMany(f, u, o) { return this._update(f, u, o, true); }
  replaceOne(f, r, o) { return this._update(f, r, o, false); }
  findOneAndUpdate(f, u, o) {
    o = o || {}; const before = this.findOne(f);
    this.updateOne(f, u, o);
    return o.returnDocument === 'after' ? this.findOne(before ? { _id: before._id } : f) : before;
  }
  _delete(filter, many) {
    const c = this._c; const m = matchDocs(c, filter); const t = many ? m : m.slice(0, 1);
    c.docs = c.docs.filter((d) => !t.includes(d));
    return { acknowledged: true, deletedCount: t.length };
  }
  deleteOne(f) { return this._delete(f, false); }
  deleteMany(f) { return this._delete(f, true); }
  aggregate(pipeline) {
    const c = this._c;
    let p = pipeline.map((s) => s), docs = c.docs, out = null;
    if (p.length && p[0].$match && p[0].$match.$text) {
      const { $text, ...rest } = p[0].$match;
      docs = docs.filter((d) => textMatch(d, textFieldsOf(c), $text.$search));
      p = [{ $match: rest }, ...p.slice(1)];
    }
    const last = p[p.length - 1];
    if (last && last.$out) { out = typeof last.$out === 'string' ? last.$out : last.$out.coll; p = p.slice(0, -1); }
    const resolver = (name) => getColl(this.dbName, name).docs;
    let res;
    try { res = new Aggregator(fixRound(p), { collectionResolver: resolver }).run(docs).map(clone); }
    catch (e) { throw new MongoServerError('Aggregation failed in the shim: ' + e.message, 40324, 'Location40324'); }
    if (out) {
      const t = getColl(this.dbName, out); t.docs = res.map((d) => (d._id === undefined ? { _id: new ObjectId(), ...d } : d));
      return new Cursor(c, [], null, {});
    }
    return new Cursor(c, res, null, {});
  }
  createIndex(key, opts) {
    opts = opts || {};
    const c = this._c;
    const isText = Object.values(key).includes('text');
    const name = opts.name || Object.entries(key).map(([k, v]) => `${k}_${v}`).join('_');
    if (c.indexes.some((i) => i.name === name)) return name;
    const ix = { v: 2, key, name, unique: !!opts.unique, text: isText, textFields: isText ? Object.entries(key).filter(([, v]) => v === 'text').map(([k]) => k) : null };
    if (opts.unique) {
      const seen = new Set();
      for (const d of c.docs) { const ks = keyString(ix, d); if (seen.has(ks)) throw new MongoServerError(`E11000 duplicate key error collection: ${this.dbName}.${this.name} index: ${name}`, 11000, 'DuplicateKey'); seen.add(ks); }
    }
    c.indexes.push(ix);
    return name;
  }
  getIndexes() { return this._c.indexes.map(({ v, key, name, unique }) => (unique ? { v, key, name, unique: true } : { v, key, name })); }
  dropIndex(n) { const c = this._c; const name = typeof n === 'string' ? n : Object.entries(n).map(([k, v]) => `${k}_${v}`).join('_'); const i = c.indexes.findIndex((x) => x.name === name); if (i < 1) throw new MongoServerError(`index not found with name [${name}]`, 27, 'IndexNotFound'); c.indexes.splice(i, 1); return { nIndexesWas: c.indexes.length + 1, ok: 1 }; }
  dropIndexes() { const c = this._c; c.indexes = c.indexes.slice(0, 1); return { ok: 1 }; }
  drop() { const had = !!getColl(this.dbName, this.name, false); delete (store[this.dbName] || {})[this.name]; return had; }
  renameCollection(to) { store[this.dbName][to] = store[this.dbName][this.name]; delete store[this.dbName][this.name]; return { ok: 1 }; }
  stats() { return { ns: `${this.dbName}.${this.name}`, count: this._c.docs.length, nindexes: this._c.indexes.length }; }
}

// ------------------------------------------------------------------ database
function makeDb(dbName) {
  const methods = {
    getName: () => dbName,
    getSiblingDB: (n) => makeDb(n),
    getCollection: (n) => new Collection(dbName, n),
    createCollection(n, opts) {
      if (getColl(dbName, n, false)) throw new MongoServerError(`Collection ${dbName}.${n} already exists.`, 48, 'NamespaceExists');
      const c = getColl(dbName, n);
      if (opts && opts.validator) c.validator = opts.validator;
      return { ok: 1 };
    },
    getCollectionNames: () => Object.keys(store[dbName] || {}).sort(),
    dropDatabase() { delete store[dbName]; return { ok: 1, dropped: dbName }; },
    runCommand(cmd) {
      if (cmd.collMod) { getColl(dbName, cmd.collMod).validator = cmd.validator || null; return { ok: 1 }; }
      throw new MongoServerError('Command not supported by the shim: ' + Object.keys(cmd)[0], 59, 'CommandNotFound');
    },
    version: () => '7.0.0-shim',
  };
  return new Proxy({}, { get: (_, p) => (typeof p === 'symbol' ? undefined : p in methods ? methods[p] : new Collection(dbName, p)) });
}

// ------------------------------------------------------------------ run scripts
const print = (...a) => console.log(a.map((x) => (typeof x === 'string' ? x : show(x))).join(' '));
Object.assign(globalThis, { require, db: makeDb('test'), ObjectId, ISODate, NumberInt, NumberLong, NumberDecimal, print, printjson: (x) => console.log(show(x)), sleep: () => {}, MongoServerError });
const files = process.argv.slice(2);
if (!files.length) { console.error('usage: node tools/mongosh_shim.js script.js [script2.js ...]'); process.exit(2); }
for (const f of files) {
  globalThis.db = makeDb('test');                   // every script starts in db "test", like a new mongosh session
  if (files.length > 1) console.log('##FILE ' + require('path').basename(f));
  try { vm.runInThisContext(fs.readFileSync(f, 'utf8'), { filename: f }); }
  catch (e) { console.error(`\n[shim] UNCAUGHT ERROR in ${f}: ${e.stack || e}`); process.exit(1); }
}


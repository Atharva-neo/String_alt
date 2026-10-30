/*
 * fake_mongodb.js - TEST AID: an in-memory object that mimics the small part of the official `mongodb` Node driver used by
 * Experiment 8D (db.collection(name).insertOne / find().toArray() / findOne / updateOne / deleteOne / aggregate().toArray()).
 * Built on mingo. Enabled with USE_FAKE_MONGO=1. It is NOT MongoDB - always run the API once against a real server.
 */
'use strict';
require('mingo/init/system');
const { Query, Aggregator } = require('mingo');
const { ObjectId } = require('mongodb');

const hex = (v) => (v instanceof ObjectId ? v.toHexString() : v);
function toPlain(doc) { return { ...doc, _id: hex(doc._id) }; }
function fromPlain(doc) { return { ...doc, _id: /^[0-9a-f]{24}$/.test(doc._id) ? new ObjectId(doc._id) : doc._id }; }
function plainFilter(f) { const o = { ...f }; if (o._id !== undefined) o._id = hex(o._id); return o; }

class FakeCollection {
  constructor() { this.docs = []; }
  async insertOne(doc) { const d = { _id: new ObjectId(), ...doc }; this.docs.push(d); return { acknowledged: true, insertedId: d._id }; }
  _match(filter) { return new Query(plainFilter(filter || {})).find(this.docs.map(toPlain)).all(); }
  find(filter) {
    const self = this; let sortSpec = null, lim = 0;
    const cur = {
      sort(s) { sortSpec = s; return cur; }, limit(n) { lim = n; return cur; },
      async toArray() {
        let r = self._match(filter);
        if (sortSpec) r = new Query({}).find(r).sort(sortSpec).all();
        if (lim) r = r.slice(0, lim);
        return r.map(fromPlain);
      },
    };
    return cur;
  }
  async findOne(filter) { const r = this._match(filter)[0]; return r ? fromPlain(r) : null; }
  async countDocuments(filter) { return this._match(filter).length; }
  async updateOne(filter, update) {
    const m = this._match(filter)[0];
    if (!m) return { acknowledged: true, matchedCount: 0, modifiedCount: 0 };
    const i = this.docs.findIndex((d) => hex(d._id) === m._id);
    if (update.$set) Object.assign(this.docs[i], update.$set);
    if (update.$inc) for (const [k, v] of Object.entries(update.$inc)) this.docs[i][k] = (this.docs[i][k] || 0) + v;
    return { acknowledged: true, matchedCount: 1, modifiedCount: 1 };
  }
  async deleteOne(filter) {
    const m = this._match(filter)[0];
    if (!m) return { acknowledged: true, deletedCount: 0 };
    this.docs.splice(this.docs.findIndex((d) => hex(d._id) === m._id), 1);
    return { acknowledged: true, deletedCount: 1 };
  }
  aggregate(pipeline) { return { toArray: async () => new Aggregator(pipeline).run(this.docs.map(toPlain)) }; }
}
class FakeDb {
  constructor() { this.cols = {}; }
  collection(n) { return (this.cols[n] = this.cols[n] || new FakeCollection()); }
}
module.exports = { FakeDb };

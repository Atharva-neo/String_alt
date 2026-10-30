# Experiment_07_MongoDB / 7B_Ecommerce

Requires MongoDB 7 and `mongosh` (or Compass' embedded shell). Every script starts with `db = db.getSiblingDB(...)`, so each file can be run on its own
(in the order below because later files use the data created by earlier ones). All scripts are re-runnable: they drop / reload their own collections.

```bash
# from this folder, against mongodb://localhost:27017
mongosh --quiet --file schema.js
mongosh --quiet --file insert_data.js
mongosh --quiet --file queries.js
mongosh --quiet --file aggregation.js
mongosh --quiet --file indexes.js
mongosh --quiet --file crud.js
```

Or against another server: `mongosh "mongodb://user:pass@host:27017" --quiet --file schema.js`.

| File | Purpose |
|------|---------|
| `schema.js` | database / collections with `$jsonSchema` validation |
| `insert_data.js` | the documents given in the PDF |
| `crud.js` | update / delete tasks (`$set`, `$inc`, `$push`, `$pull`, `$addToSet`, ...) |
| `queries.js` | find / projection / operators / sort / limit tasks |
| `aggregation.js` | pipeline tasks |
| `indexes.js` | single, compound and text indexes + `explain()` |
| `expected_output.md` | transcript of the scripts (see the note at its top about how it was produced) |
| `explanation.md` | document structure diagram + explanation of every task |
| `viva_questions.md` | viva Q&A |

Test without a server: `python ../../tools/run_mongo.py Experiment_07_MongoDB/7B_Ecommerce` (needs `npm install` once in the repository root).

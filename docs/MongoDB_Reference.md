# MongoDB 7 / mongosh quick reference

```js
db = db.getSiblingDB("shopDB")                        // in script files; "use shopDB" only works interactively
db.createCollection("c", { validator: { $jsonSchema: { bsonType: "object", required: ["name"], properties: { price: { bsonType: ["int","double"], minimum: 0 } } } } })
db.c.insertOne({..}); db.c.insertMany([{..},{..}])
db.c.find({ price: { $gte: 400, $lte: 2000 }, category: { $in: ["A","B"] } }, { name: 1, _id: 0 }).sort({ price: -1 }).limit(2)
```
| Need | Operator |
|---|---|
| comparison | `$eq $ne $gt $gte $lt $lte $in $nin` |
| logical | `$and $or $nor $not` (implicit AND between fields) |
| array | `{tags:"x"}` contains, `$all`, `$size`, `$elemMatch` (same element), `"arr.field"` |
| embedded | dot notation `"address.city"` |
| update | `$set $unset $inc $mul $rename $min $max $currentDate` ; arrays `$push $addToSet $pull $pop` (`$each`) |
| update pipeline (4.2+) | `updateMany(f, [ { $set: { total: { $add: ["$ise","$ese"] } } } ])` |
| delete | `deleteOne`, `deleteMany`, `drop()` |
| result | `matchedCount`, `modifiedCount`, `upsertedId`, `deletedCount` |

## Aggregation stages
`$match $group $sort $project $set/$addFields $unset $unwind $lookup $limit $skip $count $out $merge $facet $bucket $setWindowFields`
* `$group: {_id: "$k", n: {$sum: 1}, avg: {$avg: "$x"}, first: {$first: "$x"}, all: {$push: "$x"}, set: {$addToSet: "$x"}}`
* `$lookup: {from, localField, foreignField, as}` (or `let` + `pipeline`) = LEFT JOIN; follow with `$unwind`.
* Expressions: `$cond`, `$switch`, `$size`, `$map`, `$filter`, `$reduce`, `$arrayElemAt`, `$round`, `$dateToString`, `$hour`, `$multiply`, `$divide`.

## Indexes and explain
`createIndex({a:1})`, compound `{a:1,b:-1}` (ESR rule: Equality, Sort, Range), text `{title:"text", plot:"text"}` + `{$text:{$search:"city -ocean"}}`, unique `{unique:true}`, `getIndexes()`, `dropIndex(name)`.
`find(q).explain("executionStats")`: `COLLSCAN` vs `IXSCAN`; compare `totalDocsExamined` with `nReturned`.

## Modelling
Embed: 1:1 or 1:few, read together, owned by parent (comments, order lines, contact). Reference: many-to-many, shared, large or unbounded (products, students, courses) - join with `$lookup`.

## Replica set / change streams
`mongod --replSet rs0` + `rs.initiate()`; `db.coll.watch([pipeline])` (mongosh) / `collection.watch()` (PyMongo); needs oplog; resume with `resumeAfter` token.

## Errors
121 DocumentValidationFailure | 11000 DuplicateKey | 27 IndexNotFound | 59 CommandNotFound.

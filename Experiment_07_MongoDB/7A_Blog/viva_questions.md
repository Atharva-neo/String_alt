# Viva questions - 7A Blog (MongoDB)

**Q1. What is a collection / document / database in MongoDB?** Database = container of collections; collection = group of documents (like a table, no fixed schema unless a validator is set); document = BSON object with fields, nested documents and arrays (like a row, but richer).

**Q2. What is `_id`?** The mandatory unique primary key of every document; indexed automatically. If not supplied, the driver creates an ObjectId.

**Q3. Difference between `insertOne` and `insertMany`?** One document vs an array of documents in one call; insertMany is ordered by default (stops at the first error).

**Q4. How does `find({tags:"mongodb"})` work on an array?** It matches documents whose `tags` array contains an element equal to "mongodb".

**Q5. What is projection?** The second argument of `find` that selects the returned fields: `{title:1, likes:1, _id:0}`. You cannot mix inclusion and exclusion except for `_id`.

**Q6. Why `$elemMatch`?** To require several conditions on the same array element. `{ "comments.likes": {$gte:3}, "comments.user":"Sneha" }` can match different comments (output shows 1 without, 0 with `$elemMatch`).

**Q7. Difference between `$push`, `$addToSet`, `$pull`?** `$push` appends (duplicates allowed); `$addToSet` appends only if not present; `$pull` removes all elements matching a condition.

**Q8. Why use `$inc` instead of reading and writing the value?** `$inc` is atomic on the server, so concurrent increments are not lost.

**Q9. What do `$unwind` and `$group` do?** `$unwind` outputs one document per array element; `$group` groups documents by `_id` and applies accumulators ($sum, $avg, $push...).

**Q10. Embedded vs referenced data - when which?** Embed data that is read together, bounded and owned by the parent (comments); reference data that is shared, large, unbounded or queried independently (products referenced from orders).

**Q11 (follow-up). How are dates compared?** BSON Date type, compare with `ISODate(...)`; store dates as Date, never as strings.

**Q12 (follow-up). What does `modifiedCount: 0` with `matchedCount: 3` mean?** Documents matched but the update changed nothing (e.g. `$addToSet` of an existing value).

**Q13 (follow-up). SQL equivalents?** `find` ~ SELECT ... WHERE, projection ~ column list, `$group` ~ GROUP BY, `$unwind` ~ flattening a one-to-many join, `$lookup` ~ LEFT JOIN.

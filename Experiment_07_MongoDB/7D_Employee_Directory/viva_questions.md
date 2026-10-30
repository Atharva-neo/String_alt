# Viva questions - 7D Employee directory (MongoDB)

**Q1. How do you query a field of an embedded document?** Dot notation in quotes: `{"address.city": "Pune"}`. `{address: {city: "Pune"}}` would require the whole sub-document to be equal.

**Q2. `$all` vs `$in`?** `$all` requires every listed value in the array (AND); `$in` requires at least one (OR).

**Q3. `$nin` vs `$not`?** `$nin` = not in a list of values; `$not` negates an operator expression such as a range. Both also match documents where the field is missing.

**Q4. Why did the "not between 40000 and 60000" query return nothing?** All salaries lie inside the inclusive range; with an exclusive range the boundary salaries (40000, 60000) qualify.

**Q5. `$push` vs `$addToSet`?** `$push` may duplicate; `$addToSet` keeps the array a set.

**Q6. What does `$rename` do and is it atomic?** Renames a field in every matched document; each document is updated atomically, the multi-document `updateMany` is not.

**Q7. How do you update one field of an embedded document without replacing it?** `$set` with dot notation: `{"address.city": "Satara"}`; assigning `address: {...}` would overwrite the whole sub-document.

**Q8. What does `getIndexes()` show and what does a multikey index mean?** Lists index definitions. An index on an array field (e.g. `skills`) is multikey: one entry per element.

**Q9. How does the index on `address.city` help?** `explain` changes from COLLSCAN to IXSCAN; only matching entries are read.

**Q10. How do you count the remaining documents?** `countDocuments()` (exact) or `estimatedDocumentCount()` (metadata, fast).

**Q11 (follow-up). `deleteMany({})` and `drop()` difference?** Documents only vs the whole collection with indexes.

**Q12 (follow-up). Case-insensitive search?** Use a regex with `i` (not index friendly) or a collation / case-insensitive index.

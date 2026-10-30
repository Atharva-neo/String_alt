# Viva questions - 7B E-commerce (MongoDB)

**Q1. Embed or reference?** Order lines embedded (read with the order); products referenced by `prod_id` (shared, independently updated).

**Q2. What does `$lookup` do?** Left outer join: matches `localField` to `foreignField` of another collection and stores matches in an array (`as`); `$unwind` flattens it.

**Q3. Why `$unwind` before `$lookup` in Task 5?** `items` is an array; one document per item lets each item join exactly one product.

**Q4. `$in` vs `$or`?** `$in` is shorthand for an `$or` of equalities on one field; `$or` handles different fields.

**Q5. Products never ordered?** `$lookup` orders by `items.prod_id`, `$match` empty array (`$size: 0`); or `distinct` + `$nin`.

**Q6. What does `explain("executionStats")` show?** Plan (COLLSCAN/IXSCAN), `nReturned`, `totalKeysExamined`, `totalDocsExamined`; a good index makes docs examined close to docs returned.

**Q7. Why is `{category:1, price:1}` suitable?** Equality on the first key, range on the second (ESR rule).

**Q8. How was stock reduced?** `updateOne({_id}, {$inc:{stock:-qty}})` per item (atomic). Multi-document atomicity needs a transaction (replica set).

**Q9. What keeps stock >= 0?** The `$jsonSchema` validator; stronger: `updateOne({_id, stock:{$gte:qty}}, ...)` and check `modifiedCount`.

**Q10. `deleteMany({})` vs `drop()`?** First keeps collection and indexes, second removes the collection.

**Q11 (follow-up). Foreign keys?** None in MongoDB; the application must keep references valid.

**Q12 (follow-up). Is `$lookup` as fast as a SQL join?** Needs an index on `foreignField`; heavy joins suggest re-modelling.

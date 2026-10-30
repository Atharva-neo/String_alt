# Viva questions - 7C Movie catalogue (MongoDB)

**Q1. How do you query an element inside an array of embedded documents?** Dot notation: `{"cast.name": "Actor A"}`; several conditions on the same element need `$elemMatch`.

**Q2. `{genre: "Sci-Fi"}` on an array field?** Matches if any element equals "Sci-Fi".

**Q3. What does `$size: 2` do?** Matches arrays with exactly two elements (no ranges; use a stored count or `$expr`/`$size` in aggregation for `>`).

**Q4. How do you count films per actor?** `$unwind: "$cast"` then `$group: {_id: "$cast.name", films: {$sum: 1}}`.

**Q5. Why does a two-genre movie appear twice in Task 7?** `$unwind` creates one document per genre, so it contributes to both genre averages.

**Q6. How does `$first` give the best movie per year?** `$sort` by rating descending first; `$group` then takes the first document of each year group.

**Q7. What is a text index? Limits?** Tokenises and stems string fields for `$text` search; only one per collection; case/diacritic insensitive; needs the index to run `$text`.

**Q8. `$addToSet` vs `$push`?** `$addToSet` ignores duplicates.

**Q9. Why a pipeline update with `$round` for +0.2?** Binary floating point: 8.1 + 0.2 = 8.299999999999999. Use `$round` (or store integers / Decimal128 for money).

**Q10. `$pull` with a condition?** `$pull: {cast: {name: "Actor B"}}` removes every array element matching the condition.

**Q11 (follow-up). `updateOne` with an aggregation pipeline - since when?** MongoDB 4.2.

**Q12 (follow-up). What is `_id` of these movies?** An auto-generated ObjectId (12 bytes: timestamp, random, counter).

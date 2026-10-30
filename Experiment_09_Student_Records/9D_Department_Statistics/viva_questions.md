# Viva questions - 9D Department and semester statistics

**Q1. How do you group by two fields?** `_id` of `$group` is a sub-document: `{_id: {dept: "$dept", semester: "$semester"}}`.

**Q2. How do you find documents without a related document?** `$lookup` then `$match` on the empty array (`$size: 0`) - the MongoDB version of a LEFT JOIN ... IS NULL.

**Q3. Why did Tasks 4 and 5 return nothing?** The PDF data contains no student failing two courses and every student has an exam record; the pipeline is correct (the temporary student proves Task 5).

**Q4. `$inc` for promotion - why not `$set`?** `$inc` adds to the current value atomically per document and needs no read; `$set` would require knowing the value.

**Q5. `$unset` syntax?** `{$unset: {"contact.email": ""}}` - the value is ignored; dot notation removes the field of the embedded document only.

**Q6. How do you back up a collection with the shell?** `aggregate([{$match: {}}, {$out: "backup"}])` (or `mongodump`); remove it with `drop()`.

**Q7. How do you enrol a student into a new course in this schema?** Insert the attendance (and later exam) document for the pair (student_id, course_id).

**Q8. Why an index on `{dept: 1, semester: 1}`?** Equality filters/groupings on dept and semester can use the index prefix; `explain` shows COLLSCAN -> IXSCAN.

**Q9. What does `getCollectionNames()` return?** An array of collection names of the current database.

**Q10. Average marks per department needs which stage?** `$lookup` (exams hold no dept) and `$group` with `$avg`.

**Q11 (follow-up). `$group` vs `$bucket`?** `$group` groups by exact value; `$bucket` groups ranges (e.g. marks bands).

**Q12 (follow-up). Born after a date - which type is `dob`?** BSON Date; compare with `ISODate()`.

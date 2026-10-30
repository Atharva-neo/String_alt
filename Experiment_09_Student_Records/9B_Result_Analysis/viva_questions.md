# Viva questions - 9B Result analysis

**Q1. How do you find the topper of every course?** `$sort` by total descending, `$group` by course with `$first` (student, total), then `$lookup` the student name.

**Q2. Why does `$first` need a preceding `$sort`?** `$first` returns the first document of each group in the incoming order; without sorting it is arbitrary.

**Q3. How is the pass percentage computed?** `passed = $sum of $cond(total >= 40, 1, 0)`; `passed / appeared x 100`.

**Q4. How do you assign grades in one statement?** An update with an aggregation pipeline (`updateMany(filter, [ {$set: {grade: {$switch: ...}}} ])`, MongoDB 4.2+).

**Q5. What does `$switch` do?** A multi-branch conditional: first `case` that is true yields its `then`, otherwise `default`.

**Q6. How do you list students above the course average?** `$setWindowFields` (MongoDB 5+) computes the average per course on each document, then `$match` with `$expr`; alternative: two queries or `$group` + `$unwind`.

**Q7. Why recompute `total` in the revaluation update?** `total` is derived (`ise + ese`); updating `ese` alone would leave it inconsistent. A pipeline update reads the new `ese` in the next stage.

**Q8. Why is Task 11 empty?** No student has ISE >= 30 together with ESE < 30 in the data; the query is correct.

**Q9. `deleteMany({total: 0})` removes what?** All absentee records; it returns `deletedCount`.

**Q10. Faculty-wise average - why `$lookup`?** Faculty is stored in `courses`, not in `exams`.

**Q11 (follow-up). What is the difference between `$group` and `$setWindowFields`?** `$group` collapses documents into one per group; `$setWindowFields` keeps every document and adds computed fields.

**Q12 (follow-up). How would you rank students within a course?** `$setWindowFields` with `$rank` / `$denseRank` over `sortBy: {total: -1}`.

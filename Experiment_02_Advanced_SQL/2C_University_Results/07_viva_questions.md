# Viva questions - 2C University Results

**Q1. Meaning of `> ALL` and `> ANY` in Tasks 3 and 4?** `> ALL` = bigger than the biggest value in the subquery (> 78); `> ANY` = bigger than at least one value, i.e. bigger than the smallest (> 55).

**Q2. Why does Task 3 return only Chetan?** AIML DBMS marks are 78 and 35; only Chetan's 91 exceeds both. Asha's 78 is not greater than her own 78.

**Q3. How do you find the topper per subject?** Join to `SELECT sub_id, MAX(marks) GROUP BY sub_id`, or `RANK() OVER (PARTITION BY sub_id ORDER BY marks DESC) = 1`. Ties return several toppers.

**Q4. Difference between RANK, DENSE_RANK, ROW_NUMBER?** With marks 90, 90, 80: RANK 1,1,3; DENSE_RANK 1,1,2; ROW_NUMBER 1,2,3.

**Q5. What does `SUM(marks < 40)` do?** The boolean is 1/0 in MySQL, so SUM counts failures. Portable form: `SUM(CASE WHEN marks < 40 THEN 1 ELSE 0 END)`.

**Q6. NOT IN risk in Task 9?** If `Marks.roll_no` could be NULL, `NOT IN` would return nothing. Here the column is NOT NULL (part of the PK).

**Q7. Why is the below_40 view updatable?** It is a join but an UPDATE changes only Marks columns; no aggregates/DISTINCT. Updating columns of two base tables at once raises error 1393.

**Q8. What happened to the row after the update to 45?** It disappeared from the view because the view predicate marks < 40 no longer holds. WITH CHECK OPTION would have rejected the update (error 1369).

**Q9. Does a view hold data?** No, it re-runs its SELECT every time.

**Q10. Why use HAVING AVG(marks) > 60 instead of WHERE?** The average is a group value.

**Q11 (follow-up). How to list students without any marks?** LEFT JOIN Marks and test `m.roll_no IS NULL` or NOT EXISTS.

**Q12 (follow-up). Which constraint is missing in Marks?** `marks <= max_marks` of the subject; cross-table checks need a trigger (Experiment 4).

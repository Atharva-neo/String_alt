# Viva questions - 2A Employee-Department

**Q1. INNER vs LEFT vs RIGHT join?** INNER: matching rows only. LEFT: all left rows plus matches (NULLs otherwise). RIGHT: all right rows. MySQL has no FULL OUTER JOIN (use LEFT UNION RIGHT).

**Q2. Why LEFT JOIN in the manager query?** The president has manager_id NULL; an INNER self join would drop him.

**Q3. Correlated vs non-correlated subquery?** A correlated subquery references a column of the outer query and re-executes per outer row (Task 5); a non-correlated one runs once (Task 8).

**Q4. What do `> ALL` and `> ANY` mean?** `> ALL` greater than the maximum of the set, `> ANY` greater than the minimum. `= ANY` is the same as `IN`; `<> ALL` is the same as `NOT IN`.

**Q5. Why are Nikhil's results missing from Task 7?** The JOIN is INNER and dept_no is NULL; also the department Operations has 0 employees. Use LEFT JOINs if they must appear.

**Q6. Two ways to find the second highest salary?** Nested MAX with `<`, or `DENSE_RANK() OVER (ORDER BY salary DESC) = 2`; LIMIT 1 OFFSET 1 on DISTINCT salaries also works.

**Q7. WHERE vs HAVING?** WHERE filters rows before grouping and cannot use aggregates; HAVING filters groups.

**Q8. When is a view updatable?** Single table or simple join, no DISTINCT, GROUP BY, HAVING, aggregate, UNION, or subquery in select list. `dept_summary` aggregates, so UPDATE gives error 1288.

**Q9. What does WITH CHECK OPTION do?** Rejects INSERT/UPDATE through the view that would make the row invisible in the view (ADV 8, error 1369).

**Q10. Why does Rohit not appear in Task 10?** He was hired 2019-07-01, which is not *after* 2019 (year > 2019).

**Q11 (follow-up). RANK vs DENSE_RANK vs ROW_NUMBER?** RANK leaves gaps after ties (1,1,3), DENSE_RANK does not (1,1,2), ROW_NUMBER gives unique numbers.

**Q12 (follow-up). Does a view store data?** No, only the query (except materialised views in Oracle). Dropping the view does not touch base tables.

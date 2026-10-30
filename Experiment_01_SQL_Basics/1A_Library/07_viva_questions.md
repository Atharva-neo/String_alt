# Viva questions - 1A Library

**Q1. Why is `Issue` needed? Why not store the member inside `Book`?**
Book-Member is many-to-many (a member borrows many books, a book is borrowed by many members over time). A relational table cannot hold a multi-valued attribute, so the M:N is resolved with a junction table whose FKs point to both parents and which carries its own attributes (`issue_date`, `return_date`).

**Q2. What error do you get for an issue of book `B999` and why?**
`ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails`. `B999` does not exist in the parent `Book` table, so referential integrity forbids the child row.

**Q3. Difference between PRIMARY KEY and UNIQUE?**
PK: one per table, never NULL, identifies the row. UNIQUE: many per table, may allow NULLs (several), only forbids duplicate non-NULL values. `phone` is UNIQUE because it is an alternate key, not the identifier.

**Q4. Is CHECK enforced in your MySQL?** Yes from 8.0.16. In 5.7 and older, the syntax was accepted and silently ignored, which is why `price = -50` only fails on MySQL 8.0.16+.

**Q5. Why does `CHECK (return_date >= issue_date)` allow rows where `return_date IS NULL`?**
A CHECK passes when the expression is TRUE *or UNKNOWN*. NULL >= date is UNKNOWN, so open loans are allowed.

**Q6. Why is `DEFAULT (CURRENT_DATE)` in brackets?** Only a literal default is allowed without brackets; function-based (expression) defaults need `( )`, supported from 8.0.13.

**Q7. DELETE vs TRUNCATE vs DROP?**
DELETE: DML, WHERE allowed, row-by-row, can be rolled back, keeps AUTO_INCREMENT. TRUNCATE: DDL, all rows, faster, resets AUTO_INCREMENT, implicit commit. DROP: removes data and structure (and indexes, triggers) of the table.

**Q8. Why was the "more than one unreturned book" query empty?** After Task 8, B103 is returned, so no member holds two open loans. HAVING COUNT(*) > 1 correctly returns no rows; the second run shows it works when M01 holds two.

**Q9. Why HAVING and not WHERE for `COUNT(*) > 1`?** WHERE filters rows before grouping; HAVING filters groups after aggregation.

**Q10. After `REVOKE INSERT`, what can `librarian` still do?** Only `SELECT` on `library_1a.Issue`; an INSERT gives `ERROR 1142: INSERT command denied`.

**Q11 (follow-up). What happens to child rows with `ON DELETE CASCADE`? With `SET NULL`?** CASCADE deletes the child rows; SET NULL stores NULL in the FK column (the column must be nullable).

**Q12 (follow-up). Can a DDL statement be rolled back?** No, MySQL commits implicitly before and after DDL (ALTER, TRUNCATE, DROP). In Oracle also true.

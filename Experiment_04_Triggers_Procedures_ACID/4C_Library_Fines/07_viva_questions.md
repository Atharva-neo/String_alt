# Viva questions - 4C Library fines

**Q1. Why is the fine calculated in a BEFORE UPDATE trigger?** Only a BEFORE trigger can assign to `NEW.fine`, so the value is stored by the same UPDATE statement. An AFTER trigger would need a second UPDATE on the same table, which MySQL forbids (error 1442).

**Q2. Why the condition `OLD.return_date IS NULL AND NEW.return_date IS NOT NULL`?** The fine and the stock increment must happen once, at the moment of return; later edits must not recharge or re-increment (ADV 2).

**Q3. How much is the fine for book 1?** Due 15-Oct, returned 20-Oct: 5 days x 5 = 25.

**Q4. What does SAVEPOINT do?** Marks a point in the transaction. `ROLLBACK TO SAVEPOINT after_b1` undoes only the second issue; the transaction remains open and COMMIT then makes the first issue permanent.

**Q5. Difference between ROLLBACK and ROLLBACK TO SAVEPOINT?** ROLLBACK ends the transaction and undoes everything; ROLLBACK TO undoes part and keeps the transaction (and locks acquired before the savepoint) active.

**Q6. Why `SELECT ... FOR UPDATE` in issue_book?** It locks the Book row, so two concurrent issues of the last copy are serialised and the loser sees available = 0.

**Q7. How does the 3-book limit trigger work and why BEFORE?** It counts unreturned issues of NEW.member; if >= 3 it SIGNALs, which cancels the INSERT before anything is written.

**Q8. What happens when you call a dropped procedure?** Error 1305: PROCEDURE library_4c.overdue_list does not exist.

**Q9. Why a function for total_fine and a procedure for overdue_list?** The function returns a single value for use in SELECT; the procedure prints several rows through a cursor loop.

**Q10. What are the cursor steps?** DECLARE, OPEN, FETCH (until NOT FOUND handler sets the flag), CLOSE.

**Q11 (follow-up). Can a trigger on Issue update Book? Can it update Issue itself?** It can update other tables (Task 3). Updating the table that fired the trigger is not allowed (use BEFORE + NEW).

**Q12 (follow-up). Which sessions see the uncommitted issue made inside the savepoint demo?** None, until COMMIT (isolation); other sessions would wait on the locked Book row.

# Viva questions - 4B Payroll

**Q1. Why is the "no decrease" rule a BEFORE trigger and the audit an AFTER trigger?** BEFORE can stop the change (SIGNAL) before it is written; AFTER runs only if the change succeeded, so the audit never records rejected updates.

**Q2. How can a BEFORE INSERT trigger store a value in a NOT NULL column that was supplied as NULL?** Triggers run before the NOT NULL check, so `SET NEW.salary = 20000` fixes the value in time.

**Q3. Explain the cursor loop in give_raise.** DECLARE CURSOR, OPEN, FETCH row by row into variables, a NOT FOUND handler sets `done = 1`, LEAVE the loop, CLOSE. It processes the result set row by row.

**Q4. Why not just `UPDATE Employee SET salary = salary*1.1 WHERE dept = d`?** That is set-based and faster; the cursor version is required to demonstrate row-by-row processing and to print each new salary.

**Q5. What is the difference between CONTINUE and EXIT handlers?** CONTINUE resumes after the statement that raised the condition; EXIT terminates the BEGIN...END block in which it is declared.

**Q6. OUT parameters - how do you read them?** Pass a user variable (`@total`) in CALL; read it with SELECT in the same session.

**Q7. Annual tax rule?** Slab: 0 up to 5,00,000; 10% on the portion above it (assuming the salary is monthly). Anil: (792000 - 500000) x 10% = 29200.

**Q8. What happened to Chirag's update to 30000?** Error 1644 "Salary cannot be reduced"; the row and the audit table are unchanged.

**Q9. Why does the ROLLBACK in Task 12 also remove audit rows?** The audit INSERT ran inside the same transaction (triggers execute in the caller's transaction).

**Q10. Can the handler version of give_raise still raise an error to the caller?** No, it converts the error into a normal result row; use RESIGNAL to propagate.

**Q11 (follow-up). How many triggers can exist for one table/event/timing?** MySQL 8 allows several with FOLLOWS/PRECEDES to order them.

**Q12 (follow-up). Difference from Oracle?** Oracle triggers use `:NEW`/`:OLD`, `RAISE_APPLICATION_ERROR`, and a single `CREATE OR REPLACE TRIGGER` can cover INSERT OR UPDATE with `INSERTING/UPDATING` predicates.

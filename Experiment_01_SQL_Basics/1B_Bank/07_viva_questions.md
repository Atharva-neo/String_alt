# Viva questions - 1B Bank

**Q1. Cardinalities in the ER diagram?** Branch 1:N Account, Customer 1:N Account. A customer may open many accounts (C1 has two); each account belongs to exactly one customer and one branch.

**Q2. Which constraints stop `balance = 500` and `acc_type = 'Fixed'`?** `chk_acc_balance CHECK (balance >= 1000)` and `chk_acc_type CHECK (acc_type IN ('Savings','Current'))`, both error 3819.

**Q3. What does DEFAULT 'Savings' do?** If acc_type is omitted in INSERT the column gets 'Savings'. It does not apply when an explicit value (even NULL) is given.

**Q4. How do you give a user the right to change only `balance`?** Column privilege: `GRANT SELECT, UPDATE (balance) ON bank_1b.Account TO 'cashier'@'localhost';`. Updating acc_type gives ERROR 1143.

**Q5. Why did we copy the table before DELETE/TRUNCATE?** To keep the real data safe; `CREATE TABLE ... AS SELECT` copies rows but not constraints or indexes.

**Q6. Does RENAME TABLE break foreign keys?** No. MySQL updates FK definitions automatically (see the referential_constraints output).

**Q7. Difference between TRUNCATE and DELETE (no WHERE)?** TRUNCATE is DDL (implicit commit, resets AUTO_INCREMENT, no row-level triggers); DELETE is DML, logged row by row and rollback-able.

**Q8. Why `balance * 1.04` and DECIMAL, not FLOAT?** DECIMAL is exact for money; FLOAT has rounding error.

**Q9. How is `HAVING` different from `WHERE` in Task 5?** WHERE filters rows before grouping, HAVING filters aggregated groups.

**Q10. Why LEFT JOIN in the branch total query?** To list branches that have no accounts (total 0 through COALESCE) instead of dropping them.

**Q11 (follow-up). What if the cashier is revoked while connected?** Privilege changes take effect for the next statement for table/column privileges (global privileges at next connection).

**Q12 (follow-up). Oracle equivalents?** `RENAME`, `ALTER TABLE ... MODIFY`, `GRANT UPDATE (balance) ON Account TO cashier`, `SYSDATE`.

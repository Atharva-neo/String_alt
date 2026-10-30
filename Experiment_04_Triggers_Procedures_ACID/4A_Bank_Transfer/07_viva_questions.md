# Viva questions - 4A Bank transfer

**Q1. What is a trigger? Difference between BEFORE and AFTER?** Code fired automatically by INSERT/UPDATE/DELETE. BEFORE runs before the row is written (can validate or change `NEW`, or reject with SIGNAL); AFTER runs once the row change is done (used for logging/auditing).

**Q2. What do `NEW` and `OLD` mean?** `NEW` = row after the change (INSERT/UPDATE), `OLD` = row before (UPDATE/DELETE).

**Q3. How do you raise an error from a trigger/procedure?** `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '...'` (user-defined error 1644). Oracle: `RAISE_APPLICATION_ERROR`.

**Q4. Procedure vs function?** Procedure: invoked with CALL, may have IN/OUT/INOUT, may return result sets or change data. Function: returns exactly one value, used inside expressions (`SELECT get_balance(acc_no)`), cannot return a result set.

**Q5. What does the EXIT HANDLER do in transfer_funds?** On any SQL exception it executes ROLLBACK and RESIGNAL (re-raises the same error) so the caller sees the error and no half-transfer is left.

**Q6. Why `SELECT ... FOR UPDATE` inside the procedure?** It locks the source row so no other transaction can change the balance between the check and the debit (prevents lost update/overdraft race).

**Q7. Which ACID property does each demo show?** Atomicity: Task 7 (nothing changes after the failed transfer) and crash rollback; Consistency: min-balance trigger/total money unchanged; Isolation: Task 10 (S2 sees old balances, its UPDATE waits); Durability: Task 11 (survives a kill/restart).

**Q8. Why are there gaps in log_id?** AUTO_INCREMENT values consumed by rolled-back inserts are not reused.

**Q9. Why is `READS SQL DATA` written on get_balance?** With binary logging enabled MySQL demands a characteristic (DETERMINISTIC, NO SQL, READS SQL DATA) or error 1418.

**Q10. What happens to the Txn_Log after DROP TRIGGER?** Updates still work but nothing is logged (Task 12).

**Q11 (follow-up). Why can a trigger not call COMMIT/ROLLBACK?** It runs inside the transaction of the statement that fired it; transaction control would break statement atomicity (error 1422).

**Q12 (follow-up). What if both accounts are updated in opposite order by two transfers?** Possible deadlock (Experiment 5C); lock rows in a fixed order or retry.

# Viva questions - 6B Medical store

**Q1. Why can't a CHECK constraint block expired batches?** CHECK must be deterministic and cannot reference `CURRENT_DATE`; a BEFORE INSERT trigger can.

**Q2. How do you list medicines expiring in the next 30 days?** `expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)`. Oracle: `BETWEEN SYSDATE AND SYSDATE + 30`.

**Q3. Which batch has the maximum quantity per supplier?** Correlated subquery on the same supplier (BT01, BT02, BT03); window alternative `ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY qty DESC)`.

**Q4. What does FEFO mean?** First-expired-first-out: sell the batch that expires earliest (ADV 1) to reduce waste.

**Q5. How does `delete_expired` return the count?** OUT parameter set from `ROW_COUNT()` right after the DELETE.

**Q6. What does `sell_medicine` check?** Batch exists, not expired, quantity positive and available; locks the row with FOR UPDATE to avoid two simultaneous sales overselling it.

**Q7. Why can the pharmacist read `low_stock` but not `Medicine_Batch`?** Privileges are per object; the view's SQL SECURITY DEFINER lets the user see only the view rows without any right on the base table.

**Q8. Why did `UPDATE ... SET qty = qty - 1 WHERE batch_no = ...` fail for the pharmacist?** Reading `qty` and `batch_no` requires SELECT on those columns; UPDATE(qty) only allows writing qty. A constant assignment `SET qty = 40` passes, which shows column grants are a weak tool - prefer EXECUTE on a procedure.

**Q9. What privileges does the auditor have?** `GRANT SELECT ON medical_6b.*`: read-only; INSERT/DELETE give ERROR 1142.

**Q10. What is the effect of `DROP USER`?** Removes the account and all its privileges; open sessions of that user continue until they disconnect.

**Q11 (follow-up). What if the system date is wrong?** All expiry logic uses the DB server's clock; keep NTP synchronised.

**Q12 (follow-up). Why store expiry per batch and not per medicine?** The same medicine can come in many deliveries with different expiry; the batch is the unit of stock and recall.

# Viva questions - 5B Isolation levels

**Q1. Name the three read anomalies.** Dirty read, non-repeatable read, phantom read.

**Q2. Which anomalies are possible at each level (SQL standard)?** READ UNCOMMITTED: all three; READ COMMITTED: non-repeatable + phantom; REPEATABLE READ: phantom (in InnoDB plain reads are phantom-free); SERIALIZABLE: none. Our measured table (Task 11) matches this.

**Q3. What is the default level in MySQL/InnoDB and in Oracle?** MySQL: REPEATABLE READ. Oracle: READ COMMITTED (it has no READ UNCOMMITTED).

**Q4. Why did S2's plain count not change under REPEATABLE READ although S1 inserted A4?** InnoDB uses MVCC: the first read creates a snapshot used for all plain reads of that transaction. A locking read (`FOR UPDATE`) reads current committed data and shows the phantom.

**Q5. Why was S1's INSERT blocked under SERIALIZABLE?** SERIALIZABLE converts plain SELECTs into `LOCK IN SHARE MODE`; S2 holds shared next-key/gap locks on the scanned range, which prevent inserts into it until S2 ends.

**Q6. Difference between non-repeatable read and phantom?** Non-repeatable: an existing row changes between two reads. Phantom: the set of rows matching a predicate changes (rows appear/disappear).

**Q7. How is double booking prevented?** `SELECT ... FOR UPDATE` on the seat row (second user waits then sees 'Booked'), or a conditional UPDATE with a check of the affected row count.

**Q8. SET SESSION vs SET GLOBAL?** SESSION: only this connection, immediately for its next transactions. GLOBAL: default for connections opened afterwards; running sessions are unaffected (Task 10).

**Q9. Why is READ UNCOMMITTED hardly ever used?** Dirty reads show data that may be rolled back; the speed gain in InnoDB is negligible because reads are already non-blocking.

**Q10. Which isolation level would you choose for seat booking and why?** READ COMMITTED/REPEATABLE READ plus FOR UPDATE on the booking step; SERIALIZABLE costs concurrency and causes deadlocks (Task 12).

**Q11 (follow-up). What is MVCC?** Multi-version concurrency control: readers use old row versions from the undo log, so they do not block writers and vice versa.

**Q12 (follow-up). Can REPEATABLE READ still produce a lost update?** Yes, with read-then-write from a stale value (5A); use FOR UPDATE or atomic updates.

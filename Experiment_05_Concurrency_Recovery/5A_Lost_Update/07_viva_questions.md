# Viva questions - 5A Lost update

**Q1. Define the lost update problem.** Two transactions read the same value, compute independently and write back; the second write overwrites the first, so one update is lost (final 50 instead of 20).

**Q2. Why did S2's UPDATE wait in Task 3 even under READ UNCOMMITTED?** Isolation levels control *reads*; writes always take an exclusive row lock, so S2 waited for S1's COMMIT and then overwrote S1's value from its stale read.

**Q3. How does `SELECT ... FOR UPDATE` fix it?** It takes the X lock at read time. S2 cannot even read until S1 commits, then it reads the fresh value (70) and computes 20.

**Q4. Why does `qty = qty - 30` not lose updates?** The read, subtraction and write happen inside one statement under one row lock; the second statement starts from the committed result of the first.

**Q5. Shared vs exclusive lock?** S: many readers, no writer; X: one holder, nobody else reads (locking reads) or writes. S-S compatible; S-X, X-X conflict.

**Q6. What does `LOCK TABLES t WRITE` do and why is it rarely used with InnoDB?** Locks the whole table for the session (others block even on SELECT); it kills concurrency. InnoDB row locks are preferred. `LOCK TABLES t READ` lets everybody read but nobody (including the owner) write.

**Q7. Why does S1 get error 1099 under `LOCK TABLES Stock READ`?** The session holds only a READ lock and MySQL refuses to let it modify the table.

**Q8. Which error appears after a long wait and which variable controls it?** ERROR 1205 Lock wait timeout exceeded; `innodb_lock_wait_timeout` (default 50 s).

**Q9. Is the Task 3 schedule conflict serializable?** No. R2(X) < W1(X) gives T2->T1 and R1(X) < W2(X) gives T1->T2: a cycle in the precedence graph.

**Q10. How does strict 2PL prevent the problem?** A transaction keeps all its locks until commit, so T2 cannot read/write X until T1 is finished - only serial-equivalent schedules arise.

**Q11 (follow-up). What is optimistic concurrency control?** No locks while working; each UPDATE checks a version/timestamp (ADV 2) and fails if somebody changed the row; the application retries.

**Q12 (follow-up). Does READ COMMITTED or REPEATABLE READ prevent this lost update?** No - the pattern read-then-write-from-stale-value is not an isolation-level anomaly in MySQL's non-locking reads; you need locking reads, atomic updates or SERIALIZABLE.

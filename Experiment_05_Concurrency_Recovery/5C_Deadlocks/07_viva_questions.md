# Viva questions - 5C Deadlock

**Q1. What is a deadlock? Give the four necessary conditions.** A set of transactions each waiting for a lock held by another in the set. Conditions: mutual exclusion, hold-and-wait, no preemption, circular wait.

**Q2. What error does MySQL return and what does it do?** ERROR 1213 (40001) Deadlock found; InnoDB rolls back the victim transaction (the one with the least work / fewest modified rows) and the other continues.

**Q3. Which transaction was the victim in your run and how do you see it?** The one that printed ERROR 1213; `SHOW ENGINE INNODB STATUS` -> LATEST DETECTED DEADLOCK ends with `*** WE ROLL BACK TRANSACTION (n)`.

**Q4. What is a wait-for graph?** Nodes = transactions, edge Ti -> Tj if Ti waits for a lock of Tj. A cycle means deadlock. Our graph: T1 -> T2 -> T1.

**Q5. Why did locking in the same order (account 1 then 2) give no deadlock?** Everybody queues on the first lock; a cycle needs two transactions that take the locks in opposite order.

**Q6. How does the retry procedure work?** `DECLARE EXIT HANDLER FOR 1213` rolls back and leaves the inner block; a loop repeats the transaction once, then SIGNALs 40001 if it fails again; `attempts_used = 2` showed the retry.

**Q7. Wait-die vs wound-wait?** Both use transaction timestamps. Wait-die: older may wait for younger, younger requesting an older's lock dies. Wound-wait: older requesting a younger's lock aborts (wounds) it, younger waits. Neither can create a cycle; aborted transactions restart with the same timestamp (no starvation).

**Q8. Difference between deadlock prevention, avoidance and detection?** Prevention: break a necessary condition (ordering, wait-die/wound-wait). Avoidance: grant only safe requests (banker's algorithm, rarely in DBs). Detection: allow, find the cycle, abort a victim (InnoDB).

**Q9. How did you create a three-session deadlock?** S1 holds 1 wants 2, S2 holds 2 wants 3, S3 holds 3 wants 1: T1 -> T2 -> T3 -> T1.

**Q10. How to reduce deadlocks?** Same lock order, short transactions, lock up front, good indexes, retry on 1213.

**Q11 (follow-up). Is a lock wait the same as a deadlock?** No. A wait ends when the holder commits (or with 1205 after the timeout); a deadlock can never resolve by waiting.

**Q12 (follow-up). Can deadlocks happen with a single row?** Yes, e.g. two transactions that both take a shared lock and then try to upgrade to exclusive (S->X upgrade deadlock, 5A ADV 1).

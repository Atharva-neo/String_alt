# Concurrency control and recovery notes (Experiment 5)

## Anomalies and isolation levels (measured in 5B on MySQL 8.0.46 / InnoDB)
| Level | Dirty read | Non-repeatable read | Phantom |
|---|---|---|---|
| READ UNCOMMITTED | occurs | occurs | occurs |
| READ COMMITTED | prevented | occurs | occurs |
| REPEATABLE READ (default) | prevented | prevented | prevented for plain reads (MVCC snapshot); visible in locking reads |
| SERIALIZABLE | prevented | prevented | prevented (reads take shared next-key locks, writers wait) |

Lost update (5A) is not an isolation-level anomaly of snapshot reads: fix it with `SELECT ... FOR UPDATE`, an atomic `UPDATE x = x - n`, optimistic version columns, or SERIALIZABLE.

## Locks
S (shared, `FOR SHARE`/`LOCK IN SHARE MODE`) vs X (exclusive, `FOR UPDATE`, UPDATE/DELETE). S-S compatible; S-X and X-X conflict. `LOCK TABLES t WRITE|READ` = table lock. Lock wait: error 1205 after `innodb_lock_wait_timeout`.

## 2PL and serializability
* **Two-phase locking**: growing phase (acquire) then shrinking (release); **strict 2PL** keeps X locks until commit - guarantees conflict serializability (and avoids cascading aborts).
* **Precedence graph**: edge Ti -> Tj for conflicting ops (same item, different txns, >= 1 write) with Ti first; acyclic <=> conflict serializable (`tools/schedule_tools.py`).

## Deadlock
Necessary: mutual exclusion, hold and wait, no preemption, circular wait. **Wait-for graph** cycle = deadlock. InnoDB detects it at once, rolls back the cheapest transaction (ERROR 1213) -> **retry the transaction**.
* Prevention: consistent lock order; **wait-die** (older waits, younger dies), **wound-wait** (older wounds younger, younger waits) with timestamps T1 < T2.
* Reduce: short transactions, lock up front in key order, good indexes, retry loop.

## Log-based recovery (5D)
Records `<T,start> <T,X,old,new> <T,commit> <checkpoint {active}>`. **Immediate update**: UNDO uncommitted (scan backwards, restore old), REDO committed-after-checkpoint (scan forwards, write new). **Deferred update**: only REDO; uncommitted work never reached the DB. Transactions committed before the last checkpoint need no action. Redo/undo must be idempotent.

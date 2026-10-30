# ACID notes (Experiment 4)

| Property | Meaning | Demonstrated in this repo |
|---|---|---|
| **A**tomicity | all statements of a transaction take effect or none | 4A Task 7 (failed transfer leaves balances and log unchanged), 4C Task 9 (ROLLBACK TO SAVEPOINT), 4D Task 11 (session killed before COMMIT -> nothing saved) |
| **C**onsistency | a transaction moves the DB from one valid state to another (constraints, triggers hold) | CHECK (balance >= 1000), triggers, `available + booked = capacity` invariant (4D Task 12), total money unchanged (4A ADV 4) |
| **I**solation | concurrent transactions do not see each other's uncommitted work | 4A Task 10 (S2 sees old balances, its UPDATE waits), 5B (anomaly matrix) |
| **D**urability | committed data survives crashes | 4A Task 11: commit, **forced kill** of mysqld, restart, committed data present and the uncommitted UPDATE gone (`DURABILITY.md`) |

## Mechanisms in InnoDB
* **Undo log** (rollback, MVCC snapshots), **redo log** (crash recovery, `innodb_flush_log_at_trx_commit=1` flushes at commit), **row locks** + gap locks, **doublewrite buffer**.
* `START TRANSACTION` / `COMMIT` / `ROLLBACK` / `SAVEPOINT`; `autocommit=1` makes every statement its own transaction; DDL commits implicitly.
* Triggers and stored procedures run inside the caller's transaction (a trigger cannot COMMIT).

## Procedure pattern
```sql
CREATE PROCEDURE transfer(IN a INT, IN b INT, IN amt DECIMAL(12,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT balance INTO v FROM acc WHERE id = a FOR UPDATE;        -- lock the source row
  IF v - amt < 1000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance'; END IF;
  UPDATE acc SET balance = balance - amt WHERE id = a;
  UPDATE acc SET balance = balance + amt WHERE id = b;
  COMMIT;
END
```
Oracle: `COMMIT`/`ROLLBACK`/`SAVEPOINT`, `RAISE_APPLICATION_ERROR`, redo/undo (rollback segments), default isolation READ COMMITTED.

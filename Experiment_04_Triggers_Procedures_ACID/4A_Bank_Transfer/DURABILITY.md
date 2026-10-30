# 4A Task 11 - Durability: commit, crash/restart, data still there

Durability = once `COMMIT` returned, the change survives a crash. InnoDB guarantees this with the **redo log** (`innodb_flush_log_at_trx_commit = 1` flushes it at every commit).

## How to run it yourself

```bash
python durability_demo.py prepare      # rebuilds bank_4a, commits a 2000 transfer, leaves a second UPDATE uncommitted, then waits
# --- in another terminal: restart (or better: kill) the MySQL server ---
#   Windows (admin):  net stop MySQL80  &&  net start MySQL80
#   Linux:            sudo systemctl restart mysql        (harsher: sudo kill -9 $(pidof mysqld))
python durability_demo.py check        # reconnects and prints the balances
```

## Real captured run (scratch MySQL 8.0.46 server, killed with a forced process stop = crash, then restarted)

```text
=== PHASE 1: prepare ===
> SELECT * FROM Account
| 1001 | Rahul | 50000.00 |   | 1002 | Pooja | 20000.00 |   | 1003 | Kiran | 5000.00 |
> START TRANSACTION
> UPDATE Account SET balance = balance - 2000 WHERE acc_no = 1002        -> 1 row affected
> UPDATE Account SET balance = balance + 2000 WHERE acc_no = 1003        -> 1 row affected
> COMMIT                                                                  <-- durability point
> SELECT * FROM Account
| 1001 | Rahul | 50000.00 |   | 1002 | Pooja | 18000.00 |   | 1003 | Kiran | 7000.00 |
> START TRANSACTION
> UPDATE Account SET balance = balance - 9999 WHERE acc_no = 1001        (NOT committed)
> SELECT * FROM Account WHERE acc_no = 1001
| 1001 | Rahul | 40001.00 |

=== SERVER KILLED (forced process stop, no clean shutdown) ===
=== SERVER RESTARTED (InnoDB crash recovery runs) ===

=== PHASE 2: check ===
> SELECT * FROM Account
+--------+--------+----------+
| acc_no | holder | balance  |
+--------+--------+----------+
|   1001 | Rahul  | 50000.00 |      <- uncommitted -9999 is gone (atomicity: rolled back by crash recovery)
|   1002 | Pooja  | 18000.00 |      <- committed transfer survived (durability)
|   1003 | Kiran  |  7000.00 |      <- committed transfer survived (durability)
+--------+--------+----------+
```

The table above was produced by `durability_demo.py` (the two phase listings are reformatted to one line per row for brevity; the server answers are unchanged).

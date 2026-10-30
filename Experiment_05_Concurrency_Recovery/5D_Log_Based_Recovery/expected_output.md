# Expected output - 5D Log-based recovery

> **ACTUAL OUTPUT** of `python main.py` (Python 3.14.7, MySQL 8.0.46 for Task 12) captured on 2026-10-30. Task 12 needs a running MySQL server; without one the program prints *'MySQL part SKIPPED'* instead of faking a result.

```text
### Task 1 - the log is stored in a text file

File: data\log.txt
# Log of Experiment 5D (initial values: A = 1000, B = 2000, C = 700, D = 500)
# The PDF lists "<checkpoint {T2}> after <T2, start>": T2 started just before the checkpoint, so <T2, start> is written first.
<T1, start>
<T1, A, 1000, 950>
<T1, B, 2000, 2050>
<T1, commit>
<T2, start>
<checkpoint {T2}>
<T2, C, 700, 600>
<T3, start>
<T3, D, 500, 800>
<T3, commit>
<T2, A, 950, 900>
# --- system crash ---
Initial database: {'A': 1000, 'B': 2000, 'C': 700, 'D': 500}

### Task 2 - parse every log record

  #1  <T1, start>            => START    txn=T1
  #2  <T1, A, 1000, 950>     => UPDATE   txn=T1 item=A old=1000 new=950
  #3  <T1, B, 2000, 2050>    => UPDATE   txn=T1 item=B old=2000 new=2050
  #4  <T1, commit>           => COMMIT   txn=T1
  #5  <T2, start>            => START    txn=T2
  #6  <checkpoint {T2}>      => CHECKPOINT active=['T2']
  #7  <T2, C, 700, 600>      => UPDATE   txn=T2 item=C old=700 new=600
  #8  <T3, start>            => START    txn=T3
  #9  <T3, D, 500, 800>      => UPDATE   txn=T3 item=D old=500 new=800
  #10 <T3, commit>           => COMMIT   txn=T3
  #11 <T2, A, 950, 900>      => UPDATE   txn=T2 item=A old=950 new=900

### Task 3 - committed and uncommitted transactions

  started     : ['T1', 'T2', 'T3']
  COMMITTED   : ['T1', 'T3']
  UNCOMMITTED : ['T2']  (started, no commit record before the crash)

### Task 4 - last checkpoint and active transactions

  last checkpoint is record #6: <checkpoint {T2}>
  transactions active at the checkpoint: ['T2']

### Task 5 - UNDO and REDO lists

  UNDO list (uncommitted)                 : ['T2']
  REDO list (committed after the checkpoint): ['T3']
  no action (committed before checkpoint)   : ['T1']

### Task 6/7/8 - immediate update: undo T2 backwards, redo T3 forwards, final values

--- IMMEDIATE UPDATE (log: log.txt) ---
Database at crash time (all writes already on disk): A=900, B=2050, C=600, D=800
UNDO phase - scan the log BACKWARDS and restore old values of ['T2']:
  <T2, A, 950, 900>        -> A restored to 950 (was 900)
  <T2, C, 700, 600>        -> C restored to 700 (was 600)
REDO phase - scan the log FORWARDS and re-apply new values of ['T3']:
  <T3, D, 500, 800>        -> D set to 800 (was 800)
Database AFTER recovery: A=950, B=2050, C=700, D=800
(Task 6 = UNDO phase above, Task 7 = REDO phase above, Task 8 = the 'AFTER recovery' line)

### Task 9 - why T1 needs no action

  T1 committed BEFORE the last checkpoint. At a checkpoint all committed changes are forced to disk and the log is flushed, so T1's values
  (A=950, B=2050) are already in the database: no REDO. T1 is committed, so no UNDO either.

### Task 10 - deferred update

--- DEFERRED UPDATE (log: log.txt) ---
Database at crash time (only pre-checkpoint commits on disk): A=950, B=2050, C=700, D=500
REDO the committed transactions ['T3'] (forward scan, new values only):
  <T3, D, 500, 800>        -> D set to 800 (was 500)
IGNORE the uncommitted transactions ['T2'] - they never touched the database, so there is nothing to UNDO.
Database AFTER recovery: A=950, B=2050, C=700, D=800
  Redone: ['T3']   Ignored: ['T2']   Final values: {'A': 950, 'B': 2050, 'C': 700, 'D': 800}

### Task 11 - add <T2, commit> before the crash and rerun

  now: committed=['T1', 'T2', 'T3']  uncommitted=[]  UNDO=[]  REDO=['T2', 'T3']
--- IMMEDIATE UPDATE (log: log_t2_commit.txt) ---
Database at crash time (all writes already on disk): A=900, B=2050, C=600, D=800
UNDO phase - scan the log BACKWARDS and restore old values of nobody:
REDO phase - scan the log FORWARDS and re-apply new values of ['T2', 'T3']:
  <T2, C, 700, 600>        -> C set to 600 (was 600)
  <T3, D, 500, 800>        -> D set to 800 (was 800)
  <T2, A, 950, 900>        -> A set to 900 (was 900)
Database AFTER recovery: A=900, B=2050, C=600, D=800
--- DEFERRED UPDATE (log: log_t2_commit.txt) ---
Database at crash time (only pre-checkpoint commits on disk): A=950, B=2050, C=700, D=500
REDO the committed transactions ['T2', 'T3'] (forward scan, new values only):
  <T2, C, 700, 600>        -> C set to 600 (was 700)
  <T3, D, 500, 800>        -> D set to 800 (was 500)
  <T2, A, 950, 900>        -> A set to 900 (was 950)
IGNORE the uncommitted transactions none - they never touched the database, so there is nothing to UNDO.
Database AFTER recovery: A=900, B=2050, C=600, D=800

  Comparison of final values
  scenario                         A     B     C     D
  original log, immediate       950  2050   700   800
  original log, deferred        950  2050   700   800
  with <T2,commit>, immediate   900  2050   600   800
  with <T2,commit>, deferred    900  2050   600   800
  => Without <T2, commit> T2 is rolled back (A back to 950, C back to 700); with it T2 is redone (A=900, C=600). T3 and T1 are identical in both runs.

### Task 12 - store the database values in MySQL and apply the recovered values

db_values after the crash (before recovery):
  item | value
  A    | 900
  B    | 2050
  C    | 600
  D    | 800
  UPDATE db_values SET value = 950 WHERE item = 'A'
  UPDATE db_values SET value = 700 WHERE item = 'C'
  UPDATE db_values SET value = 800 WHERE item = 'D'
db_values after applying the recovered values:
  item | value
  A    | 950
  B    | 2050
  C    | 700
  D    | 800
```


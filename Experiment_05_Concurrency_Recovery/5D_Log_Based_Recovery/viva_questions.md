# Viva questions - 5D Log-based recovery

**Q1. What is write-ahead logging?** Log records describing a change must reach stable storage before the changed data page does (and the commit record before the commit is acknowledged). It is what makes UNDO/REDO possible.

**Q2. Immediate vs deferred update?** Immediate: database updated during the transaction (needs UNDO and REDO). Deferred: updates applied only at commit (needs only REDO; uncommitted work never touched the database).

**Q3. Why does T1 need no action?** It committed before the last checkpoint, so its changes were forced to disk at the checkpoint.

**Q4. Which transactions go to the UNDO list and the REDO list?** UNDO: started but not committed (T2). REDO: committed after the last checkpoint (T3).

**Q5. Why scan backwards for UNDO and forwards for REDO?** UNDO must leave the oldest "old value"; REDO must leave the newest "new value".

**Q6. What are the values after recovery?** A=950, B=2050, C=700, D=800.

**Q7. What changes when `<T2, commit>` is in the log?** T2 becomes committed after the checkpoint, so it is REDONE: A=900, C=600 (no UNDO list).

**Q8. What does a checkpoint save?** Recovery need not scan the whole log: only transactions active at the checkpoint and later ones matter.

**Q9. Is UNDO needed in deferred update? Why?** No - uncommitted transactions have not modified the database.

**Q10. Why must redo/undo be idempotent?** Recovery can crash and restart; repeating an operation must not change the result (writing absolute values - not "add 50" - guarantees it).

**Q11 (follow-up). What does ARIES add?** Page LSNs, analysis pass, compensation log records, fuzzy checkpoints, redo of *all* history then undo.

**Q12 (follow-up). Where does MySQL keep these logs?** InnoDB redo log (durability) and undo log (rollback / MVCC); the binary log is for replication and point-in-time recovery.

#!/usr/bin/env python3
"""5A - Lost update on stock. Replays Tasks 1-12 with two real MySQL connections and prints the transcript."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from sessions import main_demo
from schedule_tools import analyse

HERE = Path(__file__).parent
RESET = ("admin", "UPDATE Stock SET qty = 100 WHERE item_id = 1")
SHOW = ("admin", "SELECT item_id, qty FROM Stock WHERE item_id = 1")


def steps():
    return [
        ("task", "1", "Stock is an InnoDB table; autocommit is switched off in both sessions"),
        ("admin", "SELECT table_name, engine FROM information_schema.tables WHERE table_schema = 'stock_5a'"),
        ("admin", "SELECT * FROM Stock"),
        ("S1", "SET autocommit = 0"), ("S2", "SET autocommit = 0"),
        ("S1", "SELECT @@autocommit AS autocommit"),
        ("task", "2", "Isolation level of both sessions"),
        ("S1", "SELECT @@transaction_isolation AS isolation"), ("S2", "SELECT @@transaction_isolation AS isolation"),

        ("task", "3", "READ UNCOMMITTED in both sessions: the lost update"),
        ("S1", "SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED"), ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED"),
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),
        ("S1", "SELECT qty FROM Stock WHERE item_id = 1"),
        ("S2", "SELECT qty FROM Stock WHERE item_id = 1"),
        ("note", "both sessions now hold the value 100 in their head"),
        ("S1", "UPDATE Stock SET qty = 70 WHERE item_id = 1"),
        ("note", "S2 computes 100 - 50 = 50 from its stale read; the row is X-locked by S1, so S2 waits"),
        ("S2", "UPDATE Stock SET qty = 50 WHERE item_id = 1", "async"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "COMMIT"),
        SHOW,
        ("note", "FINAL qty = 50, but 100 - 30 - 50 = 20 was expected: S1's update of -30 was overwritten = LOST UPDATE"),

        ("task", "4", "Schedule (time-line table) of the transactions of Task 3", "keep"),
        ("timeline",),
        ("note", "Operation sequence: R1(X) R2(X) W1(X) C1 W2(X) C2"),

        ("task", "5", "Reset to 100, repeat with SELECT ... FOR UPDATE (exclusive lock on the read)"),
        RESET,
        ("S1", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"), ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),
        ("S1", "SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE"),
        ("S2", "SELECT qty FROM Stock WHERE item_id = 1 FOR UPDATE", "async"),
        ("S1", "UPDATE Stock SET qty = 70 WHERE item_id = 1"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("note", "S2 now reads the COMMITTED 70 (not the stale 100) and computes 70 - 50 = 20"),
        ("S2", "UPDATE Stock SET qty = 20 WHERE item_id = 1"),
        ("S2", "COMMIT"),
        SHOW,
        ("note", "FINAL qty = 20: no update was lost"),

        ("task", "6", "Reset, relative updates: UPDATE Stock SET qty = qty - 30 / qty - 50"),
        RESET,
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),
        ("S1", "UPDATE Stock SET qty = qty - 30 WHERE item_id = 1"),
        ("S2", "UPDATE Stock SET qty = qty - 50 WHERE item_id = 1", "async"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "COMMIT"),
        SHOW,
        ("note", "FINAL qty = 20 again - and with a single statement per transaction; no explicit locking code is needed"),

        ("task", "7", "Shared lock: S1 holds LOCK IN SHARE MODE, S2 may read but not write"),
        RESET,
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),
        ("S1", "SELECT qty FROM Stock WHERE item_id = 1 LOCK IN SHARE MODE"),
        ("S2", "SELECT qty FROM Stock WHERE item_id = 1"),
        ("S2", "UPDATE Stock SET qty = qty - 1 WHERE item_id = 1", "async"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "ROLLBACK"),

        ("task", "8", "LOCK TABLES Stock WRITE in S1: S2 is blocked until UNLOCK TABLES"),
        RESET,
        ("S1", "LOCK TABLES Stock WRITE"),
        ("S1", "UPDATE Stock SET qty = qty - 30 WHERE item_id = 1"),
        ("S2", "SELECT qty FROM Stock WHERE item_id = 1", "async"),
        ("S1", "COMMIT"),
        ("S1", "UNLOCK TABLES"),
        ("S2", "@join"),
        ("S2", "COMMIT"),

        ("task", "9", "LOCK TABLES Stock READ: even the locking session cannot update"),
        RESET,
        ("S1", "LOCK TABLES Stock READ"),
        ("S1", "SELECT qty FROM Stock WHERE item_id = 1"),
        ("S1", "UPDATE Stock SET qty = qty - 1 WHERE item_id = 1"),
        ("S2", "SELECT qty FROM Stock WHERE item_id = 1"),
        ("S2", "UPDATE Stock SET qty = qty - 1 WHERE item_id = 1", "async"),
        ("S1", "UNLOCK TABLES"),
        ("S2", "@join"),
        ("S2", "ROLLBACK"),

        ("task", "10", "Lock-wait timeout: S1 stays open, S2 gives up"),
        RESET,
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Stock SET qty = qty - 1 WHERE item_id = 1"),
        ("S2", "SET SESSION innodb_lock_wait_timeout = 2"),
        ("S2", "SELECT @@innodb_lock_wait_timeout AS timeout_seconds"),
        ("S2", "START TRANSACTION"),
        ("note", "S2 waits 2 seconds for S1's lock, then fails (default timeout is 50 s):"),
        ("S2", "UPDATE Stock SET qty = qty - 2 WHERE item_id = 1"),
        ("S1", "ROLLBACK"),
        ("S2", "ROLLBACK"),

        ("task", "11", "Conflict serializability of the schedule of Task 3 (precedence graph)"),
        ("py", lambda: analyse("Task 3 (READ UNCOMMITTED, lost update)",
                               [("T1", "R", "X"), ("T2", "R", "X"), ("T1", "W", "X"), ("T2", "W", "X")])),
        ("py", lambda: analyse("Task 5 (SELECT ... FOR UPDATE, T2 reads after T1 committed)",
                               [("T1", "R", "X"), ("T1", "W", "X"), ("T2", "R", "X"), ("T2", "W", "X")])),
        ("task", "12", "Why two-phase locking prevents the lost update"),
        ("note", "T1: lock-X(X) [growing] ... R1 W1 ... COMMIT -> release all locks [shrinking, strict 2PL]"),
        ("note", "T2: lock-X(X) must WAIT until T1 releases it, so R2 can only happen after W1/C1 -> schedule R1 W1 C1 R2 W2 = serial order T1, T2."),
        ("note", "The interleaving R1 R2 W1 W2 of Task 3 needs both transactions to read X without the exclusive lock, which 2PL forbids."),
    ]


main_demo(__file__, "stock_5a", [HERE / "01_schema.sql", HERE / "02_sample_data.sql"], steps, "5A Lost update")

#!/usr/bin/env python3
"""5C - Deadlock. Creates real deadlocks with two and three sessions, shows the InnoDB report, the retry procedure and wait-die / wound-wait."""
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import mysql.connector
from sessions import main_demo, CFG
from schedule_tools import wait_for_graph

HERE = Path(__file__).parent
RESET = ("quiet", "UPDATE Account SET balance = 10000 WHERE acc_no IN (1, 2, 3)")

RETRY_PROC = """CREATE PROCEDURE transfer_retry(IN f INT, IN t INT, IN amt DECIMAL(12,2), OUT attempts_used INT)
BEGIN
    DECLARE ok INT DEFAULT 0;
    SET attempts_used = 0;
    retry_loop: LOOP
        SET attempts_used = attempts_used + 1;
        BEGIN
            DECLARE EXIT HANDLER FOR 1213 BEGIN ROLLBACK; END;      -- 1213 = ER_LOCK_DEADLOCK: undo and fall out of this block
            START TRANSACTION;
            UPDATE Account SET balance = balance - amt WHERE acc_no = f;
            UPDATE Account SET balance = balance + amt WHERE acc_no = t;
            COMMIT;
            SET ok = 1;
        END;
        IF ok = 1 THEN
            LEAVE retry_loop;
        END IF;
        IF attempts_used >= 2 THEN                                   -- first try + ONE retry only
            SIGNAL SQLSTATE '40001' SET MESSAGE_TEXT = 'Transfer failed: deadlock persisted after one retry';
        END IF;
    END LOOP;
END"""


def innodb_deadlock_report():
    c = mysql.connector.connect(**CFG, autocommit=True)
    cur = c.cursor(); cur.execute("SHOW ENGINE INNODB STATUS")
    status = cur.fetchone()[2]; cur.close(); c.close()
    m = re.search(r"LATEST DETECTED DEADLOCK\n-+\n(.*?)\n-{6,}\n(?:TRANSACTIONS|LATEST FOREIGN KEY ERROR)", status, re.S)
    if not m:
        return "(no deadlock section found)"
    text = m.group(1).strip()
    victim = re.search(r"\*\*\* WE ROLL BACK TRANSACTION \((\d+)\)", text)
    lines = text.splitlines()
    keep = [l for l in lines if not l.strip().startswith(("Record lock, heap", "0: len", "1: len", "2: len", "3: len", " 0:", " 1:", " 2:", " 3:"))]
    return ("\n".join(keep) + "\n\n=> Victim: " + (f"transaction ({victim.group(1)}) was rolled back (see '*** WE ROLL BACK TRANSACTION' above)" if victim else "not found"))


def timestamp_schemes():
    out = ["Example: T1 (timestamp 1, older) and T2 (timestamp 2, younger). T1 holds lock on A, T2 holds lock on B.",
           "Event 1: T1 requests B (held by T2).   Event 2: T2 requests A (held by T1).", ""]
    for name, older_req, younger_req in (
            ("WAIT-DIE   (non-preemptive: older waits, younger dies)", "T1 is older -> T1 WAITS for T2", "T2 is younger -> T2 DIES (aborts, restarts later with its ORIGINAL timestamp)"),
            ("WOUND-WAIT (preemptive: older wounds the younger holder, younger waits)", "T1 is older -> T1 WOUNDS T2 (T2 is aborted and rolled back, T1 takes B)", "T2 restarts with its ORIGINAL timestamp and now WAITS for T1")):
        out += [name, f"  Event 1: {older_req}", f"  Event 2: {younger_req}",
                "  Result: no cycle can ever form, because waiting is only allowed in one age direction.", ""]
    out.append("Compare with InnoDB: it does not prevent deadlocks; it detects the cycle and aborts the cheapest transaction (victim).")
    return "\n".join(out)


FOUR_WAYS = """Four ways to reduce deadlocks in an application:
 1. Lock rows in a consistent global order (e.g. always the lower account number first) - Task 8 shows no deadlock then.
 2. Keep transactions short and never wait for user input inside a transaction; commit as early as possible.
 3. Acquire all needed locks up front: SELECT ... WHERE acc_no IN (1,2) ORDER BY acc_no FOR UPDATE, then update.
 4. Use proper indexes so that statements lock only the rows they need (fewer gap/next-key locks), and prefer READ COMMITTED when gap locks are not needed.
 5. (bonus) Catch error 1213 and retry the whole transaction (Task 9)."""


def steps():
    return [
        ("task", "1", "Create Account, insert the data, open two sessions"),
        ("admin", "SELECT * FROM Account"),
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),

        ("task", "2", "S1 debits account 1"),
        ("S1", "UPDATE Account SET balance = balance - 500 WHERE acc_no = 1"),
        ("task", "3", "S2 debits account 2"),
        ("S2", "UPDATE Account SET balance = balance - 300 WHERE acc_no = 2"),

        ("task", "4", "S1 wants account 2, S2 wants account 1: capture the deadlock error"),
        ("note", "S1 now waits for the lock S2 holds on row 2 ..."),
        ("S1", "UPDATE Account SET balance = balance + 500 WHERE acc_no = 2", "async"),
        ("note", "... and S2 requests the lock S1 holds on row 1 => cycle: InnoDB detects it at once."),
        ("S2", "UPDATE Account SET balance = balance + 300 WHERE acc_no = 1"),
        ("S1", "@join"),

        ("task", "5", "Who was rolled back, who commits, final balances"),
        ("note", "The session that printed ERROR 1213 was the victim: its whole transaction (also the earlier UPDATE) is already rolled back. The survivor commits:"),
        ("S1", "COMMIT"),
        ("S2", "COMMIT"),
        ("admin", "SELECT * FROM Account"),
        ("note", "Only the survivor's two updates are visible (see its row changes above); the victim's changes are gone."),

        ("task", "6", "SHOW ENGINE INNODB STATUS - LATEST DETECTED DEADLOCK"),
        ("py", innodb_deadlock_report),

        ("task", "7", "Wait-for graph"),
        ("py", lambda: wait_for_graph([("T1", "T2"), ("T2", "T1")])),

        ("task", "8", "Same lock order in both sessions (account 1 then 2): no deadlock"),
        RESET,
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"),
        ("S1", "UPDATE Account SET balance = balance - 500 WHERE acc_no = 1"),
        ("S2", "UPDATE Account SET balance = balance - 300 WHERE acc_no = 1", "async"),
        ("S1", "UPDATE Account SET balance = balance + 500 WHERE acc_no = 2"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "UPDATE Account SET balance = balance + 300 WHERE acc_no = 2"),
        ("S2", "COMMIT"),
        ("admin", "SELECT * FROM Account"),
        ("note", "Both transfers completed: 1 = 10000-500-300, 2 = 10000+500+300. S2 simply waited."),

        ("task", "9", "Procedure transfer_retry: retry once when error 1213 occurs"),
        RESET,
        ("admin", RETRY_PROC),
        ("note", "S1 does heavier work (two updates) so InnoDB picks the lighter transaction - S2, running the procedure - as the victim."),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Account SET balance = balance - 100 WHERE acc_no = 2"),
        ("S1", "UPDATE Account SET balance = balance - 100 WHERE acc_no = 2"),
        ("S2", "CALL transfer_retry(1, 2, 100, @attempts)", "async"),
        ("note", "The procedure holds row 1 and waits for row 2. S1 now asks for row 1 => deadlock, the procedure's transaction is the victim and retries:"),
        ("S1", "UPDATE Account SET balance = balance + 200 WHERE acc_no = 1"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "SELECT @attempts AS attempts_used"),
        ("admin", "SELECT * FROM Account"),
        ("note", "attempts_used = 2: first try deadlocked and was rolled back, the retry succeeded. 1 = 10000+200-100, 2 = 10000-200+100."),

        ("task", "10", "Deadlock with three accounts and three sessions"),
        ("quiet", "INSERT INTO Account VALUES (3, 10000) ON DUPLICATE KEY UPDATE balance = 10000"),
        RESET,
        ("S1", "START TRANSACTION"), ("S2", "START TRANSACTION"), ("S3", "START TRANSACTION"),
        ("S1", "UPDATE Account SET balance = balance - 1 WHERE acc_no = 1"),
        ("S1", "UPDATE Account SET balance = balance - 1 WHERE acc_no = 1"),
        ("S2", "UPDATE Account SET balance = balance - 1 WHERE acc_no = 2"),
        ("S2", "UPDATE Account SET balance = balance - 1 WHERE acc_no = 2"),
        ("S3", "UPDATE Account SET balance = balance - 1 WHERE acc_no = 3"),
        ("S1", "UPDATE Account SET balance = balance + 1 WHERE acc_no = 2", "async"),
        ("S2", "UPDATE Account SET balance = balance + 1 WHERE acc_no = 3", "async"),
        ("note", "S3 closes the cycle T1 -> T2 -> T3 -> T1 (S3 has done the least work and becomes the victim):"),
        ("S3", "UPDATE Account SET balance = balance + 1 WHERE acc_no = 1"),
        ("S3", "COMMIT"),
        ("S2", "@join"),
        ("S2", "COMMIT"),
        ("S1", "@join"),
        ("S1", "COMMIT"),
        ("py", lambda: wait_for_graph([("T1", "T2"), ("T2", "T3"), ("T3", "T1")])),

        ("task", "11", "Wait-die and wound-wait with timestamps T1 < T2"),
        ("py", timestamp_schemes),
        ("task", "12", "Four ways to reduce deadlocks"),
        ("py", lambda: FOUR_WAYS),
    ]


main_demo(__file__, "deadlock_5c", [HERE / "01_schema.sql", HERE / "02_sample_data.sql"], steps, "5C Deadlock")

#!/usr/bin/env python3
"""
5D - Log-based recovery (immediate and deferred update, UNDO / REDO).

Reads a write-ahead log from a text file, analyses it and recovers the database after a crash.

  python main.py                       run Tasks 1-12 on data/log.txt (+ data/log_t2_commit.txt for Task 11)
  python main.py --log data/log.txt --mode immediate     only one scenario on a log of your choice
  python main.py --no-mysql            skip Task 12 (needs a running MySQL server, see .env.example)

Log record formats understood (one per line, '#' starts a comment):
  <T1, start>   <T1, commit>   <T1, abort>   <T1, A, 1000, 950>  (txn, item, old value, new value)   <checkpoint {T2, T4}>
"""
import argparse
import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
INITIAL = {"A": 1000, "B": 2000, "C": 700, "D": 500}      # database before the log starts (from the PDF)
REC = re.compile(r"^<\s*(.*?)\s*>\s*$")


# --------------------------------------------------------------------------- parsing
def parse_log(path):
    records = []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = REC.match(line)
        if not m:
            raise ValueError(f"cannot parse log line: {line!r}")
        body = m.group(1)
        if body.lower().startswith("checkpoint"):
            records.append({"type": "checkpoint", "active": re.findall(r"T\d+", body), "text": line})
            continue
        parts = [p.strip() for p in body.split(",")]
        if len(parts) == 2 and parts[1].lower() in ("start", "commit", "abort"):
            records.append({"type": parts[1].lower(), "txn": parts[0], "text": line})
        elif len(parts) == 4:
            records.append({"type": "update", "txn": parts[0], "item": parts[1],
                            "old": int(parts[2]), "new": int(parts[3]), "text": line})
        else:
            raise ValueError(f"unknown log record: {line!r}")
    for i, r in enumerate(records, 1):
        r["no"] = i
    return records


def analyse(records):
    """Committed / uncommitted transactions, last checkpoint, UNDO and REDO lists."""
    started = list(dict.fromkeys(r["txn"] for r in records if r["type"] == "start"))
    commit_at = {r["txn"]: i for i, r in enumerate(records) if r["type"] == "commit"}
    aborted = {r["txn"] for r in records if r["type"] == "abort"}
    cp = max((i for i, r in enumerate(records) if r["type"] == "checkpoint"), default=None)
    active_at_cp = records[cp]["active"] if cp is not None else []
    committed = [t for t in started if t in commit_at]
    uncommitted = [t for t in started if t not in commit_at and t not in aborted]
    # REDO: committed AFTER the last checkpoint (their pages may not have reached disk). Committed before it: already safe.
    redo = [t for t in committed if cp is None or commit_at[t] > cp]
    safe = [t for t in committed if t not in redo]
    return dict(started=started, committed=committed, uncommitted=uncommitted, checkpoint_index=cp,
                active_at_cp=active_at_cp, undo=uncommitted, redo=redo, safe=safe)


def show_db(db, label):
    return f"{label}: " + ", ".join(f"{k}={v}" for k, v in sorted(db.items()))


# --------------------------------------------------------------------------- recovery algorithms
def crash_state_immediate(records):
    """Immediate update: every write may already be in the database when the crash happens (worst case: all of them)."""
    db = dict(INITIAL)
    for r in records:
        if r["type"] == "update":
            db[r["item"]] = r["new"]
    return db


def recover_immediate(records, info, db, say):
    ops = []
    say(f"UNDO phase - scan the log BACKWARDS and restore old values of {info['undo'] or 'nobody'}:")
    for r in reversed(records):
        if r["type"] == "update" and r["txn"] in info["undo"]:
            say(f"  {r['text']:<24} -> {r['item']} restored to {r['old']} (was {db[r['item']]})")
            db[r["item"]] = r["old"]
            ops.append((r["item"], r["old"]))
    say(f"REDO phase - scan the log FORWARDS and re-apply new values of {info['redo'] or 'nobody'}:")
    for r in records:
        if r["type"] == "update" and r["txn"] in info["redo"]:
            say(f"  {r['text']:<24} -> {r['item']} set to {r['new']} (was {db[r['item']]})")
            db[r["item"]] = r["new"]
            ops.append((r["item"], r["new"]))
    return db, ops


def crash_state_deferred(records, info):
    """Deferred update: writes reach the database only at commit. At crash time only transactions that committed
    BEFORE the checkpoint are certainly on disk; everything else is lost from the database (but is in the log)."""
    db = dict(INITIAL)
    for r in records:
        if r["type"] == "update" and r["txn"] in info["safe"]:
            db[r["item"]] = r["new"]
    return db


def recover_deferred(records, info, db, say):
    ops = []
    say(f"REDO the committed transactions {info['redo'] or 'none'} (forward scan, new values only):")
    for r in records:
        if r["type"] == "update" and r["txn"] in info["redo"]:
            say(f"  {r['text']:<24} -> {r['item']} set to {r['new']} (was {db[r['item']]})")
            db[r["item"]] = r["new"]
            ops.append((r["item"], r["new"]))
    say(f"IGNORE the uncommitted transactions {info['uncommitted'] or 'none'} - they never touched the database, so there is nothing to UNDO.")
    return db, ops


# --------------------------------------------------------------------------- MySQL (Task 12)
def mysql_task(crash_db, ops, say):
    try:
        import mysql.connector
        cfg = dict(host=os.environ.get("MYSQL_HOST", "127.0.0.1"), port=int(os.environ.get("MYSQL_PORT", "3306")),
                   user=os.environ.get("MYSQL_USER", "root"), password=os.environ.get("MYSQL_PWD", ""))
        conn = mysql.connector.connect(**cfg)
    except Exception as e:          # driver missing or server not reachable: say so, do not fake anything
        say(f"MySQL part SKIPPED - cannot connect ({e}). Install mysql-connector-python, start MySQL and set MYSQL_* variables.")
        return
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS recovery_5d")
    cur.execute("USE recovery_5d")
    cur.execute("DROP TABLE IF EXISTS db_values")
    cur.execute("CREATE TABLE db_values (item VARCHAR(5) NOT NULL PRIMARY KEY, value INT NOT NULL) ENGINE=InnoDB")
    cur.executemany("INSERT INTO db_values (item, value) VALUES (%s, %s)", sorted(crash_db.items()))
    conn.commit()

    def dump(title):
        cur.execute("SELECT item, value FROM db_values ORDER BY item")
        say(title + "\n  item | value\n" + "\n".join(f"  {i:<4} | {v}" for i, v in cur.fetchall()))
    dump("db_values after the crash (before recovery):")
    conn.commit()                                                # end the implicit read transaction of dump()
    conn.start_transaction()                                     # the whole recovery is one atomic transaction
    for item, value in ops:
        cur.execute("UPDATE db_values SET value = %s WHERE item = %s", (value, item))     # parameterised
        say(f"  UPDATE db_values SET value = {value} WHERE item = '{item}'")
    conn.commit()
    dump("db_values after applying the recovered values:")
    cur.close(); conn.close()


# --------------------------------------------------------------------------- driver
def run_scenario(title, path, mode, say):
    records = parse_log(path)
    info = analyse(records)
    say(f"--- {title} (log: {Path(path).name}) ---")
    if mode == "immediate":
        db = crash_state_immediate(records)
        say(show_db(db, "Database at crash time (all writes already on disk)"))
        db, ops = recover_immediate(records, info, db, say)
    else:
        db = crash_state_deferred(records, info)
        say(show_db(db, "Database at crash time (only pre-checkpoint commits on disk)"))
        db, ops = recover_deferred(records, info, db, say)
    say(show_db(db, "Database AFTER recovery"))
    return db, ops


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--log")
    ap.add_argument("--mode", choices=["immediate", "deferred"])
    ap.add_argument("--no-mysql", action="store_true")
    a = ap.parse_args()
    say = print
    if a.log and a.mode:
        run_scenario("single run", a.log, a.mode, say)
        return

    log = HERE / "data" / "log.txt"
    say("### Task 1 - the log is stored in a text file\n")
    say(f"File: {log.relative_to(HERE)}\n" + log.read_text(encoding="utf-8").rstrip())
    say(f"Initial database: {INITIAL}")

    records = parse_log(log)
    say("\n### Task 2 - parse every log record\n")
    for r in records:
        if r["type"] == "update":
            detail = f"UPDATE   txn={r['txn']} item={r['item']} old={r['old']} new={r['new']}"
        elif r["type"] == "checkpoint":
            detail = f"CHECKPOINT active={r['active']}"
        else:
            detail = f"{r['type'].upper():<8} txn={r['txn']}"
        say(f"  #{r['no']:<2} {r['text']:<22} => {detail}")
    info = analyse(records)

    say("\n### Task 3 - committed and uncommitted transactions\n")
    say(f"  started     : {info['started']}\n  COMMITTED   : {info['committed']}\n  UNCOMMITTED : {info['uncommitted']}  (started, no commit record before the crash)")

    say("\n### Task 4 - last checkpoint and active transactions\n")
    cp = info["checkpoint_index"]
    say(f"  last checkpoint is record #{records[cp]['no']}: {records[cp]['text']}\n  transactions active at the checkpoint: {info['active_at_cp']}")

    say("\n### Task 5 - UNDO and REDO lists\n")
    say(f"  UNDO list (uncommitted)                 : {info['undo']}\n  REDO list (committed after the checkpoint): {info['redo']}\n"
        f"  no action (committed before checkpoint)   : {info['safe']}")

    say("\n### Task 6/7/8 - immediate update: undo T2 backwards, redo T3 forwards, final values\n")
    db_imm, ops_imm = run_scenario("IMMEDIATE UPDATE", log, "immediate", say)
    say("(Task 6 = UNDO phase above, Task 7 = REDO phase above, Task 8 = the 'AFTER recovery' line)")
    crash_imm = crash_state_immediate(records)

    say("\n### Task 9 - why T1 needs no action\n")
    say("  T1 committed BEFORE the last checkpoint. At a checkpoint all committed changes are forced to disk and the log is flushed, so T1's values\n"
        "  (A=950, B=2050) are already in the database: no REDO. T1 is committed, so no UNDO either.")

    say("\n### Task 10 - deferred update\n")
    db_def, ops_def = run_scenario("DEFERRED UPDATE", log, "deferred", say)
    say(f"  Redone: {info['redo']}   Ignored: {info['uncommitted']}   Final values: {db_def}")

    say("\n### Task 11 - add <T2, commit> before the crash and rerun\n")
    log2 = HERE / "data" / "log_t2_commit.txt"
    i2 = analyse(parse_log(log2))
    say(f"  now: committed={i2['committed']}  uncommitted={i2['uncommitted']}  UNDO={i2['undo']}  REDO={i2['redo']}")
    db2_imm, _ = run_scenario("IMMEDIATE UPDATE", log2, "immediate", say)
    db2_def, _ = run_scenario("DEFERRED UPDATE", log2, "deferred", say)
    say("\n  Comparison of final values")
    say("  scenario                         A     B     C     D")
    for name, d in (("original log, immediate  ", db_imm), ("original log, deferred   ", db_def),
                    ("with <T2,commit>, immediate", db2_imm), ("with <T2,commit>, deferred ", db2_def)):
        say(f"  {name:<28}{d['A']:>5} {d['B']:>5} {d['C']:>5} {d['D']:>5}")
    say("  => Without <T2, commit> T2 is rolled back (A back to 950, C back to 700); with it T2 is redone (A=900, C=600). T3 and T1 are identical in both runs.")

    say("\n### Task 12 - store the database values in MySQL and apply the recovered values\n")
    if a.no_mysql:
        say("  skipped (--no-mysql)")
    else:
        mysql_task(crash_imm, ops_imm, say)


if __name__ == "__main__":
    main()

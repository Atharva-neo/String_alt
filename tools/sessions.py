#!/usr/bin/env python3
"""
sessions.py - run and document multi-session MySQL demos (Experiments 4 and 5).

A demo is a list of steps executed strictly in order by real MySQL connections
(S1, S2, S3 ... are separate connections with autocommit OFF):

  ("task", "3", "Lost update")        heading in the transcript
  ("note", "text")                    explanatory line
  ("admin", "sql")                    setup / inspection on a separate autocommit connection (not printed as a session step)
  ("S1", "sql")                       run in session S1, print result or error
  ("S2", "sql", "async")              start in a background thread (the statement is expected to BLOCK on a lock)
  ("S2", "@join")                     wait for the pending statement of S2 and print its result / error
  ("sleep", 1.0)                      let the server settle
  ("kill", "S1")                      KILL the connection of S1 from the admin connection (simulates a crash)
  ("timeline",)                       print the schedule of all session steps since the last task heading

CLI of a demo script:  python run_demo.py            run + print transcript (used for 05_expected_output.md)
                        python run_demo.py --emit     also (re)write session1.sql, session2.sql, ... next to the script
Environment: MYSQL_HOST / MYSQL_PORT / MYSQL_USER / MYSQL_PWD (see .env.example), MYSQL_BIN for the mysql client.
"""
import os
import sys
import threading
import time
from pathlib import Path

import mysql.connector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_sql  # noqa: E402  (re-use the mysql CLI helper for loading the .sql files)

CFG = dict(host=os.environ.get("MYSQL_HOST", "127.0.0.1"), port=int(os.environ.get("MYSQL_PORT", "3306")),
           user=os.environ.get("MYSQL_USER", "root"), password=os.environ.get("MYSQL_PWD", ""))


def fmt_table(cols, rows):
    data = [[("NULL" if v is None else str(v)) for v in r] for r in rows]
    widths = [max([len(c)] + [len(r[i]) for r in data]) for i, c in enumerate(cols)]
    line = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    def row(vals, numeric=None):
        cells = []
        for i, v in enumerate(vals):
            cells.append(" " + (v.rjust(widths[i]) if numeric and numeric[i] else v.ljust(widths[i])) + " ")
        return "|" + "|".join(cells) + "|"
    numeric = [all(r[i].replace(".", "", 1).lstrip("-").isdigit() for r in data) and bool(data) for i in range(len(cols))]
    out = [line, row(cols), line] + [row(r, numeric) for r in data] + [line]
    return "\n".join(out) + f"\n{len(rows)} row{'s' if len(rows) != 1 else ''} in set"


def execute(conn, sql):
    """Run one statement; return printable result text (never raises for SQL errors)."""
    cur = conn.cursor()
    try:
        cur.execute(sql)
        parts = []
        if sql.lstrip().upper().startswith("CALL"):
            for rs in cur.stored_results():
                parts.append(fmt_table([d[0] for d in rs.description], rs.fetchall()))
        elif cur.description:
            parts.append(fmt_table([d[0] for d in cur.description], cur.fetchall()))
        if not parts:
            n = cur.rowcount
            parts.append("OK" if n in (-1, 0) and not sql.lstrip().upper().startswith(("UPDATE", "DELETE", "INSERT"))
                         else f"OK, {max(n, 0)} row{'s' if n != 1 else ''} affected")
        return "\n".join(parts)
    except mysql.connector.Error as e:
        return f"ERROR {e.errno} ({e.sqlstate}): {e.msg}"
    finally:
        try:
            cur.close()
        except Exception:
            pass


class Demo:
    def __init__(self, db, setup_files=()):
        self.db = db
        self.conns = {}
        self.pending = {}
        self.log = []                 # (step_no, session, sql) for timeline / emitted files
        self.n = 0
        self.task_start = 0
        self.admin = mysql.connector.connect(**CFG, database=None, autocommit=True)
        for f in setup_files:
            out = run_sql.run_mysql(Path(f).read_text(encoding="utf-8"), db=None if "schema" in Path(f).name else db)
            if "ERROR" in out:
                raise SystemExit("setup failed: " + out)
        self.admin.database = db

    # -- helpers ---------------------------------------------------------------
    def conn(self, name):
        if name not in self.conns:
            c = mysql.connector.connect(**CFG, database=self.db, autocommit=False)
            self.conns[name] = c
        return self.conns[name]

    def conn_id(self, name):
        cur = self.conn(name).cursor()
        cur.execute("SELECT CONNECTION_ID()")
        v = cur.fetchone()[0]
        cur.close()
        return v

    def p(self, text=""):
        print(text)

    # -- step dispatch --------------------------------------------------------
    def run(self, steps):
        for st in steps:
            kind = st[0]
            if kind == "task":
                if len(st) < 4:                       # a 4th element keeps the previous step list for ("timeline",)
                    self.task_start = len(self.log)
                self.p(f"\n### Task {st[1]} - {st[2]}\n")
            elif kind == "note":
                self.p(f"-- {st[1]}")
            elif kind == "admin":
                self.p(f"admin> {st[1]}")
                self.p(self.admin_exec(st[1]))
            elif kind == "quiet":                    # silent setup / reset on the admin connection
                self.admin_exec(st[1])
            elif kind == "sleep":
                time.sleep(st[1])
            elif kind == "kill":
                cid = self.conn_id(st[1])
                self.p(f"admin> KILL {cid};   -- connection {st[1]} is terminated without COMMIT (crash simulation)")
                self.p(self.admin_exec(f"KILL {cid}"))
                time.sleep(0.5)
                try:
                    self.conns.pop(st[1]).close()
                except Exception:
                    pass
            elif kind == "timeline":
                self.p(self.timeline())
            elif kind == "py":                       # ("py", callable) -> printed text (analysis done in Python)
                self.p(st[1]())
            else:
                self.session_step(st)
        for c in self.conns.values():
            try:
                c.close()
            except Exception:
                pass
        self.admin.close()

    def admin_exec(self, sql):
        a = mysql.connector.connect(**CFG, database=self.db, autocommit=True)
        try:
            return execute(a, sql)
        finally:
            a.close()

    def session_step(self, st):
        name, sql = st[0], st[1]
        if sql == "@join":
            th, box = self.pending.pop(name)
            th.join()
            self.p(f"{name}> (the blocked statement finishes)")
            self.p(box[0])
            return
        self.n += 1
        self.log.append((self.n, name, sql, len(st) > 2 and st[2] == "async"))
        if len(st) > 2 and st[2] == "async":
            box = [None]
            c = self.conn(name)
            th = threading.Thread(target=lambda: box.__setitem__(0, execute(c, sql)))
            th.start()
            self.pending[name] = (th, box)
            time.sleep(1.0)          # give the statement time to start waiting
            state = "STILL RUNNING - blocked, waiting for a lock" if th.is_alive() else "finished immediately"
            self.p(f"{name}> {sql}\n   [{state}]")
            return
        self.p(f"{name}> {sql}")
        self.p(execute(self.conn(name), sql))

    # -- documentation helpers -------------------------------------------------
    def timeline(self):
        rows = [r for r in self.log[self.task_start:]]
        names = sorted({r[1] for r in rows})
        out = ["| Step | " + " | ".join(names) + " |", "|---|" + "---|" * len(names)]
        for no, name, sql, _ in rows:
            out.append(f"| {no} | " + " | ".join((sql.replace("|", "\\|") if n == name else "") for n in names) + " |")
        return "\n".join(out)

    def emit(self, outdir, title):
        outdir = Path(outdir)
        names = sorted({r[1] for r in self.log})
        for i, name in enumerate(names, 1):
            lines = [f"-- {title}: script for session {name} (open a separate terminal: mysql -u root -p {self.db})",
                     f"-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.", ""]
            for no, who, sql, is_async in self.log:
                if who == name:
                    lines.append(f"-- step {no}" + ("  (this statement will BLOCK until the other session releases its lock)" if is_async else ""))
                    lines.append(sql.rstrip(";") + ";")
                else:
                    lines.append(f"-- step {no}: run in {who}")
            (outdir / f"session{i}.sql").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main_demo(script_file, db, setup_files, steps_factory, title):
    """Standard entry point used by every run_demo.py."""
    d = Demo(db, setup_files)
    d.run(steps_factory())
    if "--emit" in sys.argv:
        d.emit(Path(script_file).parent, title)
        print("\n(session scripts written)")

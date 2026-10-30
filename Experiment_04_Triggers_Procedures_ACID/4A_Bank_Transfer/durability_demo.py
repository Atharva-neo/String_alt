#!/usr/bin/env python3
"""
4A Task 11 - durability. Two phases separated by a server restart that YOU perform:

  python durability_demo.py prepare   # rebuilds bank_4a, commits one transfer, prints the balances
  (restart MySQL: Windows `net stop MySQL80 && net start MySQL80`, Linux `sudo systemctl restart mysql`;
   for a harsher test kill the server process instead of stopping it)
  python durability_demo.py check     # reconnects and shows that the committed transfer is still there
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import mysql.connector
from sessions import CFG, execute, run_sql

HERE = Path(__file__).parent


def show(c, sql):
    print(f"> {sql}\n{execute(c, sql)}")


if len(sys.argv) < 2 or sys.argv[1] not in ("prepare", "check"):
    raise SystemExit(__doc__)

if sys.argv[1] == "prepare":
    for f in ("01_schema.sql", "02_sample_data.sql"):
        run_sql.run_mysql((HERE / f).read_text(encoding="utf-8"), db=None if "schema" in f else "bank_4a")
    c = mysql.connector.connect(**CFG, database="bank_4a", autocommit=False)
    show(c, "SELECT * FROM Account")
    show(c, "START TRANSACTION")
    show(c, "UPDATE Account SET balance = balance - 2000 WHERE acc_no = 1002")
    show(c, "UPDATE Account SET balance = balance + 2000 WHERE acc_no = 1003")
    show(c, "COMMIT")                      # <- durability point: the redo log is flushed to disk here
    show(c, "SELECT * FROM Account")
    # a second, UNcommitted change that must NOT survive the crash
    show(c, "START TRANSACTION")
    show(c, "UPDATE Account SET balance = balance - 9999 WHERE acc_no = 1001")
    show(c, "SELECT * FROM Account WHERE acc_no = 1001")
    print("\n>>> Leave this window open, now RESTART / KILL the MySQL server (no COMMIT was issued for the last UPDATE).")
    sys.stdout.flush()
    if "--no-wait" not in sys.argv:
        input("Press Enter after the server was killed... ")
else:
    c = mysql.connector.connect(**CFG, database="bank_4a", autocommit=True)
    print("-- after the restart --")
    show(c, "SELECT * FROM Account")

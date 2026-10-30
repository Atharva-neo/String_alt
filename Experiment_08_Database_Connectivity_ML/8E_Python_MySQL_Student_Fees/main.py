#!/usr/bin/env python3
"""8E - Python-MySQL connectivity (student fees): parameterised CRUD, executemany, stored procedure, transactions, pandas, error handling.

  python main.py [--roll 102 --amount 10000 --delete-roll 105]      (roll/amount: Task 7; delete-roll: Task 8)
Without the options the values are typed on the keyboard (Enter = default).
Connection settings: MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PWD (environment, see .env.example). Nothing is hard-coded.
"""
import argparse
import sys
from pathlib import Path

import mysql.connector
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))
from dbconn import heading, mysql_config

ap = argparse.ArgumentParser()
ap.add_argument("--roll", type=int)
ap.add_argument("--amount", type=float)
ap.add_argument("--delete-roll", type=int)
args = ap.parse_args()


def ask(label, given, default, cast):
    if given is not None:
        return given
    try:
        return cast(input(f"{label} [{default}]: ").strip() or default)
    except EOFError:
        print(f"({label}: no keyboard input, using {default})")
        return cast(default)


heading(1, "Connect with host, user, password and print the server version")
conn = mysql.connector.connect(**mysql_config())
print("connected to MySQL server version:", conn.server_info)
cur = conn.cursor()

heading(2, "Create database collegeDB and table student_fee")
cur.execute("DROP DATABASE IF EXISTS collegeDB")
cur.execute("CREATE DATABASE collegeDB")
conn.database = "collegeDB"
cur.execute("""CREATE TABLE student_fee (
    roll_no   INT           NOT NULL PRIMARY KEY,
    name      VARCHAR(50)   NOT NULL,
    dept      VARCHAR(10),
    fee_total DECIMAL(10,2) NOT NULL,
    fee_paid  DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_paid_le_total CHECK (fee_paid <= fee_total)
) ENGINE=InnoDB""")
print("table student_fee created")

heading(3, "Insert one row with a parameterised query (%s placeholders) and commit")
cur.execute("INSERT INTO student_fee (roll_no, name, dept, fee_total, fee_paid) VALUES (%s, %s, %s, %s, %s)", (101, "Aditya Pawar", "AIML", 85000, 85000))
conn.commit()
print("rows inserted:", cur.rowcount)

heading(4, "Insert the remaining rows with executemany")
rest = [(102, "Neha Gaikwad", "AIML", 85000, 40000), (103, "Omkar Salunkhe", "CSE", 90000, 90000),
        (104, "Priya Mane", "CSE", 90000, 30000), (105, "Sagar Jadhav", "ENTC", 80000, 0)]
cur.executemany("INSERT INTO student_fee (roll_no, name, dept, fee_total, fee_paid) VALUES (%s, %s, %s, %s, %s)", rest)
conn.commit()
print("rows inserted:", cur.rowcount)


def show_table(rows, header):
    widths = [max(len(str(x)) for x in col) for col in zip(header, *rows)]
    line = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    print(line); print("| " + " | ".join(str(h).ljust(w) for h, w in zip(header, widths)) + " |"); print(line)
    for r in rows:
        print("| " + " | ".join(str(v).rjust(w) if isinstance(v, (int, float)) or hasattr(v, "quantize") else str(v).ljust(w) for v, w in zip(r, widths)) + " |")
    print(line)


heading(5, "fetchall() and print as a formatted table")
cur.execute("SELECT roll_no, name, dept, fee_total, fee_paid FROM student_fee ORDER BY roll_no")
show_table(cur.fetchall(), [d[0] for d in cur.description])

heading(6, "Students with pending fee (fee_paid < fee_total) and the pending amount")
cur.execute("SELECT roll_no, name, fee_total - fee_paid AS pending FROM student_fee WHERE fee_paid < fee_total ORDER BY roll_no")
show_table(cur.fetchall(), ["roll_no", "name", "pending"])

heading(7, "Read a roll number and an amount, update fee_paid with a parameterised query")
roll = ask("roll number", args.roll, 102, int)
amount = ask("amount", args.amount, 10000, float)
cur.execute("UPDATE student_fee SET fee_paid = fee_paid + %s WHERE roll_no = %s", (amount, roll))
conn.commit()
print(f"rows updated: {cur.rowcount}")
cur.execute("SELECT roll_no, fee_total, fee_paid FROM student_fee WHERE roll_no = %s", (roll,))
print(cur.fetchone())
print("""Why not string formatting?  sql = f"UPDATE ... WHERE roll_no = {roll}"  lets the user type  102 OR 1=1  (or  1; DROP TABLE student_fee)
and the text becomes part of the SQL statement => SQL injection. With %s placeholders the driver sends the value as DATA, never as SQL.""")
try:
    cur.execute("UPDATE student_fee SET fee_paid = fee_paid + %s WHERE roll_no = %s", (10**7, roll))
except mysql.connector.Error as e:
    print(f"negative test (paying more than the total) -> errno {e.errno}: {e.msg}")
    conn.rollback()

heading(8, "Delete a student by roll number and print cursor.rowcount")
droll = ask("roll number to delete", args.delete_roll, 105, int)
cur.execute("DELETE FROM student_fee WHERE roll_no = %s", (droll,))
conn.commit()
print("cursor.rowcount =", cur.rowcount)

heading(9, "Create stored procedure pay_fee(IN r INT, IN amt DECIMAL) and call it with callproc")
cur.execute("DROP PROCEDURE IF EXISTS pay_fee")
cur.execute("""CREATE PROCEDURE pay_fee(IN r INT, IN amt DECIMAL(10,2))
BEGIN
    UPDATE student_fee SET fee_paid = LEAST(fee_total, fee_paid + amt) WHERE roll_no = r;
    SELECT roll_no, name, fee_total, fee_paid, fee_total - fee_paid AS pending FROM student_fee WHERE roll_no = r;
END""")
cur.callproc("pay_fee", (104, 5000))
for rs in cur.stored_results():
    show_table(rs.fetchall(), [d[0] for d in rs.description])
conn.commit()

heading(10, "Two updates as one transaction (autocommit off); the second fails -> rollback()")
conn.autocommit = False
cur.execute("SELECT roll_no, fee_paid FROM student_fee ORDER BY roll_no")
before = cur.fetchall()
try:
    cur.execute("UPDATE student_fee SET fee_paid = fee_paid + 1000 WHERE roll_no = %s", (104,))               # succeeds
    cur.execute("UPDATE student_fee SET fee_paid = fee_total + 1 WHERE roll_no = %s", (103,))                 # violates CHECK -> error
    conn.commit()
except mysql.connector.Error as e:
    print(f"error in the second update: errno {e.errno}: {e.msg}")
    conn.rollback()
    print("rollback() done")
cur.execute("SELECT roll_no, fee_paid FROM student_fee ORDER BY roll_no")
after = cur.fetchall()
print("table unchanged:", before == after)
conn.autocommit = True

heading(11, "Load the table into a pandas DataFrame: department-wise total pending fee")
cur.execute("SELECT roll_no, name, dept, fee_total, fee_paid FROM student_fee")
df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description]).astype({"fee_total": float, "fee_paid": float})
df["pending"] = df["fee_total"] - df["fee_paid"]
print(df.groupby("dept")["pending"].sum().to_string())

heading(12, "Handle mysql.connector.Error: wrong password and missing table; close in finally")
for label, action in (("wrong password", lambda: mysql.connector.connect(**mysql_config(password="definitely-wrong-password"))),
                      ("missing table", lambda: conn.cursor().execute("SELECT * FROM no_such_table"))):
    c2 = None
    try:
        c2 = action()
    except mysql.connector.Error as e:
        print(f"{label}: errno {e.errno}, sqlstate {e.sqlstate}: {e.msg}")
    finally:
        if c2 is not None and hasattr(c2, "close"):
            c2.close()
cur.close()
conn.close()
print("cursor and connection closed")

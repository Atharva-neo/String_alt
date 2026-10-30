#!/usr/bin/env python3
"""5B - Isolation levels on seat booking. Replays Tasks 1-12 with real connections and MEASURES the anomaly table."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import mysql.connector
from sessions import main_demo, CFG

HERE = Path(__file__).parent
LEVELS = ["READ UNCOMMITTED", "READ COMMITTED", "REPEATABLE READ", "SERIALIZABLE"]
RESET = [("quiet", "DELETE FROM Seats WHERE seat_no NOT IN ('A1','A2','A3')"),
         ("quiet", "UPDATE Seats SET status = 'Free' WHERE seat_no IN ('A1','A2')"),
         ("quiet", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A3'")]


def _c():
    c = mysql.connector.connect(**CFG, database="seats_5b", autocommit=False)
    cur = c.cursor(); cur.execute("SET SESSION innodb_lock_wait_timeout = 1"); cur.close()
    return c


def _q(c, sql):
    cur = c.cursor(); cur.execute(sql)
    r = cur.fetchall() if cur.description else None
    cur.close()
    return r


def _reset():
    a = mysql.connector.connect(**CFG, database="seats_5b", autocommit=True)
    cur = a.cursor()
    for _, s in RESET:
        cur.execute(s)
    cur.close(); a.close()


def measure():
    """Run the three anomaly experiments at every isolation level and return a markdown table."""
    out = ["| Isolation level | Dirty read | Non-repeatable read | Phantom read |", "|---|---|---|---|"]
    for lvl in LEVELS:
        cells = []
        # --- dirty read: S1 changes A1 without commit, S2 reads A1
        _reset(); s1, s2 = _c(), _c()
        _q(s2, f"SET SESSION TRANSACTION ISOLATION LEVEL {lvl}")
        _q(s1, "START TRANSACTION"); _q(s1, "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1'")
        _q(s2, "START TRANSACTION")
        try:
            cells.append("**occurred**" if _q(s2, "SELECT status FROM Seats WHERE seat_no = 'A1'")[0][0] == "Booked" else "prevented")
        except mysql.connector.Error:
            cells.append("prevented (reader blocked)")
        s1.rollback(); s2.rollback(); s1.close(); s2.close()
        # --- non-repeatable read: S2 reads A2 twice, S1 commits an UPDATE in between
        _reset(); s1, s2 = _c(), _c()
        _q(s2, f"SET SESSION TRANSACTION ISOLATION LEVEL {lvl}")
        _q(s2, "START TRANSACTION"); first = _q(s2, "SELECT status FROM Seats WHERE seat_no = 'A2'")[0][0]
        _q(s1, "START TRANSACTION")
        try:
            _q(s1, "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'"); s1.commit()
            second = _q(s2, "SELECT status FROM Seats WHERE seat_no = 'A2'")[0][0]
            cells.append("**occurred**" if first != second else "prevented")
        except mysql.connector.Error:
            cells.append("prevented (writer blocked)")
        s1.rollback(); s2.rollback(); s1.close(); s2.close()
        # --- phantom: S2 counts free seats twice, S1 commits INSERT A4 in between
        _reset(); s1, s2 = _c(), _c()
        _q(s2, f"SET SESSION TRANSACTION ISOLATION LEVEL {lvl}")
        _q(s2, "START TRANSACTION"); c1 = _q(s2, "SELECT COUNT(*) FROM Seats WHERE status = 'Free'")[0][0]
        _q(s1, "START TRANSACTION")
        try:
            _q(s1, "INSERT INTO Seats VALUES ('A4', 'Free')"); s1.commit()
            c2 = _q(s2, "SELECT COUNT(*) FROM Seats WHERE status = 'Free'")[0][0]
            if c1 != c2:
                cells.append("**occurred**")
            else:
                c3 = _q(s2, "SELECT COUNT(*) FROM Seats WHERE status = 'Free' FOR UPDATE")[0][0]
                cells.append("prevented for plain reads; **visible with FOR UPDATE**" if c3 != c1 else "prevented")
        except mysql.connector.Error:
            cells.append("prevented (insert blocked)")
        s1.rollback(); s2.rollback(); s1.close(); s2.close()
        out.append(f"| {lvl} | " + " | ".join(cells) + " |")
    _reset()
    return "\n".join(out)


RECOMMENDATION = """Recommendation for a seat-booking system: keep InnoDB's default REPEATABLE READ (or READ COMMITTED) and protect the booking step itself with a row lock:
  START TRANSACTION; SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE; -- refuse if not 'Free'; UPDATE ...; COMMIT;
Why: (1) READ UNCOMMITTED is never acceptable - users would be shown seats that are never really booked (dirty read).
(2) The dangerous anomaly in booking is the check-then-act race (two users see 'Free' and both book); isolation levels below SERIALIZABLE do not stop it,
    but FOR UPDATE (or the conditional UPDATE ... WHERE status='Free' + ROW_COUNT()) does, with row-level locking only on the seat being bought.
(3) SERIALIZABLE would also work but turns every read into a locking read, gap locks block unrelated inserts and deadlocks become frequent => poor throughput.
(4) REPEATABLE READ gives a stable view while one customer looks at the seat map; READ COMMITTED gives a fresher view and fewer gap locks - both are fine with FOR UPDATE."""


def steps():
    return [
        ("task", "1", "Seats table and two sessions"),
        ("admin", "SELECT * FROM Seats"),
        ("task", "2", "Isolation level of the session"),
        ("S1", "SELECT @@transaction_isolation AS isolation"),

        ("task", "3", "Dirty read: S2 under READ UNCOMMITTED reads S1's uncommitted booking of A1"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED"),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1'"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'"),
        ("note", "S2 sees 'Booked' - data S1 has NOT committed (dirty read). Now S1 rolls back:"),
        ("S1", "ROLLBACK"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'"),
        ("note", "The 'Booked' S2 saw never existed."),
        ("S2", "COMMIT"),

        ("task", "4", "Same experiment under READ COMMITTED: no dirty read"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A1'"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A1'"),
        ("note", "S2 still sees 'Free' - only committed data is visible."),
        ("S1", "ROLLBACK"),
        ("S2", "COMMIT"),

        ("task", "5", "Non-repeatable read under READ COMMITTED"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'"),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'"),
        ("S1", "COMMIT"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'"),
        ("note", "Same query, same transaction, different answer: NON-REPEATABLE READ."),
        ("S2", "COMMIT"),
    ] + RESET + [

        ("task", "6", "Non-repeatable read under REPEATABLE READ: prevented"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'"),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'"),
        ("S1", "COMMIT"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'"),
        ("note", "S2 keeps seeing its snapshot ('Free'). After S2 ends its transaction it sees the new value:"),
        ("S2", "COMMIT"),
        ("S2", "SELECT seat_no, status FROM Seats WHERE seat_no = 'A2'"),
        ("S2", "COMMIT"),
    ] + RESET + [

        ("task", "7", "Phantom: S2 counts free seats twice while S1 inserts A4 - REPEATABLE READ"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("S1", "START TRANSACTION"),
        ("S1", "INSERT INTO Seats VALUES ('A4', 'Free')"),
        ("S1", "COMMIT"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("note", "A plain SELECT still shows 2: InnoDB's REPEATABLE READ snapshot hides the phantom. A LOCKING read reads the latest committed data and exposes it:"),
        ("S2", "SELECT COUNT(*) AS free_seats_locking_read FROM Seats WHERE status = 'Free' FOR UPDATE"),
        ("S2", "COMMIT"),
        ("note", "For comparison under READ COMMITTED even the plain count shows the phantom:"),
    ] + RESET + [
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("S1", "START TRANSACTION"),
        ("S1", "INSERT INTO Seats VALUES ('A4', 'Free')"),
        ("S1", "COMMIT"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("S2", "COMMIT"),
    ] + RESET + [

        ("task", "8", "Phantom attempt under SERIALIZABLE: S1's INSERT is blocked"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("S1", "START TRANSACTION"),
        ("S1", "INSERT INTO Seats VALUES ('A4', 'Free')", "async"),
        ("S2", "SELECT COUNT(*) AS free_seats FROM Seats WHERE status = 'Free'"),
        ("note", "S2 still sees 2 and S1 is still waiting. Once S2 commits, S1's insert goes through:"),
        ("S2", "COMMIT"),
        ("S1", "@join"),
        ("S1", "COMMIT"),
    ] + RESET + [

        ("task", "9", "Two users book A2 at once - SELECT ... FOR UPDATE prevents double booking"),
        ("S1", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S1", "START TRANSACTION"),
        ("S1", "SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT status FROM Seats WHERE seat_no = 'A2' FOR UPDATE", "async"),
        ("S1", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2'"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("note", "S2 now sees 'Booked': the application tells user 2 that the seat is taken. Nothing is double booked."),
        ("S2", "ROLLBACK"),
        ("note", "Alternative without a separate SELECT: a conditional UPDATE and a check of the affected rows:"),
        ("S2", "UPDATE Seats SET status = 'Booked' WHERE seat_no = 'A2' AND status = 'Free'"),
        ("S2", "ROLLBACK"),
    ] + RESET + [

        ("task", "10", "SET SESSION versus SET GLOBAL"),
        ("S1", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"),
        ("S2", "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ"),
        ("S1", "SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level"),
        ("note", "SET GLOBAL (the demo restores it at the end):"),
        ("admin", "SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED"),
        ("S2", "SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level"),
        ("S3", "SELECT @@session.transaction_isolation AS session_level, @@global.transaction_isolation AS global_level"),
        ("note", "S2 (opened before) keeps its own level; the NEW session S3 inherited the new global level."),
        ("admin", "SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ"),

        ("task", "11", "Isolation level x anomaly - measured with real sessions"),
        ("py", measure),
        ("task", "12", "Recommendation for a seat-booking system"),
        ("py", lambda: RECOMMENDATION),
    ]


main_demo(__file__, "seats_5b", [HERE / "01_schema.sql", HERE / "02_sample_data.sql"], steps, "5B Isolation levels")

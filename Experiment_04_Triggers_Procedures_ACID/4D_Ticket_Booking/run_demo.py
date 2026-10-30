#!/usr/bin/env python3
"""4D Task 11 - start a transaction with two bookings, kill the session before COMMIT, reconnect and show nothing was saved."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from sessions import main_demo

HERE = Path(__file__).parent

TRIGGERS = [
    """CREATE TRIGGER trg_booking_reserve AFTER INSERT ON Booking FOR EACH ROW
BEGIN UPDATE Show_Seats SET available = available - NEW.seats WHERE show_id = NEW.show_id; END""",
    """CREATE TRIGGER trg_booking_guard BEFORE INSERT ON Booking FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Show_Seats WHERE show_id = NEW.show_id;
    IF NEW.seats > v_avail THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available'; END IF;
END""",
]


def steps():
    return [("admin", t) for t in TRIGGERS] + [
        ("task", "11", "Kill the session before COMMIT (atomicity)"),
        ("S2", "SELECT * FROM Show_Seats"),
        ("S1", "START TRANSACTION"),
        ("S1", "INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 3)"),
        ("S1", "INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 2)"),
        ("S1", "SELECT customer, seats FROM Booking"),
        ("S1", "SELECT show_id, available FROM Show_Seats WHERE show_id = 2"),
        ("note", "S2 (another connection) cannot see the uncommitted rows (isolation):"),
        ("S2", "SELECT COUNT(*) AS visible_bookings FROM Booking"),
        ("S2", "SELECT show_id, available FROM Show_Seats WHERE show_id = 2"),
        ("kill", "S1"),
        ("note", "Reconnect as a brand new session S3 and look at the data: the server rolled the dead transaction back."),
        ("S3", "SELECT COUNT(*) AS bookings FROM Booking"),
        ("S3", "SELECT show_id, available FROM Show_Seats WHERE show_id = 2"),
        ("note", "Seats are untouched: 50 available - the transaction was atomic (all or nothing)."),
    ]


main_demo(__file__, "ticket_4d", [HERE / "01_schema.sql", HERE / "02_sample_data.sql"], steps, "4D Ticket booking - Task 11")

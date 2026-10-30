#!/usr/bin/env python3
"""4A Task 10 - isolation demo with two real sessions (and the atomicity side of the transfer)."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from sessions import main_demo

HERE = Path(__file__).parent


def steps():
    # Re-create the objects needed by the demo (tables + data + procedure) so the script is self-contained.
    proc = """CREATE PROCEDURE transfer_funds(IN from_acc INT, IN to_acc INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE v_bal DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT balance INTO v_bal FROM Account WHERE acc_no = from_acc FOR UPDATE;
    IF v_bal - amt < 1000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance'; END IF;
    UPDATE Account SET balance = balance - amt WHERE acc_no = from_acc;
    UPDATE Account SET balance = balance + amt WHERE acc_no = to_acc;
    COMMIT;
END"""
    return [
        ("admin", proc),
        ("task", "10", "Isolation: S1 changes balances but has not committed; S2 reads / writes"),
        ("note", "Plain statements instead of CALL transfer_funds are used so that S1 can stay inside an open transaction."),
        ("S1", "START TRANSACTION"),
        ("S1", "UPDATE Account SET balance = balance - 10000 WHERE acc_no = 1001"),
        ("S1", "UPDATE Account SET balance = balance + 10000 WHERE acc_no = 1002"),
        ("S1", "SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)"),
        ("note", "S1 sees its own uncommitted changes. S2 (default REPEATABLE READ) still sees the OLD, committed balances:"),
        ("S2", "START TRANSACTION"),
        ("S2", "SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)"),
        ("note", "S2 tries to modify the row S1 has locked: it has to wait."),
        ("S2", "UPDATE Account SET balance = balance + 1 WHERE acc_no = 1001", "async"),
        ("S1", "COMMIT"),
        ("S2", "@join"),
        ("S2", "COMMIT"),
        ("S2", "SELECT acc_no, balance FROM Account WHERE acc_no IN (1001, 1002)"),
        ("note", "After S1's COMMIT the new balances are visible (and S2's waiting UPDATE added 1 to account 1001)."),
        ("timeline",),
        ("task", "10b", "Atomicity: a failed transfer leaves nothing behind (also seen from a second session)"),
        ("S1", "CALL transfer_funds(1003, 1001, 8000)"),
        ("S2", "SELECT acc_no, balance FROM Account"),
        ("S2", "SELECT COUNT(*) AS log_rows FROM Txn_Log"),
    ]


main_demo(__file__, "bank_4a", [HERE / "01_schema.sql", HERE / "02_sample_data.sql"], steps, "4A Bank transfer - Task 10")

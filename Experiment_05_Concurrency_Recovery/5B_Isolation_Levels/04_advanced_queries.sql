-- Experiment 5B - examiner follow-ups (two-terminal scripts; "-- S1>" terminal 1, "-- S2>" terminal 2). Not executed by tools/run_sql.py.

-- ### ADV 1: Set the level for one transaction only
-- S1> SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;   START TRANSACTION; ...; COMMIT;      -- applies to the NEXT transaction only, then the session level returns

-- ### ADV 2: Phantom caused by the transaction's own write (REPEATABLE READ)
-- S2> START TRANSACTION; SELECT COUNT(*) FROM Seats WHERE status='Free';          -- 2
-- S1> INSERT INTO Seats VALUES ('A5','Free'); COMMIT;
-- S2> UPDATE Seats SET status='Free' WHERE seat_no='A5';                           -- 1 row affected: S2 can modify a row it could not see
-- S2> SELECT COUNT(*) FROM Seats WHERE status='Free';                              -- 3: the row is now part of S2's view (phantom)

-- ### ADV 3: Optimistic booking without a lock
-- S1> UPDATE Seats SET status='Booked' WHERE seat_no='A2' AND status='Free';       -- ROW_COUNT() = 1 : success
-- S2> UPDATE Seats SET status='Booked' WHERE seat_no='A2' AND status='Free';       -- ROW_COUNT() = 0 : somebody was faster, tell the user

-- ### ADV 4: Which level does a mysqldump --single-transaction use?
-- REPEATABLE READ with START TRANSACTION WITH CONSISTENT SNAPSHOT: a consistent backup while the application keeps writing.

-- ### ADV 5: Statement that shows current locks
-- SELECT engine_transaction_id, object_name, lock_type, lock_mode, lock_data FROM performance_schema.data_locks;
